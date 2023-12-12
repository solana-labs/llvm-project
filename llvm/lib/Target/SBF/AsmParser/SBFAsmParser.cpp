//===-- SBFAsmParser.cpp - Parse SBF assembly to MCInst instructions --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/SBFMCTargetDesc.h"
#include "MCTargetDesc/SBFInstPrinter.h"
#include "TargetInfo/SBFTargetInfo.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCParser/MCAsmLexer.h"
#include "llvm/MC/MCParser/MCParsedAsmOperand.h"
#include "llvm/MC/MCParser/MCTargetAsmParser.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Casting.h"

using namespace llvm;

namespace {
struct SBFOperand;

class SBFAsmParser : public MCTargetAsmParser {

  SMLoc getLoc() const { return getParser().getTok().getLoc(); }

  bool MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                               OperandVector &Operands, MCStreamer &Out,
                               uint64_t &ErrorInfo,
                               bool MatchingInlineAsm) override;

  bool parseRegister(MCRegister &Reg, SMLoc &StartLoc,
                     SMLoc &EndLoc) override;
  OperandMatchResultTy tryParseRegister(MCRegister &Reg, SMLoc &StartLoc,
                                        SMLoc &EndLoc) override;

  bool ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                        SMLoc NameLoc, OperandVector &Operands) override;

  bool ParseDirective(AsmToken DirectiveID) override;

#define GET_ASSEMBLER_HEADER
#include "SBFGenAsmMatcher.inc"

  bool parseOperand(OperandVector &Operands, StringRef Mnemonic);
  OperandMatchResultTy parseImmediate(OperandVector &Operands);
  OperandMatchResultTy parseRegister(OperandVector &Operands);
  OperandMatchResultTy parseMemOperand(OperandVector &Operands);

public:
  enum SBFMatchResultTy {
    Match_Dummy = FIRST_TARGET_MATCH_RESULT_TY,
#define GET_OPERAND_DIAGNOSTIC_TYPES
#include "SBFGenAsmMatcher.inc"
#undef GET_OPERAND_DIAGNOSTIC_TYPES
  };

  SBFAsmParser(const MCSubtargetInfo &STI, MCAsmParser &Parser,
               const MCInstrInfo &MII, const MCTargetOptions &Options)
      : MCTargetAsmParser(Options, STI, MII) {
    setAvailableFeatures(ComputeAvailableFeatures(STI.getFeatureBits()));
  }
};

/// SBFOperand - Instances of this class represent a parsed machine
/// instruction
struct SBFOperand : public MCParsedAsmOperand {

  enum KindTy {
    Token,
    Register,
    Immediate,
  } Kind;

  struct RegOp {
    unsigned RegNum;
  };

  struct ImmOp {
    const MCExpr *Val;
  };

  SMLoc StartLoc, EndLoc;
  union {
    StringRef Tok;
    RegOp Reg;
    ImmOp Imm;
  };

  SBFOperand(KindTy K) : Kind(K) {}

public:
  SBFOperand(const SBFOperand &o) : MCParsedAsmOperand() {
    Kind = o.Kind;
    StartLoc = o.StartLoc;
    EndLoc = o.EndLoc;

    switch (Kind) {
    case Register:
      Reg = o.Reg;
      break;
    case Immediate:
      Imm = o.Imm;
      break;
    case Token:
      Tok = o.Tok;
      break;
    }
  }

  bool isToken() const override { return Kind == Token; }
  bool isReg() const override { return Kind == Register; }
  bool isImm() const override { return Kind == Immediate; }
  bool isMem() const override { return false; }

  bool isConstantImm() const {
    return isImm() && isa<MCConstantExpr>(getImm());
  }

  int64_t getConstantImm() const {
    const MCExpr *Val = getImm();
    return static_cast<const MCConstantExpr *>(Val)->getValue();
  }

  bool isSImm12() const {
    return (isConstantImm() && isInt<12>(getConstantImm()));
  }

  /// getStartLoc - Gets location of the first token of this operand
  SMLoc getStartLoc() const override { return StartLoc; }
  /// getEndLoc - Gets location of the last token of this operand
  SMLoc getEndLoc() const override { return EndLoc; }

  unsigned getReg() const override {
    assert(Kind == Register && "Invalid type access!");
    return Reg.RegNum;
  }

  const MCExpr *getImm() const {
    assert(Kind == Immediate && "Invalid type access!");
    return Imm.Val;
  }

  StringRef getToken() const {
    assert(Kind == Token && "Invalid type access!");
    return Tok;
  }

  void print(raw_ostream &OS) const override {
    auto RegName = [](unsigned Reg) {
      if (Reg)
        return SBFInstPrinter::getRegisterName(Reg);
      else
        return "noreg";
    };

    switch (Kind) {
    case Immediate:
      OS << *getImm();
      break;
    case Register:
      OS << "<register ";
      OS << RegName(getReg()) << ">";
      break;
    case Token:
      OS << "'" << getToken() << "'";
      break;
    }
  }

