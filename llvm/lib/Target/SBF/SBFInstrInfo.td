//===-- SBFInstrInfo.td - Target Description for SBF Target ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the SBF instructions in TableGen format.
//
//===----------------------------------------------------------------------===//

include "SBFInstrFormats.td"

// Instruction Operands and Patterns

// These are target-independent nodes, but have target-specific formats.
def SDT_SBFCallSeqStart : SDCallSeqStart<[SDTCisVT<0, iPTR>,
                                          SDTCisVT<1, iPTR>]>;
def SDT_SBFCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, iPTR>, SDTCisVT<1, iPTR>]>;
def SDT_SBFCall         : SDTypeProfile<0, -1, [SDTCisVT<0, iPTR>]>;
def SDT_SBFSetFlag      : SDTypeProfile<0, 3, [SDTCisSameAs<0, 1>]>;
def SDT_SBFSelectCC     : SDTypeProfile<1, 5, [SDTCisSameAs<1, 2>,
                                               SDTCisSameAs<0, 4>,
                                               SDTCisSameAs<4, 5>]>;
def SDT_SBFBrCC         : SDTypeProfile<0, 4, [SDTCisSameAs<0, 1>,
                                               SDTCisVT<3, OtherVT>]>;
def SDT_SBFWrapper      : SDTypeProfile<1, 1, [SDTCisSameAs<0, 1>,
                                               SDTCisPtrTy<0>]>;
def SDT_SBFMEMCPY       : SDTypeProfile<0, 4, [SDTCisVT<0, i64>,
                                               SDTCisVT<1, i64>,
                                               SDTCisVT<2, i64>,
                                               SDTCisVT<3, i64>]>;

def SBFcall         : SDNode<"SBFISD::CALL", SDT_SBFCall,
                             [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                              SDNPVariadic]>;
def SBFretflag      : SDNode<"SBFISD::RET_FLAG", SDTNone,
                             [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;
def SBFcallseq_start: SDNode<"ISD::CALLSEQ_START", SDT_SBFCallSeqStart,
                             [SDNPHasChain, SDNPOutGlue]>;
def SBFcallseq_end  : SDNode<"ISD::CALLSEQ_END",   SDT_SBFCallSeqEnd,
                             [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;
def SBFbrcc         : SDNode<"SBFISD::BR_CC", SDT_SBFBrCC,
                             [SDNPHasChain, SDNPOutGlue, SDNPInGlue]>;

def SBFselectcc     : SDNode<"SBFISD::SELECT_CC", SDT_SBFSelectCC, [SDNPInGlue]>;
def SBFWrapper      : SDNode<"SBFISD::Wrapper", SDT_SBFWrapper>;
def SBFmemcpy       : SDNode<"SBFISD::MEMCPY", SDT_SBFMEMCPY,
                             [SDNPHasChain, SDNPInGlue, SDNPOutGlue,
                              SDNPMayStore, SDNPMayLoad]>;
def SBFIsLittleEndian : Predicate<"CurDAG->getDataLayout().isLittleEndian()">;
def SBFIsBigEndian    : Predicate<"!CurDAG->getDataLayout().isLittleEndian()">;
def SBFHasALU32 : Predicate<"Subtarget->getHasAlu32()">;
def SBFNoALU32 : Predicate<"!Subtarget->getHasAlu32()">;
def SBFSubtargetSolana : Predicate<"Subtarget->isSolana()">;

def brtarget : Operand<OtherVT> {
  let PrintMethod = "printBrTargetOperand";
}
def calltarget : Operand<i64>;

def u64imm   : Operand<i64> {
  let PrintMethod = "printImm64Operand";
}

def i64immSExt32 : PatLeaf<(i64 imm),
                [{return isInt<32>(N->getSExtValue()); }]>;
def i32immSExt32 : PatLeaf<(i32 imm),
                [{return isInt<32>(N->getSExtValue()); }]>;

// Addressing modes.
def ADDRri : ComplexPattern<i64, 2, "SelectAddr", [], []>;
def FIri : ComplexPattern<i64, 2, "SelectFIAddr", [add, or], []>;

// Address operands
def MEMri : Operand<i64> {
  let PrintMethod = "printMemOperand";
  let EncoderMethod = "getMemoryOpValue";
  let DecoderMethod = "decodeMemoryOpValue";
  let MIOperandInfo = (ops GPR, i16imm);
}

// Conditional code predicates - used for pattern matching for jump instructions
def SBF_CC_EQ  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETEQ);}]>;
def SBF_CC_NE  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETNE);}]>;
def SBF_CC_GE  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETGE);}]>;
def SBF_CC_GT  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETGT);}]>;
def SBF_CC_GTU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETUGT);}]>;
def SBF_CC_GEU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETUGE);}]>;
def SBF_CC_LE  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETLE);}]>;
def SBF_CC_LT  : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETLT);}]>;
def SBF_CC_LTU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETULT);}]>;
def SBF_CC_LEU : PatLeaf<(i64 imm),
                         [{return (N->getZExtValue() == ISD::SETULE);}]>;
def SBF_CC_EQ_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETEQ);}]>;
def SBF_CC_NE_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETNE);}]>;
def SBF_CC_GE_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETGE);}]>;
def SBF_CC_GT_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETGT);}]>;
def SBF_CC_GTU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETUGT);}]>;
def SBF_CC_GEU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETUGE);}]>;
def SBF_CC_LE_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETLE);}]>;
def SBF_CC_LT_32  : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETLT);}]>;
def SBF_CC_LTU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETULT);}]>;
def SBF_CC_LEU_32 : PatLeaf<(i32 imm),
                         [{return (N->getZExtValue() == ISD::SETULE);}]>;

