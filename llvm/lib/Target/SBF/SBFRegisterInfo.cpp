//===-- SBFRegisterInfo.cpp - SBF Register Information ----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the SBF implementation of the TargetRegisterInfo class.
//
//===----------------------------------------------------------------------===//

#include "SBFFunctionInfo.h"
#include "SBFRegisterInfo.h"
#include "SBFSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/Support/ErrorHandling.h"

#define GET_REGINFO_TARGET_DESC
#include "SBFGenRegisterInfo.inc"
using namespace llvm;

unsigned SBFRegisterInfo::FrameLength = 512;

SBFRegisterInfo::SBFRegisterInfo()
    : SBFGenRegisterInfo(SBF::R0) {}

const MCPhysReg *
SBFRegisterInfo::getCalleeSavedRegs(const MachineFunction *MF) const {
  return CSR_SaveList;
}

BitVector SBFRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());
  markSuperRegs(Reserved, SBF::W10); // [W|R]10 is read only frame pointer
  markSuperRegs(Reserved, SBF::W11); // [W|R]11 is pseudo stack pointer
  return Reserved;
}

static void WarnSize(int Offset, MachineFunction &MF, DebugLoc& DL)
{
  static Function *OldMF = nullptr;
  int MaxOffset = -1 * SBFRegisterInfo::FrameLength;
  if (Offset < MaxOffset) {

    if (&(MF.getFunction()) == OldMF) {
      return;
    }
    OldMF = &(MF.getFunction());

    if (MF.getSubtarget<SBFSubtarget>().isSolana()) {
      dbgs() << "Error:";
      if (DL) {
        dbgs() << " ";
        DL.print(dbgs());
      }
      uint64_t StackSize = MF.getFrameInfo().getStackSize();
      dbgs() << " Function " << MF.getFunction().getName()
             << " Stack offset of " << -Offset << " exceeded max offset of "
             << -MaxOffset << " by " << MaxOffset - Offset
             << " bytes, please minimize large stack variables. "
             << "Estimated function frame size: " << StackSize << " bytes.\n\n";
      report_fatal_error("Exceeding the maximum stack offset may cause "
                         "undefined behavior, including the loss of funds.");
    } else {
      DiagnosticInfoUnsupported DiagStackSize(
          MF.getFunction(),
          "SBF stack limit of 512 bytes is exceeded. "
          "Please move large on stack variables into SBF per-cpu array map.\n",
          DL, DiagnosticSeverity::DS_Error);
      MF.getFunction().getContext().diagnose(DiagStackSize);
    }
  }
}

bool SBFRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                          int SPAdj, unsigned FIOperandNum,
                                          RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected");

  unsigned i = 0;
  MachineInstr &MI = *II;
  MachineBasicBlock &MBB = *MI.getParent();
  MachineFunction &MF = *MBB.getParent();
  DebugLoc DL = MI.getDebugLoc();

  if (!DL)
    /* try harder to get some debug loc */
    for (auto &I : MBB)
      if (I.getDebugLoc()) {
        DL = I.getDebugLoc().getFnDebugLoc();
        break;
      }

  while (!MI.getOperand(i).isFI()) {
    ++i;
    assert(i < MI.getNumOperands() && "Instr doesn't have FrameIndex operand!");
  }

  Register FrameReg = getFrameRegister(MF);
  int FrameIndex = MI.getOperand(i).getIndex();
  const TargetInstrInfo &TII = *MF.getSubtarget().getInstrInfo();

  if (MI.getOpcode() == SBF::MOV_rr) {
    int Offset = resolveInternalFrameIndex(MF, FrameIndex, std::nullopt);

    if (!MF.getSubtarget<SBFSubtarget>().getHasDynamicFrames()) {
      WarnSize(Offset, MF, DL);
    }
    MI.getOperand(i).ChangeToRegister(FrameReg, false);
    Register reg = MI.getOperand(i - 1).getReg();
    BuildMI(MBB, ++II, DL, TII.get(SBF::ADD_ri), reg)
        .addReg(reg)
        .addImm(Offset);
    return false;
  }

  int Offset =
      resolveInternalFrameIndex(MF, FrameIndex, MI.getOperand(i + 1).getImm());


  if (!isInt<32>(Offset))
    llvm_unreachable("bug in frame offset");

  if (!MF.getSubtarget<SBFSubtarget>().getHasDynamicFrames()) {
    WarnSize(Offset, MF, DL);
  }

  if (MI.getOpcode() == SBF::FI_ri) {
    // architecture does not really support FI_ri, replace it with
    //    MOV_rr <target_reg>, frame_reg
    //    ADD_ri <target_reg>, imm
    Register reg = MI.getOperand(i - 1).getReg();

    BuildMI(MBB, ++II, DL, TII.get(SBF::MOV_rr), reg)
        .addReg(FrameReg);
    BuildMI(MBB, II, DL, TII.get(SBF::ADD_ri), reg)
        .addReg(reg)
        .addImm(Offset);

    // Remove FI_ri instruction
    MI.eraseFromParent();
  } else {
    MI.getOperand(i).ChangeToRegister(FrameReg, false);
    MI.getOperand(i + 1).ChangeToImmediate(Offset);
  }
  return false;
}

int SBFRegisterInfo::resolveInternalFrameIndex(
    const llvm::MachineFunction &MF, int FI, std::optional<int64_t> Imm) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  const SBFFunctionInfo *SBFFuncInfo = MF.getInfo<SBFFunctionInfo>();
  int Offset = MFI.getObjectOffset(FI);

  if (!MF.getSubtarget<SBFSubtarget>().getHasDynamicFrames() &&
      SBFFuncInfo->containsFrameIndex(FI)) {
    Offset = SBFRegisterInfo::FrameLength - Offset;
    if (static_cast<uint64_t>(Offset) < MFI.getStackSize()) {
      dbgs() << "Error: A function call in method "
             << MF.getFunction().getName()
             << " overwrites values in the frame. Please, decrease stack usage "
             << "or remove parameters from the call.\n\n";
      report_fatal_error(
          "The function call may cause undefined behavior during execution.");
    }
    Offset = -Offset;
  } else if (MF.getSubtarget<SBFSubtarget>().getEnableNewCallConvention() &&
             SBFFuncInfo->containsFrameIndex(FI)) {
    uint64_t StackSize = MFI.getStackSize();
    Offset = -static_cast<int>(StackSize) - Offset;
  } else if (Imm.has_value()) {
    Offset += Imm.value();
  }

  return Offset;
}

Register SBFRegisterInfo::getFrameRegister(const MachineFunction &MF) const {
  return SBF::R10;
}
