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
#include "BPFTargetMachine.h"
#include "GISel/BPFCallLowering.h"
#include "GISel/BPFLegalizerInfo.h"
#include "GISel/BPFRegisterBankInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/TargetParser/Host.h"

using namespace llvm;

#define DEBUG_TYPE "bpf-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "BPFGenSubtargetInfo.inc"

static cl::opt<bool> Disable_ldsx("disable-ldsx", cl::Hidden, cl::init(false),
  cl::desc("Disable ldsx insns"));
static cl::opt<bool> Disable_movsx("disable-movsx", cl::Hidden, cl::init(false),
  cl::desc("Disable movsx insns"));
static cl::opt<bool> Disable_bswap("disable-bswap", cl::Hidden, cl::init(false),
  cl::desc("Disable bswap insns"));
static cl::opt<bool> Disable_sdiv_smod("disable-sdiv-smod", cl::Hidden,
  cl::init(false), cl::desc("Disable sdiv/smod insns"));
static cl::opt<bool> Disable_gotol("disable-gotol", cl::Hidden, cl::init(false),
  cl::desc("Disable gotol insn"));
static cl::opt<bool>
    Disable_StoreImm("disable-storeimm", cl::Hidden, cl::init(false),
                     cl::desc("Disable BPF_ST (immediate store) insn"));

void BPFSubtarget::anchor() {}

BPFSubtarget &BPFSubtarget::initializeSubtargetDependencies(const Triple &TT,
                                                            StringRef CPU,
                                                            StringRef FS) {
  initializeEnvironment(TT);
  initSubtargetFeatures(CPU, FS);
  return *this;
}

void BPFSubtarget::initializeEnvironment(const Triple &TT) {
  // TODO: jle: remove, sbf is now provided by the SBF backend.
  IsSolana = false;
  HasJmpExt = false;
  HasJmp32 = false;
  HasAlu32 = false;
  HasDynamicFrames = false;
  HasSdiv = false;
  UseDwarfRIS = false;
  HasLdsx = false;
  HasMovsx = false;
  HasBswap = false;
  HasSdivSmod = false;
  HasGotol = false;
  HasStoreImm = false;
}

void BPFSubtarget::initSubtargetFeatures(StringRef CPU, StringRef FS) {
  if (CPU == "probe")
    CPU = sys::detail::getHostCPUNameForBPF();

  ParseSubtargetFeatures(CPU, /*TuneCPU*/ CPU, FS);

  if (IsSolana) {
    report_fatal_error("The Solana target is not supported in BPF. Use SBF instead.");
  }

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
  if (CPU == "v4") {
    HasJmpExt = true;
    HasJmp32 = true;
    HasAlu32 = true;
    HasLdsx = !Disable_ldsx;
    HasMovsx = !Disable_movsx;
    HasBswap = !Disable_bswap;
    HasSdivSmod = !Disable_sdiv_smod;
    HasGotol = !Disable_gotol;
    HasStoreImm = !Disable_StoreImm;
    return;
  }
}

BPFSubtarget::BPFSubtarget(const Triple &TT, const std::string &CPU,
                           const std::string &FS, const TargetMachine &TM)
    : BPFGenSubtargetInfo(TT, CPU, /*TuneCPU*/ CPU, FS), InstrInfo(),
      FrameLowering(initializeSubtargetDependencies(TT, CPU, FS)),
      TLInfo(TM, *this) {
  IsLittleEndian = TT.isLittleEndian();
  TSInfo.setSolanaFlag(false);

  CallLoweringInfo.reset(new BPFCallLowering(*getTargetLowering()));
  Legalizer.reset(new BPFLegalizerInfo(*this));
  auto *RBI = new BPFRegisterBankInfo(*getRegisterInfo());
  RegBankInfo.reset(RBI);

  InstSelector.reset(createBPFInstructionSelector(
      *static_cast<const BPFTargetMachine *>(&TM), *this, *RBI));
}

const CallLowering *BPFSubtarget::getCallLowering() const {
  return CallLoweringInfo.get();
}

InstructionSelector *BPFSubtarget::getInstructionSelector() const {
  return InstSelector.get();
}

const LegalizerInfo *BPFSubtarget::getLegalizerInfo() const {
  return Legalizer.get();
}

const RegisterBankInfo *BPFSubtarget::getRegBankInfo() const {
  return RegBankInfo.get();
}