// For arithmetic and jump instructions the 8-bit 'code'
// field is divided into three parts:
//
//  +----------------+--------+--------------------+
//  |   4 bits       |  1 bit |   3 bits           |
//  | operation code | source | instruction class  |
//  +----------------+--------+--------------------+
//  (MSB)                                      (LSB)
class TYPE_ALU_JMP<bits<4> op, bits<1> srctype,
                   dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstSBF<outs, ins, asmstr, pattern> {

  let Inst{63-60} = op;
  let Inst{59} = srctype;
}

//For load and store instructions the 8-bit 'code' field is divided as:
//
//  +--------+--------+-------------------+
//  | 3 bits | 2 bits |   3 bits          |
//  |  mode  |  size  | instruction class |
//  +--------+--------+-------------------+
//  (MSB)                             (LSB)
class TYPE_LD_ST<bits<3> mode, bits<2> size,
                 dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstSBF<outs, ins, asmstr, pattern> {

  let Inst{63-61} = mode;
  let Inst{60-59} = size;
}

// jump instructions
class JMP_RR<SBFJumpOp Opc, string Mnemonic, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, SBF_X.Value,
                   (outs),
                   (ins GPR:$dst, GPR:$src, brtarget:$BrDst),
                   "{" # Mnemonic # " $dst, $src, $BrDst"
                   "|if $dst " # OpcodeStr # " $src goto $BrDst}",
                   [(SBFbrcc i64:$dst, i64:$src, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<4> src;
  bits<16> BrDst;

  let Inst{55-52} = src;
  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let SBFClass = SBF_JMP;
}

class JMP_RI<SBFJumpOp Opc, string Mnemonic, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, SBF_K.Value,
                   (outs),
                   (ins GPR:$dst, i64imm:$imm, brtarget:$BrDst),
                   "{" # Mnemonic # " $dst, $imm, $BrDst"
                   "|if $dst " # OpcodeStr # " $imm goto $BrDst}",
                   [(SBFbrcc i64:$dst, i64immSExt32:$imm, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<16> BrDst;
  bits<32> imm;

  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let Inst{31-0} = imm;
  let SBFClass = SBF_JMP;
}

class JMP_RR_32<SBFJumpOp Opc, string Mnemonic, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, SBF_X.Value,
                   (outs),
                   (ins GPR32:$dst, GPR32:$src, brtarget:$BrDst),
                   "{" # Mnemonic # " $dst, $src, $BrDst"
                   "|if $dst " # OpcodeStr # " $src goto $BrDst}",
                   [(SBFbrcc i32:$dst, i32:$src, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<4> src;
  bits<16> BrDst;

  let Inst{55-52} = src;
  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let SBFClass = SBF_JMP32;
}

class JMP_RI_32<SBFJumpOp Opc, string Mnemonic, string OpcodeStr, PatLeaf Cond>
    : TYPE_ALU_JMP<Opc.Value, SBF_K.Value,
                   (outs),
                   (ins GPR32:$dst, i32imm:$imm, brtarget:$BrDst),
                   "{" # Mnemonic # " $dst, $imm, $BrDst"
                   "|if $dst " # OpcodeStr # " $imm goto $BrDst}",
                   [(SBFbrcc i32:$dst, i32immSExt32:$imm, Cond, bb:$BrDst)]> {
  bits<4> dst;
  bits<16> BrDst;
  bits<32> imm;

  let Inst{51-48} = dst;
  let Inst{47-32} = BrDst;
  let Inst{31-0} = imm;
  let SBFClass = SBF_JMP32;
}

multiclass J<SBFJumpOp Opc, string Mnemonic, string OpcodeStr, PatLeaf Cond,
             PatLeaf Cond32> {
  def _rr : JMP_RR<Opc, Mnemonic, OpcodeStr, Cond>;
  def _ri : JMP_RI<Opc, Mnemonic, OpcodeStr, Cond>;
  def _rr_32 : JMP_RR_32<Opc, Mnemonic, OpcodeStr, Cond32>;
  def _ri_32 : JMP_RI_32<Opc, Mnemonic, OpcodeStr, Cond32>;
}

let isBranch = 1, isTerminator = 1, hasDelaySlot=0 in {
// cmp+goto instructions
defm JEQ  : J<SBF_JEQ, "jeq", "==",  SBF_CC_EQ, SBF_CC_EQ_32>;
defm JUGT : J<SBF_JGT, "jgt", ">", SBF_CC_GTU, SBF_CC_GTU_32>;
defm JUGE : J<SBF_JGE, "jge", ">=", SBF_CC_GEU, SBF_CC_GEU_32>;
defm JNE  : J<SBF_JNE, "jne", "!=",  SBF_CC_NE, SBF_CC_NE_32>;
defm JSGT : J<SBF_JSGT, "jsgt",  "s>", SBF_CC_GT, SBF_CC_GT_32>;
defm JSGE : J<SBF_JSGE, "jsge",  "s>=", SBF_CC_GE, SBF_CC_GE_32>;
defm JULT : J<SBF_JLT, "jlt", "<", SBF_CC_LTU, SBF_CC_LTU_32>;
defm JULE : J<SBF_JLE, "jle", "<=", SBF_CC_LEU, SBF_CC_LEU_32>;
defm JSLT : J<SBF_JSLT, "jslt", "s<", SBF_CC_LT, SBF_CC_LT_32>;
defm JSLE : J<SBF_JSLE, "jsle", "s<=", SBF_CC_LE, SBF_CC_LE_32>;
}

// ALU instructions
class ALU_RI<SBFOpClass Class, SBFArithOp Opc,
             dag outs, dag ins, string asmstr, list<dag> pattern>
    : TYPE_ALU_JMP<Opc.Value, SBF_K.Value, outs, ins, asmstr, pattern> {
  bits<4> dst;
  bits<32> imm;

  let Inst{51-48} = dst;
  let Inst{31-0} = imm;
  let SBFClass = Class;
}

class ALU_RR<SBFOpClass Class, SBFArithOp Opc,
             dag outs, dag ins, string asmstr, list<dag> pattern>
    : TYPE_ALU_JMP<Opc.Value, SBF_X.Value, outs, ins, asmstr, pattern> {
  bits<4> dst;
  bits<4> src;

  let Inst{55-52} = src;
  let Inst{51-48} = dst;
  let SBFClass = Class;
}

multiclass ALU<SBFArithOp Opc, string Mnemonic, string OpcodeStr,
               SDNode OpNode> {
  def _rr : ALU_RR<SBF_ALU64, Opc,
                   (outs GPR:$dst),
                   (ins GPR:$src2, GPR:$src),
                   "{?!?" # Mnemonic # "64 $dst, $src" #
                   "!$dst " # OpcodeStr # " $src}",
                   [(set GPR:$dst, (OpNode i64:$src2, i64:$src))]>;
  def _ri : ALU_RI<SBF_ALU64, Opc,
                   (outs GPR:$dst),
                   (ins GPR:$src2, i64imm:$imm),
                   "{?!?" # Mnemonic # "64 $dst, $imm" #
                   "!$dst " # OpcodeStr #" $imm}",
                   [(set GPR:$dst, (OpNode GPR:$src2, i64immSExt32:$imm))]>;
  def _rr_32 : ALU_RR<SBF_ALU, Opc,
                   (outs GPR32:$dst),
                   (ins GPR32:$src2, GPR32:$src),
                   "{?!?" # Mnemonic # "32 $dst, $src" #
                   "!$dst " # OpcodeStr # " $src}",
                   [(set GPR32:$dst, (OpNode i32:$src2, i32:$src))]>;
  def _ri_32 : ALU_RI<SBF_ALU, Opc,
                   (outs GPR32:$dst),
                   (ins GPR32:$src2, i32imm:$imm),
                   "{?!?" # Mnemonic # "32 $dst, $imm" #
                   "!$dst " # OpcodeStr # " $imm}",
                   [(set GPR32:$dst, (OpNode GPR32:$src2, i32immSExt32:$imm))]>;
}

let Constraints = "$dst = $src2" in {
    let isAsCheapAsAMove = 1 in {
        defm ADD : ALU<SBF_ADD, "add", "+=", add>;
        defm SUB : ALU<SBF_SUB, "sub", "-=", sub>;
        defm OR  : ALU<SBF_OR, "or", "|=", or>;
        defm AND : ALU<SBF_AND, "and", "&=", and>;
        defm SLL : ALU<SBF_LSH, "lsh", "<<=", shl>;
        defm SRL : ALU<SBF_RSH, "rsh", ">>=", srl>;
        defm XOR : ALU<SBF_XOR, "xor", "^=", xor>;
        defm SRA : ALU<SBF_ARSH, "arsh", "s>>=", sra>;
    }

    defm MUL : ALU<SBF_MUL, "mul", "*=", mul>;
    defm DIV : ALU<SBF_DIV, "div", "/=", udiv>;

    let Predicates = [SBFSubtargetSolana] in {
        defm SDIV : ALU<SBF_SDIV, "sdiv", "s/=", sdiv>;
    }
}

class NEG_RR<SBFOpClass Class, SBFArithOp Opc,
             dag outs, dag ins, string asmstr, list<dag> pattern>
    : TYPE_ALU_JMP<Opc.Value, 0, outs, ins, asmstr, pattern> {
  bits<4> dst;

  let Inst{51-48} = dst;
  let SBFClass = Class;
}

let Constraints = "$dst = $src", isAsCheapAsAMove = 1 in {
  def NEG_64: NEG_RR<SBF_ALU64, SBF_NEG, (outs GPR:$dst), (ins GPR:$src),
                     "{neg64 $dst|$dst = -$src}",
                     [(set GPR:$dst, (ineg i64:$src))]>;
  def NEG_32: NEG_RR<SBF_ALU, SBF_NEG, (outs GPR32:$dst), (ins GPR32:$src),
                     "{neg32 $dst|$dst = -$src}",
                     [(set GPR32:$dst, (ineg i32:$src))]>;
}

class LD_IMM64<bits<4> Pseudo, string Mnemonic, string OpcodeStr>
    : TYPE_LD_ST<SBF_IMM.Value, SBF_DW.Value,
                 (outs GPR:$dst),
                 (ins u64imm:$imm),
                 "{" # Mnemonic # " $dst, $imm" #
                 "|$dst " # OpcodeStr # " $imm ll}",
                 [(set GPR:$dst, (i64 imm:$imm))]> {

  bits<4> dst;
  bits<64> imm;

  let Inst{51-48} = dst;
  let Inst{55-52} = Pseudo;
  let Inst{47-32} = 0;
  let Inst{31-0} = imm{31-0};
  let SBFClass = SBF_LD;
}

let isReMaterializable = 1, isAsCheapAsAMove = 1 in {
def LD_imm64 : LD_IMM64<0, "lddw", "=">;
def MOV_rr : ALU_RR<SBF_ALU64, SBF_MOV,
                    (outs GPR:$dst),
                    (ins GPR:$src),
                    "{mov64 $dst, $src|$dst = $src}",
                    []>;
def MOV_ri : ALU_RI<SBF_ALU64, SBF_MOV,
                    (outs GPR:$dst),
                    (ins i64imm:$imm),
                    "{mov64 $dst, $imm|$dst = $imm}",
                    [(set GPR:$dst, (i64 i64immSExt32:$imm))]>;
def MOV_rr_32 : ALU_RR<SBF_ALU, SBF_MOV,
                    (outs GPR32:$dst),
                    (ins GPR32:$src),
                    "{mov32 $dst, $src|$dst = $src}",
                    []>;
def MOV_ri_32 : ALU_RI<SBF_ALU, SBF_MOV,
                    (outs GPR32:$dst),
                    (ins i32imm:$imm),
                    "{mov32 $dst, $imm|$dst = $imm}",
                    [(set GPR32:$dst, (i32 i32immSExt32:$imm))]>;
}

def FI_ri
    : TYPE_LD_ST<SBF_IMM.Value, SBF_DW.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr),
                 "lea\t$dst, $addr",
                 [(set i64:$dst, FIri:$addr)]> {
  // This is a tentative instruction, and will be replaced
  // with MOV_rr and ADD_ri in PEI phase
  let Inst{51-48} = 0;
  let Inst{55-52} = 2;
  let Inst{47-32} = 0;
  let Inst{31-0} = 0;
  let SBFClass = SBF_LD;
  bit isPseudo = true;
}

def LD_pseudo
    : TYPE_LD_ST<SBF_IMM.Value, SBF_DW.Value,
                 (outs GPR:$dst),
                 (ins i64imm:$pseudo, u64imm:$imm),
                 "ld_pseudo\t$dst, $pseudo, $imm",
                 [(set GPR:$dst, (int_bpf_pseudo imm:$pseudo, imm:$imm))]> {

  bits<4> dst;
  bits<64> imm;
  bits<4> pseudo;

  let Inst{51-48} = dst;
  let Inst{55-52} = pseudo;
  let Inst{47-32} = 0;
  let Inst{31-0} = imm{31-0};
  let SBFClass = SBF_LD;
}

// STORE instructions
class STORE<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
            list<dag> Pattern>
    : TYPE_LD_ST<SBF_MEM.Value, SizeOp.Value,
                 (outs),
                 (ins GPR:$src, MEMri:$addr),
                 "{" # Mnemonic # " [$addr], $src" #
                 "|*(" # OpcodeStr # " *)($addr) = $src}",
                 Pattern> {
  bits<4> src;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = src;
  let Inst{47-32} = addr{15-0}; // offset
  let SBFClass = SBF_STX;
}

class STOREi64<SBFWidthModifer Opc, string Mnemonic, string OpcodeStr,
               PatFrag OpNode>
    : STORE<Opc, Mnemonic, OpcodeStr, [(OpNode i64:$src, ADDRri:$addr)]>;

let Predicates = [SBFNoALU32] in {
  def STW : STOREi64<SBF_W, "stxw", "u32", truncstorei32>;
  def STH : STOREi64<SBF_H, "stxh", "u16", truncstorei16>;
  def STB : STOREi64<SBF_B, "stxb", "u8", truncstorei8>;
}
def STD : STOREi64<SBF_DW, "stxdw", "u64", store>;

// LOAD instructions
class LOAD<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
           list<dag> Pattern>
    : TYPE_LD_ST<SBF_MEM.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr),
                 "{" # Mnemonic # " $dst, [$addr]" #
                 "|$dst = *(" # OpcodeStr # " *)($addr)}",
                 Pattern> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = dst;
  let Inst{55-52} = addr{19-16};
  let Inst{47-32} = addr{15-0};
  let SBFClass = SBF_LDX;
}

