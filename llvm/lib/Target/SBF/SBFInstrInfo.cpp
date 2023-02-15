//===-- SBFInstrInfo.cpp - SBF Instruction Information ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the SBF implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "SBFInstrInfo.h"
#include "SBF.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/IR/DebugLoc.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <iterator>

#define GET_INSTRINFO_CTOR_DTOR
#include "SBFGenInstrInfo.inc"

using namespace llvm;

SBFInstrInfo::SBFInstrInfo()
    : SBFGenInstrInfo(SBF::ADJCALLSTACKDOWN, SBF::ADJCALLSTACKUP) {}

void SBFInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                               MachineBasicBlock::iterator I,
                               const DebugLoc &DL, MCRegister DestReg,
                               MCRegister SrcReg, bool KillSrc) const {
  if (SBF::GPRRegClass.contains(DestReg, SrcReg))
    BuildMI(MBB, I, DL, get(SBF::MOV_rr), DestReg)
        .addReg(SrcReg, getKillRegState(KillSrc));
  else if (SBF::GPR32RegClass.contains(DestReg, SrcReg))
    BuildMI(MBB, I, DL, get(SBF::MOV_rr_32), DestReg)
        .addReg(SrcReg, getKillRegState(KillSrc));
  else
    llvm_unreachable("Impossible reg-to-reg copy");
}

void SBFInstrInfo::expandMEMCPY(MachineBasicBlock::iterator MI) const {
  Register DstReg = MI->getOperand(0).getReg();
  Register SrcReg = MI->getOperand(1).getReg();
  uint64_t CopyLen = MI->getOperand(2).getImm();
  uint64_t Alignment = MI->getOperand(3).getImm();
  Register ScratchReg = MI->getOperand(4).getReg();
  MachineBasicBlock *BB = MI->getParent();
  DebugLoc dl = MI->getDebugLoc();
  unsigned LdOpc, StOpc;

  switch (Alignment) {
  case 1:
    LdOpc = SBF::LDB;
    StOpc = SBF::STB;
    break;
  case 2:
    LdOpc = SBF::LDH;
    StOpc = SBF::STH;
    break;
  case 4:
    LdOpc = SBF::LDW;
    StOpc = SBF::STW;
    break;
  case 8:
    LdOpc = SBF::LDD;
    StOpc = SBF::STD;
    break;
  default:
    llvm_unreachable("unsupported memcpy alignment");
  }

  unsigned IterationNum = CopyLen >> Log2_64(Alignment);
  for(unsigned I = 0; I < IterationNum; ++I) {
    BuildMI(*BB, MI, dl, get(LdOpc))
            .addReg(ScratchReg, RegState::Define).addReg(SrcReg)
            .addImm(I * Alignment);
    BuildMI(*BB, MI, dl, get(StOpc))
            .addReg(ScratchReg, RegState::Kill).addReg(DstReg)
            .addImm(I * Alignment);
  }

  unsigned BytesLeft = CopyLen & (Alignment - 1);
  unsigned Offset = IterationNum * Alignment;
  bool Hanging4Byte = BytesLeft & 0x4;
  bool Hanging2Byte = BytesLeft & 0x2;
  bool Hanging1Byte = BytesLeft & 0x1;
  if (Hanging4Byte) {
    BuildMI(*BB, MI, dl, get(SBF::LDW))
            .addReg(ScratchReg, RegState::Define).addReg(SrcReg).addImm(Offset);
    BuildMI(*BB, MI, dl, get(SBF::STW))
            .addReg(ScratchReg, RegState::Kill).addReg(DstReg).addImm(Offset);
    Offset += 4;
  }
  if (Hanging2Byte) {
    BuildMI(*BB, MI, dl, get(SBF::LDH))
            .addReg(ScratchReg, RegState::Define).addReg(SrcReg).addImm(Offset);
    BuildMI(*BB, MI, dl, get(SBF::STH))
            .addReg(ScratchReg, RegState::Kill).addReg(DstReg).addImm(Offset);
    Offset += 2;
  }
  if (Hanging1Byte) {
    BuildMI(*BB, MI, dl, get(SBF::LDB))
            .addReg(ScratchReg, RegState::Define).addReg(SrcReg).addImm(Offset);
    BuildMI(*BB, MI, dl, get(SBF::STB))
            .addReg(ScratchReg, RegState::Kill).addReg(DstReg).addImm(Offset);
  }

  BB->erase(MI);
}

