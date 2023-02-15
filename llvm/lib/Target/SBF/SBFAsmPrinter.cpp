//===-- SBFAsmPrinter.cpp - SBF LLVM assembly writer ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to the SBF assembly language.
//
//===----------------------------------------------------------------------===//

#include "SBF.h"
#include "SBFInstrInfo.h"
#include "SBFMCInstLower.h"
#include "SBFTargetMachine.h"
#include "BTFDebug.h"
#include "MCTargetDesc/SBFInstPrinter.h"
#include "MCTargetDesc/SBFMCTargetDesc.h"
#include "TargetInfo/SBFTargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/raw_ostream.h"
using namespace llvm;

#define DEBUG_TYPE "asm-printer"

extern cl::opt<unsigned> SBFAsmWriterVariant;
static cl::opt<bool> SBFEnableBTFEmission(
    "sbf-enable-btf-emission", cl::Hidden, cl::init(false),
    cl::desc("Enable BTF debuginfo sections to be emitted"));

namespace {
class SBFAsmPrinter : public AsmPrinter {
public:
  explicit SBFAsmPrinter(TargetMachine &TM,
                         std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer)), BTF(nullptr) {}

  StringRef getPassName() const override { return "SBF Assembly Printer"; }
  bool doInitialization(Module &M) override;
  void printOperand(const MachineInstr *MI, int OpNum, raw_ostream &O);
  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       const char *ExtraCode, raw_ostream &O) override;
  bool PrintAsmMemoryOperand(const MachineInstr *MI, unsigned OpNum,
                             const char *ExtraCode, raw_ostream &O) override;

  void emitInstruction(const MachineInstr *MI) override;

private:
  BTFX::BTFDebug *BTF;
};
} // namespace

bool SBFAsmPrinter::doInitialization(Module &M) {
  AsmPrinter::doInitialization(M);

  // Only emit BTF when debuginfo available.
  // Unsupported for Solana:
  // https://github.com/solana-labs/llvm-project/issues/37
  if (MAI->doesSupportDebugInformation() && !M.debug_compile_units().empty() &&
      SBFEnableBTFEmission) {
    BTF = new BTFX::BTFDebug(this);
    Handlers.push_back(HandlerInfo(std::unique_ptr<BTFX::BTFDebug>(BTF), "emit",
                                   "Debug Info Emission", "BTF",
                                   "BTF Emission"));
  }

  return false;
}

void SBFAsmPrinter::printOperand(const MachineInstr *MI, int OpNum,
                                 raw_ostream &O) {
  const MachineOperand &MO = MI->getOperand(OpNum);

  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    O << SBFInstPrinter::getRegisterName(MO.getReg());
    break;

  case MachineOperand::MO_Immediate:
    O << MO.getImm();
    break;

  case MachineOperand::MO_MachineBasicBlock:
    O << *MO.getMBB()->getSymbol();
    break;

  case MachineOperand::MO_GlobalAddress:
    O << *getSymbol(MO.getGlobal());
    break;

  case MachineOperand::MO_BlockAddress: {
    MCSymbol *BA = GetBlockAddressSymbol(MO.getBlockAddress());
    O << BA->getName();
    break;
  }

  case MachineOperand::MO_ExternalSymbol:
    O << *GetExternalSymbolSymbol(MO.getSymbolName());
    break;

  case MachineOperand::MO_JumpTableIndex:
  case MachineOperand::MO_ConstantPoolIndex:
  default:
    llvm_unreachable("<unknown operand type>");
  }
}

bool SBFAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                    const char *ExtraCode, raw_ostream &O) {
  if (ExtraCode && ExtraCode[0])
    return AsmPrinter::PrintAsmOperand(MI, OpNo, ExtraCode, O);

  printOperand(MI, OpNo, O);
  return false;
}

bool SBFAsmPrinter::PrintAsmMemoryOperand(const MachineInstr *MI,
                                          unsigned OpNum, const char *ExtraCode,
                                          raw_ostream &O) {
  assert(OpNum + 1 < MI->getNumOperands() && "Insufficient operands");
  const MachineOperand &BaseMO = MI->getOperand(OpNum);
  const MachineOperand &OffsetMO = MI->getOperand(OpNum + 1);
  assert(BaseMO.isReg() && "Unexpected base pointer for inline asm memory operand.");
  assert(OffsetMO.isImm() && "Unexpected offset for inline asm memory operand.");
  int Offset = OffsetMO.getImm();

  if (ExtraCode)
    return true; // Unknown modifier.

  if (SBFAsmWriterVariant == 1)
    O << "(";
  O << SBFInstPrinter::getRegisterName(BaseMO.getReg());
  if (Offset < 0)
    O << " - " << -Offset;
  else
    O << " + " << Offset;
  if (SBFAsmWriterVariant == 1)
    O << ")";

  return false;
}

void SBFAsmPrinter::emitInstruction(const MachineInstr *MI) {
  SBF_MC::verifyInstructionPredicates(MI->getOpcode(),
                                      getSubtargetInfo().getFeatureBits());

  MCInst TmpInst;

  if (!BTF || !BTF->InstLower(MI, TmpInst)) {
    SBFMCInstLower MCInstLowering(OutContext, *this);
    MCInstLowering.Lower(MI, TmpInst);
  }
  EmitToStreamer(*OutStreamer, TmpInst);
}

// Force static initialization.
extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeSBFAsmPrinter() {
  RegisterAsmPrinter<SBFAsmPrinter> XX(getTheSBFXTarget());
}