class LOADi64<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
              PatFrag OpNode>
    : LOAD<SizeOp, Mnemonic, OpcodeStr, [(set i64:$dst, (OpNode ADDRri:$addr))]>;

let isCodeGenOnly = 1 in {
  def CORE_MEM : TYPE_LD_ST<SBF_MEM.Value, SBF_W.Value,
                            (outs GPR:$dst),
                            (ins u64imm:$opcode, GPR:$src, u64imm:$offset),
                            "$dst = core_mem($opcode, $src, $offset)",
                            []>;
  def CORE_ALU32_MEM : TYPE_LD_ST<SBF_MEM.Value, SBF_W.Value,
                                  (outs GPR32:$dst),
                                  (ins u64imm:$opcode, GPR:$src, u64imm:$offset),
                                  "$dst = core_alu32_mem($opcode, $src, $offset)",
                                  []>;
  let Constraints = "$dst = $src" in {
    def CORE_SHIFT : ALU_RR<SBF_ALU64, SBF_LSH,
                             (outs GPR:$dst),
                             (ins u64imm:$opcode, GPR:$src, u64imm:$offset),
                             "$dst = core_shift($opcode, $src, $offset)",
                             []>;
  }
}

let Predicates = [SBFNoALU32] in {
  def LDW : LOADi64<SBF_W, "ldxw", "u32", zextloadi32>;
  def LDH : LOADi64<SBF_H, "ldxh", "u16", zextloadi16>;
  def LDB : LOADi64<SBF_B, "ldxb", "u8", zextloadi8>;
}

