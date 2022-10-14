//===-- SBFInstrFormats.td - SBF Instruction Formats -------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

class SBFOpClass<bits<3> val> {
  bits<3> Value = val;
}

def SBF_LD    : SBFOpClass<0x0>;
def SBF_LDX   : SBFOpClass<0x1>;
def SBF_ST    : SBFOpClass<0x2>;
def SBF_STX   : SBFOpClass<0x3>;
def SBF_ALU   : SBFOpClass<0x4>;
def SBF_JMP   : SBFOpClass<0x5>;
def SBF_JMP32 : SBFOpClass<0x6>;
def SBF_ALU64 : SBFOpClass<0x7>;

class SBFSrcType<bits<1> val> {
  bits<1> Value = val;
}

def SBF_K : SBFSrcType<0x0>;
def SBF_X : SBFSrcType<0x1>;

class SBFArithOp<bits<4> val> {
  bits<4> Value = val;
}

def SBF_ADD  : SBFArithOp<0x0>;
def SBF_SUB  : SBFArithOp<0x1>;
def SBF_MUL  : SBFArithOp<0x2>;
def SBF_DIV  : SBFArithOp<0x3>;
def SBF_OR   : SBFArithOp<0x4>;
def SBF_AND  : SBFArithOp<0x5>;
def SBF_LSH  : SBFArithOp<0x6>;
def SBF_RSH  : SBFArithOp<0x7>;
def SBF_NEG  : SBFArithOp<0x8>;
def SBF_XOR  : SBFArithOp<0xa>;
def SBF_MOV  : SBFArithOp<0xb>;
def SBF_ARSH : SBFArithOp<0xc>;
def SBF_END  : SBFArithOp<0xd>;
def SBF_SDIV : SBFArithOp<0xe>;

def SBF_XCHG    : SBFArithOp<0xe>;
def SBF_CMPXCHG : SBFArithOp<0xf>;

class SBFEndDir<bits<1> val> {
  bits<1> Value = val;
}

def SBF_TO_LE : SBFSrcType<0x0>;
def SBF_TO_BE : SBFSrcType<0x1>;

class SBFJumpOp<bits<4> val> {
  bits<4> Value = val;
}

def SBF_JA   : SBFJumpOp<0x0>;
def SBF_JEQ  : SBFJumpOp<0x1>;
def SBF_JGT  : SBFJumpOp<0x2>;
def SBF_JGE  : SBFJumpOp<0x3>;
def SBF_JNE  : SBFJumpOp<0x5>;
def SBF_JSGT : SBFJumpOp<0x6>;
def SBF_JSGE : SBFJumpOp<0x7>;
def SBF_CALL : SBFJumpOp<0x8>;
def SBF_EXIT : SBFJumpOp<0x9>;
def SBF_JLT  : SBFJumpOp<0xa>;
def SBF_JLE  : SBFJumpOp<0xb>;
def SBF_JSLT : SBFJumpOp<0xc>;
def SBF_JSLE : SBFJumpOp<0xd>;

class SBFWidthModifer<bits<2> val> {
  bits<2> Value = val;
}

def SBF_W  : SBFWidthModifer<0x0>;
def SBF_H  : SBFWidthModifer<0x1>;
def SBF_B  : SBFWidthModifer<0x2>;
def SBF_DW : SBFWidthModifer<0x3>;

class SBFModeModifer<bits<3> val> {
  bits<3> Value = val;
}

def SBF_IMM  : SBFModeModifer<0x0>;
def SBF_ABS  : SBFModeModifer<0x1>;
def SBF_IND  : SBFModeModifer<0x2>;
def SBF_MEM  : SBFModeModifer<0x3>;
def SBF_ATOMIC : SBFModeModifer<0x6>;

class SBFAtomicFlag<bits<4> val> {
  bits<4> Value = val;
}

def SBF_FETCH : SBFAtomicFlag<0x1>;

class InstSBF<dag outs, dag ins, string asmstr, list<dag> pattern>
  : Instruction {
  field bits<64> Inst;
  field bits<64> SoftFail = 0;
  let Size = 8;

  let Namespace = "SBF";
  let DecoderNamespace = "SBF";

  SBFOpClass SBFClass;
  let Inst{58-56} = SBFClass.Value;

  dag OutOperandList = outs;
  dag InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
}

// Pseudo instructions
class Pseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
  : InstSBF<outs, ins, asmstr, pattern> {
  let Inst{63-0} = 0;
  let isPseudo = 1;
}
