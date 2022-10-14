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

def DummyFeature : SubtargetFeature<"dummy", "isDummyMode",
                                    "true", "unused feature">;

def ALU32 : SubtargetFeature<"alu32", "HasAlu32", "true",
                             "Enable ALU32 instructions">;

def DwarfRIS: SubtargetFeature<"dwarfris", "UseDwarfRIS", "true",
                               "Disable MCAsmInfo DwarfUsesRelocationsAcrossSections">;

def FeatureSolana : SubtargetFeature<"solana", "IsSolana", "true",
                                     "Enable Solana extensions">;

def FeatureDynamicFrames : SubtargetFeature<"dynamic-frames", "HasDynamicFrames", "true",
                                            "Enable dynamic frames">;

def FeatureSdiv : SubtargetFeature<"sdiv", "HasSdiv", "true",
                                   "Enable native SBF_SDIV support">;

def FeatureRelocAbs64 : SubtargetFeature<"reloc-abs64", "UseRelocAbs64", "true",
                                   "Fix 64bit data relocations">;

def FeatureStaticSyscalls : SubtargetFeature<"static-syscalls", "HasStaticSyscalls", "true",
                                   "Marker feature used for conditional compilation">;

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", []>;
def : Proc<"v1", []>;
def : Proc<"v2", []>;
def : Proc<"v3", []>;
def : Proc<"probe", []>;
def : Proc<"sbfv2", [FeatureSolana, FeatureDynamicFrames, FeatureSdiv, FeatureRelocAbs64, FeatureStaticSyscalls]>;

def SBFInstPrinter : AsmWriter {
  string AsmWriterClassName  = "InstPrinter";
  bit isMCAsmWriter = 1;
}

def SBFAsmParser : AsmParser {
  bit HasMnemonicFirst = 0;
}

def SBFAsmParserVariant : AsmParserVariant {
  int Variant = 0;
  string Name = "SBF";
  string BreakCharacters = ".";
  string TokenizingCharacters = "#()[]=:.<>!+*/";
}

def SBF : Target {
  let InstructionSet = SBFInstrInfo;
  let AssemblyWriters = [SBFInstPrinter];
  let AssemblyParsers = [SBFAsmParser];
  let AssemblyParserVariants = [SBFAsmParserVariant];
}