def LDD : LOADi64<SBF_DW, "ldxdw", "u64", load>;

class BRANCH<SBFJumpOp Opc, string Mnemonic, string OpcodeStr,
             list<dag> Pattern>
    : TYPE_ALU_JMP<Opc.Value, SBF_K.Value,
                   (outs),
                   (ins brtarget:$BrDst),
                   "{" # Mnemonic # " $BrDst" #
                   "|" # OpcodeStr # " $BrDst}",
                   Pattern> {
  bits<16> BrDst;

  let Inst{47-32} = BrDst;
  let SBFClass = SBF_JMP;
}

class CALL<string OpcodeStr>
    : TYPE_ALU_JMP<SBF_CALL.Value, SBF_K.Value,
                   (outs),
                   (ins calltarget:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   []> {
  bits<32> BrDst;

  let Inst{31-0} = BrDst;
  let SBFClass = SBF_JMP;
}

class CALLX<string OpcodeStr>
    : TYPE_ALU_JMP<SBF_CALL.Value, SBF_X.Value,
                   (outs),
                   (ins GPR:$BrDst),
                   !strconcat(OpcodeStr, " $BrDst"),
                   []> {
  bits<32> BrDst;

  let Inst{31-0} = BrDst;
  let SBFClass = SBF_JMP;
}

// Jump always
let isBranch = 1, isTerminator = 1, hasDelaySlot=0, isBarrier = 1 in {
  def JMP : BRANCH<SBF_JA, "ja", "goto", [(br bb:$BrDst)]>;
}

// Jump and link
let isCall=1, hasDelaySlot=0, Uses = [R11],
    // Potentially clobbered registers
    Defs = [R0, R1, R2, R3, R4, R5] in {
  def JAL  : CALL<"call">;
  def JALX  : CALLX<"callx">;
}

class NOP_I<string OpcodeStr>
    : TYPE_ALU_JMP<SBF_MOV.Value, SBF_X.Value,
                   (outs),
                   (ins i32imm:$imm),
                   !strconcat(OpcodeStr, "\t$imm"),
                   []> {
  // mov r0, r0 == nop
  let Inst{55-52} = 0;
  let Inst{51-48} = 0;
  let SBFClass = SBF_ALU64;
}

let hasSideEffects = 0, isCodeGenOnly = 1 in
  def NOP : NOP_I<"nop">;

class RET<string OpcodeStr>
    : TYPE_ALU_JMP<SBF_EXIT.Value, SBF_K.Value,
                   (outs),
                   (ins),
                   !strconcat(OpcodeStr, ""),
                   [(SBFretflag)]> {
  let Inst{31-0} = 0;
  let SBFClass = SBF_JMP;
}

let isReturn = 1, isTerminator = 1, hasDelaySlot=0, isBarrier = 1,
    isNotDuplicable = 1 in {
  def RET : RET<"exit">;
}

// ADJCALLSTACKDOWN/UP pseudo insns
let Defs = [R11], Uses = [R11], isCodeGenOnly = 1 in {
def ADJCALLSTACKDOWN : Pseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                              "#ADJCALLSTACKDOWN $amt1 $amt2",
                              [(SBFcallseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP   : Pseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                              "#ADJCALLSTACKUP $amt1 $amt2",
                              [(SBFcallseq_end timm:$amt1, timm:$amt2)]>;
}

let usesCustomInserter = 1, isCodeGenOnly = 1 in {
  def Select : Pseudo<(outs GPR:$dst),
                      (ins GPR:$lhs, GPR:$rhs, i64imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (SBFselectcc i64:$lhs, i64:$rhs, (i64 imm:$imm), i64:$src, i64:$src2))]>;
  def Select_Ri : Pseudo<(outs GPR:$dst),
                      (ins GPR:$lhs, i64imm:$rhs, i64imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (SBFselectcc i64:$lhs, (i64immSExt32:$rhs), (i64 imm:$imm), i64:$src, i64:$src2))]>;
  def Select_64_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR:$lhs, GPR:$rhs, i64imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (SBFselectcc i64:$lhs, i64:$rhs, (i64 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_Ri_64_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR:$lhs, i64imm:$rhs, i64imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (SBFselectcc i64:$lhs, (i64immSExt32:$rhs), (i64 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR32:$lhs, GPR32:$rhs, i32imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (SBFselectcc i32:$lhs, i32:$rhs, (i32 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_Ri_32 : Pseudo<(outs GPR32:$dst),
                      (ins GPR32:$lhs, i32imm:$rhs, i32imm:$imm, GPR32:$src, GPR32:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i32:$dst,
                       (SBFselectcc i32:$lhs, (i32immSExt32:$rhs), (i32 imm:$imm), i32:$src, i32:$src2))]>;
  def Select_32_64 : Pseudo<(outs GPR:$dst),
                      (ins GPR32:$lhs, GPR32:$rhs, i32imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (SBFselectcc i32:$lhs, i32:$rhs, (i32 imm:$imm), i64:$src, i64:$src2))]>;
  def Select_Ri_32_64 : Pseudo<(outs GPR:$dst),
                      (ins GPR32:$lhs, i32imm:$rhs, i32imm:$imm, GPR:$src, GPR:$src2),
                      "# Select PSEUDO $dst = $lhs $imm $rhs ? $src : $src2",
                      [(set i64:$dst,
                       (SBFselectcc i32:$lhs, (i32immSExt32:$rhs), (i32 imm:$imm), i64:$src, i64:$src2))]>;
}

// load 64-bit global addr into register
def : Pat<(SBFWrapper tglobaladdr:$in), (LD_imm64 tglobaladdr:$in)>;

// 0xffffFFFF doesn't fit into simm32, optimize common case
def : Pat<(i64 (and (i64 GPR:$src), 0xffffFFFF)),
          (SRL_ri (SLL_ri (i64 GPR:$src), 32), 32)>;

// Calls
def : Pat<(SBFcall tglobaladdr:$dst), (JAL tglobaladdr:$dst)>;
def : Pat<(SBFcall texternalsym:$dst), (JAL texternalsym:$dst)>;
def : Pat<(SBFcall imm:$dst), (JAL imm:$dst)>;
def : Pat<(SBFcall GPR:$dst), (JALX GPR:$dst)>;

// Loads
let Predicates = [SBFNoALU32] in {
  def : Pat<(i64 (extloadi8  ADDRri:$src)), (i64 (LDB ADDRri:$src))>;
  def : Pat<(i64 (extloadi16 ADDRri:$src)), (i64 (LDH ADDRri:$src))>;
  def : Pat<(i64 (extloadi32 ADDRri:$src)), (i64 (LDW ADDRri:$src))>;
}

// Atomic XADD for SBFNoALU32
class XADD<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
           PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr, GPR:$val),
                 "{" # Mnemonic # " [$addr], $val" #
                 "|lock *(" # OpcodeStr # " *)($addr) += $val}",
                 [(set GPR:$dst, (OpNode ADDRri:$addr, GPR:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = SBF_ADD.Value;
  let SBFClass = SBF_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [SBFNoALU32] in {
    def XADDW : XADD<SBF_W, "stxxaddw", "u32", atomic_load_add_32>;
  }
}

// Atomic add, and, or, xor
class ATOMIC_NOFETCH<SBFArithOp Opc, string Mnemonic, string Opstr>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SBF_DW.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr, GPR:$val),
                 "{?!?stxx" # Mnemonic # "dw [$addr], $val" #
                 "!lock *(u64 *)($addr) " # Opstr # "= $val}",
                 []> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let SBFClass = SBF_STX;
}

class ATOMIC32_NOFETCH<SBFArithOp Opc, string Mnemonic, string Opstr>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SBF_W.Value,
                 (outs GPR32:$dst),
                 (ins MEMri:$addr, GPR32:$val),
                 "{?!?stxx" # Mnemonic # "w [$addr], $val" #
                 "!lock *(u32 *)($addr) " # Opstr # "= $val}",
                 []> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let SBFClass = SBF_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [SBFHasALU32], DecoderNamespace = "SBFALU32" in {
    def XADDW32 : ATOMIC32_NOFETCH<SBF_ADD, "add", "+">;
    def XANDW32 : ATOMIC32_NOFETCH<SBF_AND, "and", "&">;
    def XORW32  : ATOMIC32_NOFETCH<SBF_OR, "or", "|">;
    def XXORW32 : ATOMIC32_NOFETCH<SBF_XOR, "xor", "^">;
  }

  def XADDD  : ATOMIC_NOFETCH<SBF_ADD, "add", "+">;
  def XANDD  : ATOMIC_NOFETCH<SBF_AND, "and", "&">;
  def XORD   : ATOMIC_NOFETCH<SBF_OR, "or", "|">;
  def XXORD  : ATOMIC_NOFETCH<SBF_XOR,"xor",  "^">;
}

// Atomic Fetch-and-<add, and, or, xor> operations
class XFALU64<SBFWidthModifer SizeOp, SBFArithOp Opc, string OpcodeStr,
              string OpcStr, PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr, GPR:$val),
                 "{stxxf" # OpcStr # "dw [$addr], $val" #
                 "|$dst = atomic_fetch_" # OpcStr # "((" # OpcodeStr # " *)($addr), $val)}",
                 [(set GPR:$dst, (OpNode ADDRri:$addr, GPR:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let Inst{3-0} = SBF_FETCH.Value;
  let SBFClass = SBF_STX;
}

class XFALU32<SBFWidthModifer SizeOp, SBFArithOp Opc, string OpcodeStr,
              string OpcStr, PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs GPR32:$dst),
                 (ins MEMri:$addr, GPR32:$val),
                 "{stxxf" # OpcStr  # "w [$addr], $val" #
                 "|$dst = atomic_fetch_" # OpcStr # "((" # OpcodeStr # " *)($addr), $val)}",
                 [(set GPR32:$dst, (OpNode ADDRri:$addr, GPR32:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = Opc.Value;
  let Inst{3-0} = SBF_FETCH.Value;
  let SBFClass = SBF_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [SBFHasALU32], DecoderNamespace = "SBFALU32" in {
    def XFADDW32 : XFALU32<SBF_W, SBF_ADD, "u32", "add", atomic_load_add_32>;
    def XFANDW32 : XFALU32<SBF_W, SBF_AND, "u32", "and", atomic_load_and_32>;
    def XFORW32  : XFALU32<SBF_W, SBF_OR,  "u32", "or",  atomic_load_or_32>;
    def XFXORW32 : XFALU32<SBF_W, SBF_XOR, "u32", "xor", atomic_load_xor_32>;
  }

  def XFADDD : XFALU64<SBF_DW, SBF_ADD, "u64", "add", atomic_load_add_64>;
  def XFANDD : XFALU64<SBF_DW, SBF_AND, "u64", "and", atomic_load_and_64>;
  def XFORD  : XFALU64<SBF_DW, SBF_OR,  "u64", "or",  atomic_load_or_64>;
  def XFXORD : XFALU64<SBF_DW, SBF_XOR, "u64", "xor", atomic_load_xor_64>;
}

// atomic_load_sub can be represented as a neg followed
// by an atomic_load_add.
def : Pat<(atomic_load_sub_32 ADDRri:$addr, GPR32:$val),
          (XFADDW32 ADDRri:$addr, (NEG_32 GPR32:$val))>;
def : Pat<(atomic_load_sub_64 ADDRri:$addr, GPR:$val),
          (XFADDD ADDRri:$addr, (NEG_64 GPR:$val))>;

let Predicates = [SBFSubtargetSolana], usesCustomInserter = 1, isCodeGenOnly = 1 in {
  def ATOMIC_FENCE : Pseudo<
    (outs),
    (ins),
    "#atomic_fence",
    [(atomic_fence timm, timm)]>;
}

// Atomic Exchange
class XCHG<SBFWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs GPR:$dst),
                 (ins MEMri:$addr, GPR:$val),
                 "{stxxchgdw [$addr], $val" #
                 "|$dst = xchg_" # OpcodeStr # "($addr, $val)}",
                 [(set GPR:$dst, (OpNode ADDRri:$addr,GPR:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = SBF_XCHG.Value;
  let Inst{3-0} = SBF_FETCH.Value;
  let SBFClass = SBF_STX;
}

class XCHG32<SBFWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs GPR32:$dst),
                 (ins MEMri:$addr, GPR32:$val),
                 "{stxxchgw [$addr], $val" #
                 "|$dst = xchg32_" # OpcodeStr # "($addr, $val)}",
                 [(set GPR32:$dst, (OpNode ADDRri:$addr,GPR32:$val))]> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = dst;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = SBF_XCHG.Value;
  let Inst{3-0} = SBF_FETCH.Value;
  let SBFClass = SBF_STX;
}

let Constraints = "$dst = $val" in {
  let Predicates = [SBFHasALU32], DecoderNamespace = "SBFALU32" in {
    def XCHGW32 : XCHG32<SBF_W, "32", atomic_swap_32>;
  }

  def XCHGD : XCHG<SBF_DW, "64", atomic_swap_64>;
}

// Compare-And-Exchange
class CMPXCHG<SBFWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs),
                 (ins MEMri:$addr, GPR:$new),
                 "{stxcmpxchgdw [$addr], $new" #
                 "|r0 = cmpxchg_" # OpcodeStr # "($addr, r0, $new)}",
                 [(set R0, (OpNode ADDRri:$addr, R0, GPR:$new))]> {
  bits<4> new;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = new;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = SBF_CMPXCHG.Value;
  let Inst{3-0} = SBF_FETCH.Value;
  let SBFClass = SBF_STX;
}

class CMPXCHG32<SBFWidthModifer SizeOp, string OpcodeStr, PatFrag OpNode>
    : TYPE_LD_ST<SBF_ATOMIC.Value, SizeOp.Value,
                 (outs),
                 (ins MEMri:$addr, GPR32:$new),
                 "{stxcmpxchgw [$addr], $new" #
                 "|w0 = cmpxchg32_" # OpcodeStr # "($addr, w0, $new)}",
                 [(set W0, (OpNode ADDRri:$addr, W0, GPR32:$new))]> {
  bits<4> new;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = new;
  let Inst{47-32} = addr{15-0}; // offset
  let Inst{7-4} = SBF_CMPXCHG.Value;
  let Inst{3-0} = SBF_FETCH.Value;
  let SBFClass = SBF_STX;
}

let Predicates = [SBFHasALU32], Defs = [W0], Uses = [W0],
    DecoderNamespace = "SBFALU32" in {
  def CMPXCHGW32 : CMPXCHG32<SBF_W, "32", atomic_cmp_swap_32>;
}

let Defs = [R0], Uses = [R0] in {
  def CMPXCHGD : CMPXCHG<SBF_DW, "64", atomic_cmp_swap_64>;
}

// bswap16, bswap32, bswap64
class BSWAP<bits<32> SizeOp, string OpcodeStr, SBFSrcType SrcType, list<dag> Pattern>
    : TYPE_ALU_JMP<SBF_END.Value, SrcType.Value,
                   (outs GPR:$dst),
                   (ins GPR:$src),
                   "{" # OpcodeStr # " $src" #
                   "|$dst = " # OpcodeStr # " $src}",
                   Pattern> {
  bits<4> dst;

  let Inst{51-48} = dst;
  let Inst{31-0} = SizeOp;
  let SBFClass = SBF_ALU;
}


let Constraints = "$dst = $src" in {
    let Predicates = [SBFIsLittleEndian] in {
        def BE16 : BSWAP<16, "be16", SBF_TO_BE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 48)))]>;
        def BE32 : BSWAP<32, "be32", SBF_TO_BE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 32)))]>;
        def BE64 : BSWAP<64, "be64", SBF_TO_BE, [(set GPR:$dst, (bswap GPR:$src))]>;
    }
    let Predicates = [SBFIsBigEndian] in {
        def LE16 : BSWAP<16, "le16", SBF_TO_LE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 48)))]>;
        def LE32 : BSWAP<32, "le32", SBF_TO_LE, [(set GPR:$dst, (srl (bswap GPR:$src), (i64 32)))]>;
        def LE64 : BSWAP<64, "le64", SBF_TO_LE, [(set GPR:$dst, (bswap GPR:$src))]>;
    }
}

