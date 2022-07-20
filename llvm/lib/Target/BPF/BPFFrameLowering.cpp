//===-- BPFFrameLowering.cpp - BPF Frame Information ----------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the BPF implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "BPFFrameLowering.h"
#include "BPFInstrInfo.h"
#include "BPFSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"

using namespace llvm;

namespace {

void adjustStackPointer(MachineFunction &MF, MachineBasicBlock &MBB,
                        MachineBasicBlock::iterator &MBBI,
                        unsigned int Opcode) {
  MachineFrameInfo &MFI = MF.getFrameInfo();
  int NumBytes = (int)MFI.getStackSize();
  if (NumBytes) {
    DebugLoc Dl;
    const BPFInstrInfo &TII =
        *static_cast<const BPFInstrInfo *>(MF.getSubtarget().getInstrInfo());
    BuildMI(MBB, MBBI, Dl, TII.get(Opcode), BPF::R11)
        .addReg(BPF::R11)
        .addImm(NumBytes);
  }
}

} // namespace

bool BPFFrameLowering::hasFP(const MachineFunction &MF) const { return true; }

void BPFFrameLowering::emitPrologue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  if (!MF.getSubtarget<BPFSubtarget>().getHasDynamicFrames()) {
    return;
  }
  MachineBasicBlock::iterator MBBI = MBB.begin();
  adjustStackPointer(MF, MBB, MBBI, BPF::SUB_ri);
}

void BPFFrameLowering::emitEpilogue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  if (!MF.getSubtarget<BPFSubtarget>().getHasDynamicFrames()) {
    return;
  }
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  adjustStackPointer(MF, MBB, MBBI, BPF::ADD_ri);
}

void BPFFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                            BitVector &SavedRegs,
                                            RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  SavedRegs.reset(BPF::R6);
  SavedRegs.reset(BPF::R7);
  SavedRegs.reset(BPF::R8);
  SavedRegs.reset(BPF::R9);
}