bool SBFInstrInfo::expandPostRAPseudo(MachineInstr &MI) const {
  if (MI.getOpcode() == SBF::MEMCPY) {
    expandMEMCPY(MI);
    return true;
  }

  return false;
}

void SBFInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                       MachineBasicBlock::iterator I,
                                       Register SrcReg, bool IsKill, int FI,
                                       const TargetRegisterClass *RC,
                                       const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  if (RC == &SBF::GPRRegClass)
    BuildMI(MBB, I, DL, get(SBF::STD))
        .addReg(SrcReg, getKillRegState(IsKill))
        .addFrameIndex(FI)
        .addImm(0);
  else if (RC == &SBF::GPR32RegClass)
    BuildMI(MBB, I, DL, get(SBF::STW32))
        .addReg(SrcReg, getKillRegState(IsKill))
        .addFrameIndex(FI)
        .addImm(0);
  else
    llvm_unreachable("Can't store this register to stack slot");
}

void SBFInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                        MachineBasicBlock::iterator I,
                                        Register DestReg, int FI,
                                        const TargetRegisterClass *RC,
                                        const TargetRegisterInfo *TRI) const {
  DebugLoc DL;
  if (I != MBB.end())
    DL = I->getDebugLoc();

  if (RC == &SBF::GPRRegClass)
    BuildMI(MBB, I, DL, get(SBF::LDD), DestReg).addFrameIndex(FI).addImm(0);
  else if (RC == &SBF::GPR32RegClass)
    BuildMI(MBB, I, DL, get(SBF::LDW32), DestReg).addFrameIndex(FI).addImm(0);
  else
    llvm_unreachable("Can't load this register from stack slot");
}

bool SBFInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                 MachineBasicBlock *&TBB,
                                 MachineBasicBlock *&FBB,
                                 SmallVectorImpl<MachineOperand> &Cond,
                                 bool AllowModify) const {
  // Start from the bottom of the block and work up, examining the
  // terminator instructions.
  MachineBasicBlock::iterator I = MBB.end();
  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;

    // Working from the bottom, when we see a non-terminator
    // instruction, we're done.
    if (!isUnpredicatedTerminator(*I))
      break;

    // A terminator that isn't a branch can't easily be handled
    // by this analysis.
    if (!I->isBranch())
      return true;

    // Handle unconditional branches.
    if (I->getOpcode() == SBF::JMP) {
      if (!AllowModify) {
        TBB = I->getOperand(0).getMBB();
        continue;
      }

      // If the block has any instructions after a J, delete them.
      MBB.erase(std::next(I), MBB.end());
      Cond.clear();
      FBB = nullptr;

      // Delete the J if it's equivalent to a fall-through.
      if (MBB.isLayoutSuccessor(I->getOperand(0).getMBB())) {
        TBB = nullptr;
        I->eraseFromParent();
        I = MBB.end();
        continue;
      }

      // TBB is used to indicate the unconditinal destination.
      TBB = I->getOperand(0).getMBB();
      continue;
    }
    // Cannot handle conditional branches
    return true;
  }

  return false;
}

unsigned SBFInstrInfo::insertBranch(MachineBasicBlock &MBB,
                                    MachineBasicBlock *TBB,
                                    MachineBasicBlock *FBB,
                                    ArrayRef<MachineOperand> Cond,
                                    const DebugLoc &DL,
                                    int *BytesAdded) const {
  assert(!BytesAdded && "code size not handled");

  // Shouldn't be a fall through.
  assert(TBB && "insertBranch must not be told to insert a fallthrough");

  if (Cond.empty()) {
    // Unconditional branch
    assert(!FBB && "Unconditional branch with multiple successors!");
    BuildMI(&MBB, DL, get(SBF::JMP)).addMBB(TBB);
    return 1;
  }

  llvm_unreachable("Unexpected conditional branch");
}

unsigned SBFInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                    int *BytesRemoved) const {
  assert(!BytesRemoved && "code size not handled");

  MachineBasicBlock::iterator I = MBB.end();
  unsigned Count = 0;

  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;
    if (I->getOpcode() != SBF::JMP)
      break;
    // Remove the branch.
    I->eraseFromParent();
    I = MBB.end();
    ++Count;
  }

  return Count;
}