let Defs = [R0, R1, R2, R3, R4, R5], Uses = [R6], hasSideEffects = 1,
    hasExtraDefRegAllocReq = 1, hasExtraSrcRegAllocReq = 1, mayLoad = 1 in {
class LOAD_ABS<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
               Intrinsic OpNode>
    : TYPE_LD_ST<SBF_ABS.Value, SizeOp.Value,
                 (outs),
                 (ins GPR:$skb, i64imm:$imm),
                 "{" # Mnemonic # " $imm" #
                 "|r0 = *(" # OpcodeStr # " *)skb[$imm]}",
                 [(set R0, (OpNode GPR:$skb, i64immSExt32:$imm))]> {
  bits<32> imm;

  let Inst{31-0} = imm;
  let SBFClass = SBF_LD;
}

class LOAD_IND<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
               Intrinsic OpNode>
    : TYPE_LD_ST<SBF_IND.Value, SizeOp.Value,
                 (outs),
                 (ins GPR:$skb, GPR:$val),
                 "{" # Mnemonic # " $val" #
                 "|r0 = *(" # OpcodeStr # " *)skb[$val]}",
                 [(set R0, (OpNode GPR:$skb, GPR:$val))]> {
  bits<4> val;

  let Inst{55-52} = val;
  let SBFClass = SBF_LD;
}
}

