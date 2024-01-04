//===-- SBF.td - Describe the SBF Target Machine -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

include "SBFRegisterInfo.td"
include "SBFCallingConv.td"
include "SBFInstrInfo.td"

def SBFInstrInfo : InstrInfo;
//===----------------------------------------------------------------------===//
// Assembly printer
//===----------------------------------------------------------------------===//

def SBFAsmWriter : AsmWriter {
  string AsmWriterClassName  = "InstPrinter";
  int Variant = 0;
  bit isMCAsmWriter = 1;
}

//===----------------------------------------------------------------------===//
// Assembly parser
//===----------------------------------------------------------------------===//

def SBFAsmParser : AsmParser;

def SBFAsmParserVariant : AsmParserVariant {
  int Variant = 0;
  string Name = "sbf";
  string BreakCharacters = ".";
}

//===----------------------------------------------------------------------===//
// Target Declaration
//===----------------------------------------------------------------------===//

def SBF : Target {
  let InstructionSet = SBFInstrInfo;
  let AssemblyWriters = [SBFAsmWriter];
  let AssemblyParsers = [SBFAsmParser];
  let AssemblyParserVariants = [SBFAsmParserVariant];
}
