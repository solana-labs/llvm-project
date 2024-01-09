//===-- SBFTargetFeatures.td - Target Features for SBF Target ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file describes the SBF target features in TableGen format.
//
//===----------------------------------------------------------------------===//

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
                                   "Enable static syscalls">;

def FeatureDisableNeg : SubtargetFeature<"no-neg", "DisableNeg", "true",
                                    "Disable the neg instruction">;

def FeatureReverseSubImm : SubtargetFeature<"reverse-sub", "ReverseSubImm", "true",
                                    "Reverse the operands in the 'sub reg, imm' instruction">;

def FeatureDisableLddw : SubtargetFeature<"no-lddw", "NoLddw", "true",
                                    "Disable the lddw instruction">;

def FeatureCallxRegSrc : SubtargetFeature<"callx-reg-src", "CallxRegSrc", "true",
                                    "Encode Callx destination register in the src field">;

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, NoItineraries, Features>;

def : Proc<"generic", []>;
def : Proc<"v1", []>;
def : Proc<"v2", []>;
def : Proc<"v3", []>;
def : Proc<"probe", []>;
def : Proc<"sbfv2", [FeatureSolana, FeatureDynamicFrames, FeatureSdiv, FeatureRelocAbs64, FeatureStaticSyscalls,
                        FeatureDisableNeg, FeatureReverseSubImm, FeatureDisableLddw, FeatureCallxRegSrc]>;