def LD_ABS_B : LOAD_ABS<SBF_B, "ldabsb", "u8", int_bpf_load_byte>;
def LD_ABS_H : LOAD_ABS<SBF_H, "ldabsh", "u16", int_bpf_load_half>;
def LD_ABS_W : LOAD_ABS<SBF_W, "ldabsw", "u32", int_bpf_load_word>;

def LD_IND_B : LOAD_IND<SBF_B, "ldindb", "u8", int_bpf_load_byte>;
def LD_IND_H : LOAD_IND<SBF_H, "ldindh", "u16", int_bpf_load_half>;
def LD_IND_W : LOAD_IND<SBF_W, "ldindw", "u32", int_bpf_load_word>;

let isCodeGenOnly = 1 in {
  def MOV_32_64 : ALU_RR<SBF_ALU, SBF_MOV,
                         (outs GPR:$dst), (ins GPR32:$src),
                         "{mov32 $dst, $src|$dst = $src}", []>;
}

def : Pat<(i64 (sext GPR32:$src)),
          (SRA_ri (SLL_ri (MOV_32_64 GPR32:$src), 32), 32)>;

def : Pat<(i64 (zext GPR32:$src)), (MOV_32_64 GPR32:$src)>;

// For i64 -> i32 truncation, use the 32-bit subregister directly.
def : Pat<(i32 (trunc GPR:$src)),
          (i32 (EXTRACT_SUBREG GPR:$src, sub_32))>;

