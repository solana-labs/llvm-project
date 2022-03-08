//===-- BPFSubtarget.cpp - BPF Subtarget Information ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements the BPF specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "BPFSubtarget.h"
#include "BPF.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Host.h"

using namespace llvm;

#define DEBUG_TYPE "bpf-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "BPFGenSubtargetInfo.inc"

void BPFSubtarget::anchor() {}

BPFSubtarget &BPFSubtarget::initializeSubtargetDependencies(const Triple &TT,
                                                            StringRef CPU,
                                                            StringRef FS) {
  initializeEnvironment(TT);
  initSubtargetFeatures(CPU, FS);
  return *this;
}

void BPFSubtarget::initializeEnvironment(const Triple &TT) {
  IsSolana = TT.getArch() == Triple::sbf;
  HasJmpExt = false;
  HasJmp32 = false;
  HasAlu32 = false;
  HasDynamicFrames = false;
  UseDwarfRIS = false;
}

void BPFSubtarget::initSubtargetFeatures(StringRef CPU, StringRef FS) {
  if (CPU == "probe")
    CPU = sys::detail::getHostCPUNameForBPF();

  ParseSubtargetFeatures(CPU, /*TuneCPU*/ CPU, FS);

  if (CPU == "v2") {
    HasJmpExt = true;
  }

  if (CPU == "v3") {
    HasJmpExt = true;
    HasJmp32 = true;
    HasAlu32 = true;
  }

  if (CPU == "sbfv2" && !HasDynamicFrames) {
    report_fatal_error("sbfv2 requires dynamic-frames\n", false);
  }
}

BPFSubtarget::BPFSubtarget(const Triple &TT, const std::string &CPU,
                           const std::string &FS, const TargetMachine &TM)
    : BPFGenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS), InstrInfo(),
      FrameLowering(initializeSubtargetDependencies(TT, CPU, FS)),
      TLInfo(TM, *this) {
  if (TT.getArch() == Triple::sbf) {
    IsSolana = true;
  }
  TSInfo.setSolanaFlag(IsSolana);
}