  void addExpr(MCInst &Inst, const MCExpr *Expr) const {
    assert(Expr && "Expr shouldn't be null!");

    if (auto *CE = dyn_cast<MCConstantExpr>(Expr))
      Inst.addOperand(MCOperand::createImm(CE->getValue()));
    else
      Inst.addOperand(MCOperand::createExpr(Expr));
  }

  // Used by the TableGen Code
  void addRegOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    Inst.addOperand(MCOperand::createReg(getReg()));
  }

  void addImmOperands(MCInst &Inst, unsigned N) const {
    assert(N == 1 && "Invalid number of operands!");
    addExpr(Inst, getImm());
  }

  static std::unique_ptr<SBFOperand> createToken(StringRef Str, SMLoc S) {
    auto Op = std::make_unique<SBFOperand>(Token);
    Op->Tok = Str;
    Op->StartLoc = S;
    Op->EndLoc = S;
    return Op;
  }

  static std::unique_ptr<SBFOperand> createReg(unsigned RegNo, SMLoc S,
                                               SMLoc E) {
    auto Op = std::make_unique<SBFOperand>(Register);
    Op->Reg.RegNum = RegNo;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  static std::unique_ptr<SBFOperand> createImm(const MCExpr *Val, SMLoc S,
                                               SMLoc E) {
    auto Op = std::make_unique<SBFOperand>(Immediate);
    Op->Imm.Val = Val;
    Op->StartLoc = S;
    Op->EndLoc = E;
    return Op;
  }

  // Identifiers that can be used at the start of a statment.
  static bool isValidIdAtStart(StringRef Name) {
    return StringSwitch<bool>(Name.lower())
        .Case("if", true)
        .Case("call", true)
        .Case("callx", true)
        .Case("goto", true)
        .Case("*", true)
        .Case("exit", true)
        .Case("lock", true)
        .Case("ld_pseudo", true)
        .Default(false);
  }

  // Identifiers that can be used in the middle of a statment.
  static bool isValidIdInMiddle(StringRef Name) {
    return StringSwitch<bool>(Name.lower())
        .Case("u64", true)
        .Case("u32", true)
        .Case("u16", true)
        .Case("u8", true)
        .Case("be64", true)
        .Case("be32", true)
        .Case("be16", true)
        .Case("le64", true)
        .Case("le32", true)
        .Case("le16", true)
        .Case("goto", true)
        .Case("ll", true)
        .Case("skb", true)
        .Case("s", true)
        .Default(false);
  }
};
} // end anonymous namespace.

#define GET_REGISTER_MATCHER
#define GET_MATCHER_IMPLEMENTATION
#include "SBFGenAsmMatcher.inc"

bool SBFAsmParser::MatchAndEmitInstruction(SMLoc IDLoc, unsigned &Opcode,
                                           OperandVector &Operands,
                                           MCStreamer &Out, uint64_t &ErrorInfo,
                                           bool MatchingInlineAsm) {
  MCInst Inst;
  SMLoc ErrorLoc;

  switch (MatchInstructionImpl(Operands, Inst, ErrorInfo, MatchingInlineAsm)) {
  default:
    break;
  case Match_Success:
    Inst.setLoc(IDLoc);
    Out.emitInstruction(Inst, getSTI());
    return false;
  case Match_MissingFeature:
    return Error(IDLoc, "instruction use requires an option to be enabled");
  case Match_MnemonicFail:
    return Error(IDLoc, "unrecognized instruction mnemonic");
  case Match_InvalidOperand:
    ErrorLoc = IDLoc;

    if (ErrorInfo != ~0U) {
      if (ErrorInfo >= Operands.size())
        return Error(ErrorLoc, "too few operands for instruction");

      ErrorLoc = ((SBFOperand &)*Operands[ErrorInfo]).getStartLoc();

      if (ErrorLoc == SMLoc())
        ErrorLoc = IDLoc;
    }

    return Error(ErrorLoc, "invalid operand for instruction");
  }

  llvm_unreachable("Unknown match type detected!");
}

bool SBFAsmParser::parseRegister(MCRegister &Reg, SMLoc &StartLoc,
                                 SMLoc &EndLoc) {
  if (tryParseRegister(Reg, StartLoc, EndLoc) != MatchOperand_Success)
    return Error(StartLoc, "invalid register name");
  return false;
}

OperandMatchResultTy SBFAsmParser::tryParseRegister(MCRegister &Reg,
                                                    SMLoc &StartLoc,
                                                    SMLoc &EndLoc) {
  const AsmToken &Tok = getParser().getTok();
  StartLoc = Tok.getLoc();
  EndLoc = Tok.getEndLoc();
  Reg = 0;
  StringRef Name = getLexer().getTok().getIdentifier();

  if (!MatchRegisterName(Name)) {
    getParser().Lex(); // Eat identifier token.
    return MatchOperand_Success;
  }

  return MatchOperand_NoMatch;
}