// For i32 -> i64 anyext, we don't care about the high bits.
def : Pat<(i64 (anyext GPR32:$src)),
          (INSERT_SUBREG (i64 (IMPLICIT_DEF)), GPR32:$src, sub_32)>;

class STORE32<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
              list<dag> Pattern>
    : TYPE_LD_ST<SBF_MEM.Value, SizeOp.Value,
                 (outs),
                 (ins GPR32:$src, MEMri:$addr),
                 "{" # Mnemonic # " [$addr], $src" #
                 "|*("#OpcodeStr#" *)($addr) = $src}",
                 Pattern> {
  bits<4> src;
  bits<20> addr;

  let Inst{51-48} = addr{19-16}; // base reg
  let Inst{55-52} = src;
  let Inst{47-32} = addr{15-0}; // offset
  let SBFClass = SBF_STX;
}

class STOREi32<SBFWidthModifer Opc, string Mnemonic, string OpcodeStr,
               PatFrag OpNode>
    : STORE32<Opc, Mnemonic, OpcodeStr, [(OpNode i32:$src, ADDRri:$addr)]>;

let Predicates = [SBFHasALU32], DecoderNamespace = "SBFALU32" in {
  def STW32 : STOREi32<SBF_W, "stxw", "u32", store>;
  def STH32 : STOREi32<SBF_H, "stxh", "u16", truncstorei16>;
  def STB32 : STOREi32<SBF_B, "stxb", "u8", truncstorei8>;
}

