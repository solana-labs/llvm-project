//===-- SBFTargetMachine.cpp - Define TargetMachine for SBF ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Implements the info about SBF target spec.
//
//===----------------------------------------------------------------------===//

#include "SBFTargetMachine.h"
#include "SBF.h"
#include "SBFTargetTransformInfo.h"
#include "MCTargetDesc/SBFMCAsmInfo.h"
#include "TargetInfo/SBFTargetInfo.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/PassManager.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Target/TargetOptions.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Scalar.h"
#include "llvm/Transforms/Scalar/SimplifyCFG.h"
#include "llvm/Transforms/Utils/SimplifyCFGOptions.h"
using namespace llvm;

static cl::
opt<bool> DisableMIPeephole("disable-sbf-peephole", cl::Hidden,
                            cl::desc("Disable machine peepholes for SBF"));

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeSBFTarget() {
  // Register the target.
  RegisterTargetMachine<SBFTargetMachine> XX(getTheSBFXTarget());

  PassRegistry &PR = *PassRegistry::getPassRegistry();
  initializeSBFAbstractMemberAccessLegacyPassPass(PR);
  initializeSBFPreserveDITypePass(PR);
  initializeSBFIRPeepholePass(PR);
  initializeSBFAdjustOptPass(PR);
  initializeSBFCheckAndAdjustIRPass(PR);
  initializeSBFMIPeepholePass(PR);
  initializeSBFMIPeepholeTruncElimPass(PR);
}

// DataLayout: little or big endian
static std::string computeDataLayout(const Triple &TT, StringRef FS) {
  // TOOD: jle; specialize this (and elsewhere) to Solana-only once the new
  // back-end is integrated; e.g. we won't need IsSolana, etc.
  assert(TT.getArch() == Triple::sbf && "expected Triple::sbf");
  return "e-m:e-p:64:64-i64:64-n32:64-S128";
}

static Reloc::Model getEffectiveRelocModel(Optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::PIC_);
}

SBFTargetMachine::SBFTargetMachine(const Target &T, const Triple &TT,
                                   StringRef CPU, StringRef FS,
                                   const TargetOptions &Options,
                                   Optional<Reloc::Model> RM,
                                   Optional<CodeModel::Model> CM,
                                   CodeGenOpt::Level OL, bool JIT)
    : LLVMTargetMachine(T, computeDataLayout(TT, FS), TT, CPU, FS, Options,
                        getEffectiveRelocModel(RM),
                        getEffectiveCodeModel(CM, CodeModel::Small), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()),
      Subtarget(TT, std::string(CPU), std::string(FS), *this) {
  initAsmInfo();

  SBFMCAsmInfo *MAI =
      static_cast<SBFMCAsmInfo *>(const_cast<MCAsmInfo *>(AsmInfo.get()));
  MAI->setDwarfUsesRelocationsAcrossSections(!Subtarget.getUseDwarfRIS());
  MAI->setSupportsDebugInformation(true);
}

namespace {
// SBF Code Generator Pass Configuration Options.
class SBFPassConfig : public TargetPassConfig {
public:
  SBFPassConfig(SBFTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  SBFTargetMachine &getSBFTargetMachine() const {
    return getTM<SBFTargetMachine>();
  }

  void addIRPasses() override;
  bool addInstSelector() override;
  void addMachineSSAOptimization() override;
  void addPreEmitPass() override;
};
}

TargetPassConfig *SBFTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new SBFPassConfig(*this, PM);
}

void SBFTargetMachine::adjustPassManager(PassManagerBuilder &Builder) {
 Builder.addExtension(
      PassManagerBuilder::EP_EarlyAsPossible,
      [&](const PassManagerBuilder &, legacy::PassManagerBase &PM) {
        PM.add(createSBFAbstractMemberAccess(this));
        PM.add(createSBFPreserveDIType());
        PM.add(createSBFIRPeephole());
      });

  Builder.addExtension(
      PassManagerBuilder::EP_Peephole,
      [&](const PassManagerBuilder &, legacy::PassManagerBase &PM) {
        PM.add(createCFGSimplificationPass(
            SimplifyCFGOptions().hoistCommonInsts(true)));
      });
  Builder.addExtension(
      PassManagerBuilder::EP_ModuleOptimizerEarly,
      [&](const PassManagerBuilder &, legacy::PassManagerBase &PM) {
        PM.add(createSBFAdjustOpt());
      });
}

void SBFTargetMachine::registerPassBuilderCallbacks(PassBuilder &PB) {
  PB.registerPipelineStartEPCallback(
      [=](ModulePassManager &MPM, OptimizationLevel) {
        FunctionPassManager FPM;
        FPM.addPass(SBFAbstractMemberAccessPass(this));
        FPM.addPass(SBFPreserveDITypePass());
        FPM.addPass(SBFIRPeepholePass());
        MPM.addPass(createModuleToFunctionPassAdaptor(std::move(FPM)));
      });
  PB.registerPeepholeEPCallback([=](FunctionPassManager &FPM,
                                    OptimizationLevel Level) {
    FPM.addPass(SimplifyCFGPass(SimplifyCFGOptions().hoistCommonInsts(true)));
  });
  PB.registerPipelineEarlySimplificationEPCallback(
      [=](ModulePassManager &MPM, OptimizationLevel) {
        MPM.addPass(SBFAdjustOptPass());
      });
}

void SBFPassConfig::addIRPasses() {
  addPass(createSBFCheckAndAdjustIR());
  TargetPassConfig::addIRPasses();
}

TargetTransformInfo
SBFTargetMachine::getTargetTransformInfo(const Function &F) const {
  return TargetTransformInfo(SBFTTIImpl(this, F));
}

// Install an instruction selector pass using
// the ISelDag to gen SBF code.
bool SBFPassConfig::addInstSelector() {
  addPass(createSBFISelDag(getSBFTargetMachine()));

  return false;
}

void SBFPassConfig::addMachineSSAOptimization() {
  addPass(createSBFMISimplifyPatchablePass());

  // The default implementation must be called first as we want eBPF
  // Peephole ran at last.
  TargetPassConfig::addMachineSSAOptimization();

  const SBFSubtarget *Subtarget = getSBFTargetMachine().getSubtargetImpl();
  if (!DisableMIPeephole) {
    if (Subtarget->getHasAlu32())
      addPass(createSBFMIPeepholePass());
    addPass(createSBFMIPeepholeTruncElimPass());
  }
}

void SBFPassConfig::addPreEmitPass() {
  addPass(createSBFMIPreEmitCheckingPass());
  if (getOptLevel() != CodeGenOpt::None)
    if (!DisableMIPeephole)
      addPass(createSBFMIPreEmitPeepholePass());
}
