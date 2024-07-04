//===-------------- SBFMIChecking.cpp - MI Checking Legality -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass performs checking to signal errors for certain illegal usages at
// MachineInstruction layer. Specially, the result of XADD{32,64} insn should
// not be used. The pass is done at the PreEmit pass right before the
// machine code is emitted at which point the register liveness information
// is still available.
//
//===----------------------------------------------------------------------===//

#include "SBF.h"
#include "SBFInstrInfo.h"
#include "SBFTargetMachine.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "sbf-mi-checking"

namespace {

struct SBFMIPreEmitChecking : public MachineFunctionPass {

  static char ID;
  MachineFunction *MF;
  const TargetRegisterInfo *TRI;

  SBFMIPreEmitChecking() : MachineFunctionPass(ID) {
    initializeSBFMIPreEmitCheckingPass(*PassRegistry::getPassRegistry());
  }

private:
  // Initialize class variables.
  void initialize(MachineFunction &MFParm);

public:

  // Main entry point for this pass.
  bool runOnMachineFunction(MachineFunction &MF) override {
    if (!skipFunction(MF.getFunction())) {
      initialize(MF);
      return false;
    }
    return false;
  }
};

// Initialize class variables.
void SBFMIPreEmitChecking::initialize(MachineFunction &MFParm) {
  MF = &MFParm;
  TRI = MF->getSubtarget<SBFSubtarget>().getRegisterInfo();
  LLVM_DEBUG(dbgs() << "*** SBF PreEmit checking pass ***\n\n");
}

} // end default namespace

INITIALIZE_PASS(SBFMIPreEmitChecking, "sbf-mi-pemit-checking",
                "SBF PreEmit Checking", false, false)

char SBFMIPreEmitChecking::ID = 0;
FunctionPass* llvm::createSBFMIPreEmitCheckingPass()
{
  return new SBFMIPreEmitChecking();
}