OperandMatchResultTy SBFAsmParser::parseRegister(OperandVector &Operands) {
  SMLoc S = getLoc();
  SMLoc E = SMLoc::getFromPointer(S.getPointer() - 1);

  switch (getLexer().getKind()) {
  default:
    return MatchOperand_NoMatch;
  case AsmToken::Identifier:
    StringRef Name = getLexer().getTok().getIdentifier();
    unsigned RegNo = MatchRegisterName(Name);

    if (RegNo == 0)
      return MatchOperand_NoMatch;

    getLexer().Lex();
    Operands.push_back(SBFOperand::createReg(RegNo, S, E));
  }
  return MatchOperand_Success;
}

OperandMatchResultTy SBFAsmParser::parseImmediate(OperandVector &Operands) {
  switch (getLexer().getKind()) {
  default:
    return MatchOperand_NoMatch;
  case AsmToken::LParen:
  case AsmToken::Minus:
  case AsmToken::Plus:
  case AsmToken::Integer:
  case AsmToken::String:
  case AsmToken::Identifier:
    break;
  }

  const MCExpr *IdVal;
  SMLoc S = getLoc();

  if (getParser().parseExpression(IdVal))
    return MatchOperand_ParseFail;

  SMLoc E = SMLoc::getFromPointer(S.getPointer() - 1);
  Operands.push_back(SBFOperand::createImm(IdVal, S, E));

  return MatchOperand_Success;
}

OperandMatchResultTy SBFAsmParser::parseMemOperand(OperandVector &Operands) {
  if (getLexer().isNot(AsmToken::LBrac)) {
    return MatchOperand_ParseFail;
  }

  getParser().Lex(); // Eat '['.
  Operands.push_back(SBFOperand::createToken("[", getLoc()));

  if (parseRegister(Operands) != MatchOperand_Success) {
    Error(getLoc(), "expected register");
    return MatchOperand_ParseFail;
  }

  if (parseImmediate(Operands) != MatchOperand_Success) {
    Error(getLoc(), "expected immediate offset");
    return MatchOperand_ParseFail;
  }

  if (getLexer().isNot(AsmToken::RBrac)) {
    Error(getLoc(), "expected ']'");
    return MatchOperand_ParseFail;
  }

  getParser().Lex(); // Eat ']'.
  Operands.push_back(SBFOperand::createToken("]", getLoc()));

  return MatchOperand_Success;
}

/// Looks at a token type and creates the relevant operand from this
/// information, adding to Operands. If operand was parsed, returns false, else
/// true.
bool SBFAsmParser::parseOperand(OperandVector &Operands, StringRef Mnemonic) {
  // Attempt to parse token as a register.
  if (parseRegister(Operands) == MatchOperand_Success)
    return false;

  // Attempt to parse token as an immediate.
  if (parseImmediate(Operands) == MatchOperand_Success) {
    return false;
  }

  // Attempt to parse token sequence as a memory operand ("[reg+/-offset]").
  if (parseMemOperand(Operands) == MatchOperand_Success) {
    return false;
  }

  // Finally we have exhausted all options and must declare defeat.
  Error(getLoc(), "unknown operand");
  return true;
}

/// Parse an SBF instruction.
bool SBFAsmParser::ParseInstruction(ParseInstructionInfo &Info, StringRef Name,
                                    SMLoc NameLoc, OperandVector &Operands) {
  // First operand is token for instruction mnemonic.
  Operands.push_back(SBFOperand::createToken(Name, NameLoc));

  // If there are no more operands, then finish.
  if (getLexer().is(AsmToken::EndOfStatement)) {
    getParser().Lex(); // Consume the EndOfStatement.
    return false;
  }

  // Parse first operand.
  if (parseOperand(Operands, Name))
    return true;

  // Parse until end of statement, consuming commas between operands.
  while (getLexer().is(AsmToken::Comma)) {
    // Consume comma token.
    getLexer().Lex();

    // Parse next operand.
    if (parseOperand(Operands, Name))
      return true;
  }

  if (getLexer().isNot(AsmToken::EndOfStatement)) {
    SMLoc Loc = getLexer().getLoc();
    getParser().eatToEndOfStatement();
    return Error(Loc, "unexpected token");
  }

  getParser().Lex(); // Consume the EndOfStatement.
  return false;
}

bool SBFAsmParser::ParseDirective(AsmToken DirectiveID) { return true; }

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeSBFAsmParser() {
  RegisterMCAsmParser<SBFAsmParser> XX(getTheSBFXTarget());
}
