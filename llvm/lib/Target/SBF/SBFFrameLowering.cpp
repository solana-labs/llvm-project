//===-- SBFFrameLowering.cpp - SBF Frame Information ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the SBF implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "SBFFrameLowering.h"
#include "SBFInstrInfo.h"
#include "SBFSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

using namespace llvm;

namespace {

void adjustStackPointer(MachineFunction &MF, MachineBasicBlock &MBB,
                        MachineBasicBlock::iterator &MBBI, bool IsSubtract) {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  int NumBytes = (int)MFI.getStackSize();
  if (NumBytes) {
    DebugLoc Dl;
    const SBFInstrInfo &TII =
        *static_cast<const SBFInstrInfo *>(MF.getSubtarget().getInstrInfo());
    BuildMI(MBB, MBBI, Dl, TII.get(SBF::ADD_ri), SBF::R11)
        .addReg(SBF::R11)
        .addImm(IsSubtract ? -NumBytes : NumBytes);
  }
}

} // namespace

bool SBFFrameLowering::hasFP(const MachineFunction &MF) const { return true; }

void SBFFrameLowering::emitPrologue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  if (!MF.getSubtarget<SBFSubtarget>().getHasDynamicFrames()) {
    return;
  }
  MachineBasicBlock::iterator MBBI = MBB.begin();
  adjustStackPointer(MF, MBB, MBBI, true);
}

void SBFFrameLowering::emitEpilogue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  if (!MF.getSubtarget<SBFSubtarget>().getHasDynamicFrames()) {
    return;
  }
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  adjustStackPointer(MF, MBB, MBBI, false);
}

void SBFFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                            BitVector &SavedRegs,
                                            RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  SavedRegs.reset(SBF::R6);
  SavedRegs.reset(SBF::R7);
  SavedRegs.reset(SBF::R8);
  SavedRegs.reset(SBF::R9);
}