class LOAD32<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
             list<dag> Pattern>
    : TYPE_LD_ST<SBF_MEM.Value, SizeOp.Value,
                (outs GPR32:$dst),
                (ins MEMri:$addr),
                 "{" # Mnemonic # " $dst, [$addr]" #
                "|$dst = *("#OpcodeStr#" *)($addr)}",
                Pattern> {
  bits<4> dst;
  bits<20> addr;

  let Inst{51-48} = dst;
  let Inst{55-52} = addr{19-16};
  let Inst{47-32} = addr{15-0};
  let SBFClass = SBF_LDX;
}

class LOADi32<SBFWidthModifer SizeOp, string Mnemonic, string OpcodeStr,
              PatFrag OpNode>
    : LOAD32<SizeOp, Mnemonic, OpcodeStr, [(set i32:$dst, (OpNode ADDRri:$addr))]>;

let Predicates = [SBFHasALU32], DecoderNamespace = "SBFALU32" in {
  def LDW32 : LOADi32<SBF_W, "ldxw", "u32", load>;
  def LDH32 : LOADi32<SBF_H, "ldxh", "u16", zextloadi16>;
  def LDB32 : LOADi32<SBF_B, "ldxb", "u8", zextloadi8>;
}

let Predicates = [SBFHasALU32] in {
  def : Pat<(truncstorei8 GPR:$src, ADDRri:$dst),
            (STB32 (EXTRACT_SUBREG GPR:$src, sub_32), ADDRri:$dst)>;
  def : Pat<(truncstorei16 GPR:$src, ADDRri:$dst),
            (STH32 (EXTRACT_SUBREG GPR:$src, sub_32), ADDRri:$dst)>;
  def : Pat<(truncstorei32 GPR:$src, ADDRri:$dst),
            (STW32 (EXTRACT_SUBREG GPR:$src, sub_32), ADDRri:$dst)>;
  def : Pat<(i32 (extloadi8 ADDRri:$src)), (i32 (LDB32 ADDRri:$src))>;
  def : Pat<(i32 (extloadi16 ADDRri:$src)), (i32 (LDH32 ADDRri:$src))>;
  def : Pat<(i64 (zextloadi8  ADDRri:$src)),
            (SUBREG_TO_REG (i64 0), (LDB32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (zextloadi16 ADDRri:$src)),
            (SUBREG_TO_REG (i64 0), (LDH32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (zextloadi32 ADDRri:$src)),
            (SUBREG_TO_REG (i64 0), (LDW32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (extloadi8  ADDRri:$src)),
            (SUBREG_TO_REG (i64 0), (LDB32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (extloadi16 ADDRri:$src)),
            (SUBREG_TO_REG (i64 0), (LDH32 ADDRri:$src), sub_32)>;
  def : Pat<(i64 (extloadi32 ADDRri:$src)),
            (SUBREG_TO_REG (i64 0), (LDW32 ADDRri:$src), sub_32)>;
}

let usesCustomInserter = 1, isCodeGenOnly = 1 in {
    def MEMCPY : Pseudo<
      (outs),
      (ins GPR:$dst, GPR:$src, i64imm:$len, i64imm:$align, variable_ops),
      "#memcpy dst: $dst, src: $src, len: $len, align: $align",
      [(SBFmemcpy GPR:$dst, GPR:$src, imm:$len, imm:$align)]>;
}
