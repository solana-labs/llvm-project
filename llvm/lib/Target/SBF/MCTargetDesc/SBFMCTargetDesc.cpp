//===-- SBFMCTargetDesc.cpp - SBF Target Descriptions ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file provides SBF specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/SBFMCTargetDesc.h"
#include "MCTargetDesc/SBFInstPrinter.h"
#include "MCTargetDesc/SBFMCAsmInfo.h"
#include "TargetInfo/SBFTargetInfo.h"
#include "llvm/BinaryFormat/ELF.h"
#include "llvm/MC/MCAsmBackend.h"
#include "llvm/MC/MCCodeEmitter.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCInstrAnalysis.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCObjectWriter.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/Host.h"

#define GET_INSTRINFO_MC_DESC
#include "SBFGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "SBFGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "SBFGenRegisterInfo.inc"

using namespace llvm;

static MCInstrInfo *createSBFMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitSBFMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createSBFMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitSBFMCRegisterInfo(X, SBF::R11 /* RAReg doesn't exist */);
  return X;
}

static MCSubtargetInfo *createSBFMCSubtargetInfo(const Triple &TT,
                                                 StringRef CPU, StringRef FS) {
  return createSBFMCSubtargetInfoImpl(TT, CPU, /*TuneCPU*/ CPU, FS);
}

static MCStreamer *createSBFMCStreamer(const Triple &T, MCContext &Ctx,
                                       std::unique_ptr<MCAsmBackend> &&MAB,
                                       std::unique_ptr<MCObjectWriter> &&OW,
                                       std::unique_ptr<MCCodeEmitter> &&Emitter,
                                       bool RelaxAll) {
  MCELFStreamer *S =
      new MCELFStreamer(Ctx, std::move(MAB), std::move(OW), std::move(Emitter));
  MCAssembler &A = S->getAssembler();
  if (RelaxAll)
    A.setRelaxAll(true);

  const MCSubtargetInfo *STI = Ctx.getSubtargetInfo();
  if (STI->getCPU() == "sbfv2") {
    A.setELFHeaderEFlags(llvm::ELF::EF_SBF_V2);
  }

  return S;
}

static MCInstPrinter *createSBFMCInstPrinter(const Triple &T,
                                             unsigned SyntaxVariant,
                                             const MCAsmInfo &MAI,
                                             const MCInstrInfo &MII,
                                             const MCRegisterInfo &MRI) {
  if (SyntaxVariant == 0)
    return new SBFInstPrinter(MAI, MII, MRI);
  return nullptr;
}

namespace {

class SBFMCInstrAnalysis : public MCInstrAnalysis {
public:
  explicit SBFMCInstrAnalysis(const MCInstrInfo *Info)
      : MCInstrAnalysis(Info) {}

  bool evaluateBranch(const MCInst &Inst, uint64_t Addr, uint64_t Size,
                      uint64_t &Target) const override {
    // The target is the 3rd operand of cond inst and the 1st of uncond inst.
    int16_t Imm;
    if (isConditionalBranch(Inst)) {
      Imm = Inst.getOperand(2).getImm();
    } else if (isUnconditionalBranch(Inst))
      Imm = Inst.getOperand(0).getImm();
    else
      return false;

    Target = Addr + Size + Imm * Size;
    return true;
  }
};

} // end anonymous namespace

static MCInstrAnalysis *createSBFInstrAnalysis(const MCInstrInfo *Info) {
  return new SBFMCInstrAnalysis(Info);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeSBFTargetMC() {
  for (Target *T : {&getTheSBFXTarget()}) {
    // Register the MC asm info.
    RegisterMCAsmInfo<SBFMCAsmInfo> X(*T);

    // Register the MC instruction info.
    TargetRegistry::RegisterMCInstrInfo(*T, createSBFMCInstrInfo);

    // Register the MC register info.
    TargetRegistry::RegisterMCRegInfo(*T, createSBFMCRegisterInfo);

    // Register the MC subtarget info.
    TargetRegistry::RegisterMCSubtargetInfo(*T,
                                            createSBFMCSubtargetInfo);

    // Register the object streamer
    TargetRegistry::RegisterELFStreamer(*T, createSBFMCStreamer);

    // Register the MCInstPrinter.
    TargetRegistry::RegisterMCInstPrinter(*T, createSBFMCInstPrinter);

    // Register the MC instruction analyzer.
    TargetRegistry::RegisterMCInstrAnalysis(*T, createSBFInstrAnalysis);
  }

  // Register the MC code emitter
  TargetRegistry::RegisterMCCodeEmitter(getTheSBFXTarget(),
                                        createSBFMCCodeEmitter);

  // Register the ASM Backend
  TargetRegistry::RegisterMCAsmBackend(getTheSBFXTarget(),
                                       createSBFAsmBackend);
}
