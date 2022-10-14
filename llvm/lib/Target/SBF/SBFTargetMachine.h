//===-- SBFTargetMachine.h - Define TargetMachine for SBF --- C++ ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares the SBF specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SBF_SBFTARGETMACHINE_H
#define LLVM_LIB_TARGET_SBF_SBFTARGETMACHINE_H

#include "SBFSubtarget.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class SBFTargetMachine : public LLVMTargetMachine {
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
  SBFSubtarget Subtarget;

public:
  SBFTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                   StringRef FS, const TargetOptions &Options,
                   Optional<Reloc::Model> RM, Optional<CodeModel::Model> CM,
                   CodeGenOpt::Level OL, bool JIT);

  const SBFSubtarget *getSubtargetImpl() const { return &Subtarget; }
  const SBFSubtarget *getSubtargetImpl(const Function &) const override {
    return &Subtarget;
  }

  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

  TargetTransformInfo getTargetTransformInfo(const Function &F) override;

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }

  void adjustPassManager(PassManagerBuilder &) override;
  void registerPassBuilderCallbacks(PassBuilder &PB) override;
};
}

#endif
