//===-------------- SBFMIPeephole.cpp - MI Peephole Cleanups  -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This pass performs peephole optimizations to cleanup ugly code sequences at
// MachineInstruction layer.
//
// Currently, there are two optimizations implemented:
//  - One pre-RA MachineSSA pass to eliminate type promotion sequences, those
//    zero extend 32-bit subregisters to 64-bit registers, if the compiler
//    could prove the subregisters is defined by 32-bit operations in which
//    case the upper half of the underlying 64-bit registers were zeroed
//    implicitly.
//
//  - One post-RA PreEmit pass to do final cleanup on some redundant
//    instructions generated due to bad RA on subregister.
//===----------------------------------------------------------------------===//

#include "SBF.h"
#include "SBFInstrInfo.h"
#include "SBFTargetMachine.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/Debug.h"
#include <set>

using namespace llvm;

#define DEBUG_TYPE "sbf-mi-zext-elim"

STATISTIC(ZExtElemNum, "Number of zero extension shifts eliminated");

namespace {

struct SBFMIPeephole : public MachineFunctionPass {

  static char ID;
  const SBFInstrInfo *TII;
  MachineFunction *MF;
  MachineRegisterInfo *MRI;

  SBFMIPeephole() : MachineFunctionPass(ID) {
    initializeSBFMIPeepholePass(*PassRegistry::getPassRegistry());
  }

private:
  // Initialize class variables.
  void initialize(MachineFunction &MFParm);
  bool eliminateZExt();

  std::set<MachineInstr *> PhiInsns;

public:

  // Main entry point for this pass.
  bool runOnMachineFunction(MachineFunction &MF) override {
    if (skipFunction(MF.getFunction()))
      return false;

    initialize(MF);

    return eliminateZExt();
  }
};

// Initialize class variables.
void SBFMIPeephole::initialize(MachineFunction &MFParm) {
  MF = &MFParm;
  MRI = &MF->getRegInfo();
  TII = MF->getSubtarget<SBFSubtarget>().getInstrInfo();
  LLVM_DEBUG(dbgs() << "*** SBF MachineSSA ZEXT Elim peephole pass ***\n\n");
}

bool SBFMIPeephole::eliminateZExt() {
  MachineInstr* ToErase = nullptr;
  bool Eliminated = false;

  for (MachineBasicBlock &MBB : *MF) {
    for (MachineInstr &MI : MBB) {
      // If the previous instruction was marked for elimination, remove it now.
      if (ToErase) {
        ToErase->eraseFromParent();
        ToErase = nullptr;
      }

      if (MI.getOpcode() != SBF::MOV_32_64_no_sext)
        continue;

      // Eliminate MOV_32_64 if possible.
      //   MOV_32_64 rA, wB
      LLVM_DEBUG(dbgs() << "Candidate MOV_32_64_no_sext instruction:");
      LLVM_DEBUG(MI.dump());

      LLVM_DEBUG(dbgs() << "Removing the MOV_32_64_no_sext instruction\n");

      Register dst = MI.getOperand(0).getReg();
      Register src = MI.getOperand(1).getReg();

      // Build a SUBREG_TO_REG instruction.
      BuildMI(MBB, MI, MI.getDebugLoc(), TII->get(SBF::SUBREG_TO_REG), dst)
        .addImm(0).addReg(src).addImm(SBF::sub_32);

      ToErase = &MI;
      Eliminated = true;
    }
  }

  return Eliminated;
}

} // end default namespace

INITIALIZE_PASS(SBFMIPeephole, DEBUG_TYPE,
                "SBF MachineSSA Peephole Optimization For ZEXT Eliminate",
                false, false)

char SBFMIPeephole::ID = 0;
FunctionPass* llvm::createSBFMIPeepholePass() { return new SBFMIPeephole(); }

STATISTIC(RedundantMovElemNum, "Number of redundant moves eliminated");

namespace {

struct SBFMIPreEmitPeephole : public MachineFunctionPass {

  static char ID;
  MachineFunction *MF;
  const TargetRegisterInfo *TRI;

  SBFMIPreEmitPeephole() : MachineFunctionPass(ID) {
    initializeSBFMIPreEmitPeepholePass(*PassRegistry::getPassRegistry());
  }

private:
  // Initialize class variables.
  void initialize(MachineFunction &MFParm);

  bool eliminateRedundantMov();

public:

  // Main entry point for this pass.
  bool runOnMachineFunction(MachineFunction &MF) override {
    if (skipFunction(MF.getFunction()))
      return false;

    initialize(MF);

    return eliminateRedundantMov();
  }
};

// Initialize class variables.
void SBFMIPreEmitPeephole::initialize(MachineFunction &MFParm) {
  MF = &MFParm;
  TRI = MF->getSubtarget<SBFSubtarget>().getRegisterInfo();
  LLVM_DEBUG(dbgs() << "*** SBF PreEmit peephole pass ***\n\n");
}

bool SBFMIPreEmitPeephole::eliminateRedundantMov() {
  MachineInstr* ToErase = nullptr;
  bool Eliminated = false;

  for (MachineBasicBlock &MBB : *MF) {
    for (MachineInstr &MI : MBB) {
      // If the previous instruction was marked for elimination, remove it now.
      if (ToErase) {
        LLVM_DEBUG(dbgs() << "  Redundant Mov Eliminated:");
        LLVM_DEBUG(ToErase->dump());
        ToErase->eraseFromParent();
        ToErase = nullptr;
      }

      // Eliminate identical move:
      //
      //   MOV rA, rA
      //   MOV wA, wA
      unsigned Opcode = MI.getOpcode();
      if (Opcode == SBF::MOV_rr ||
          Opcode == SBF::MOV_rr_32_no_sext_v2 ||
          Opcode == SBF::MOV_32_64_no_sext) {
        Register dst = MI.getOperand(0).getReg();
        Register src = MI.getOperand(1).getReg();

        if (dst != src)
          continue;

        ToErase = &MI;
        RedundantMovElemNum++;
        Eliminated = true;
      }
    }
  }

  return Eliminated;
}

} // end default namespace

INITIALIZE_PASS(SBFMIPreEmitPeephole, "sbf-mi-pemit-peephole",
                "SBF PreEmit Peephole Optimization", false, false)

char SBFMIPreEmitPeephole::ID = 0;
FunctionPass* llvm::createSBFMIPreEmitPeepholePass()
{
  return new SBFMIPreEmitPeephole();
}

STATISTIC(TruncElemNum, "Number of truncation eliminated");

namespace {

struct SBFMIPeepholeTruncElim : public MachineFunctionPass {

  static char ID;
  const SBFInstrInfo *TII;
  MachineFunction *MF;
  MachineRegisterInfo *MRI;

  SBFMIPeepholeTruncElim() : MachineFunctionPass(ID) {
    initializeSBFMIPeepholeTruncElimPass(*PassRegistry::getPassRegistry());
  }

private:
  // Initialize class variables.
  void initialize(MachineFunction &MFParm);

  bool eliminateTruncSeq();

public:

  // Main entry point for this pass.
  bool runOnMachineFunction(MachineFunction &MF) override {
    if (skipFunction(MF.getFunction()))
      return false;

    initialize(MF);

    return eliminateTruncSeq();
  }
};

static bool TruncSizeCompatible(int TruncSize, unsigned opcode, bool NewEncoding)
{
  if (TruncSize == 1) {
    if (NewEncoding)
      return opcode == SBF::LDB_V2 || opcode == SBF::LDB32_V2;

    return opcode == SBF::LDB_V1 || opcode == SBF::LDB32_V1;
  }

  if (TruncSize == 2) {
    if (NewEncoding)
      return opcode == SBF::LDH_V2 || opcode == SBF::LDH32_V2;

    return opcode == SBF::LDH_V1 || opcode == SBF::LDH32_V1;
  }

  if (TruncSize == 4) {
    if (NewEncoding)
      return opcode == SBF::LDW_V2 || opcode == SBF::LDW32_V2;

    return opcode == SBF::LDW_V1 || opcode == SBF::LDW32_V1;
  }

  return false;
}

// Initialize class variables.
void SBFMIPeepholeTruncElim::initialize(MachineFunction &MFParm) {
  MF = &MFParm;
  MRI = &MF->getRegInfo();
  TII = MF->getSubtarget<SBFSubtarget>().getInstrInfo();
  LLVM_DEBUG(dbgs() << "*** SBF MachineSSA TRUNC Elim peephole pass ***\n\n");
}

// Reg truncating is often the result of 8/16/32bit->64bit or
// 8/16bit->32bit conversion. If the reg value is loaded with
// masked byte width, the AND operation can be removed since
// SBF LOAD already has zero extension.
//
// This also solved a correctness issue.
// In SBF socket-related program, e.g., __sk_buff->{data, data_end}
// are 32-bit registers, but later on, kernel verifier will rewrite
// it with 64-bit value. Therefore, truncating the value after the
// load will result in incorrect code.
bool SBFMIPeepholeTruncElim::eliminateTruncSeq() {
  MachineInstr* ToErase = nullptr;
  bool Eliminated = false;

  bool NewEncoding = MF->getSubtarget<SBFSubtarget>().getNewMemEncoding();
  for (MachineBasicBlock &MBB : *MF) {
    for (MachineInstr &MI : MBB) {
      // The second insn to remove if the eliminate candidate is a pair.
      MachineInstr *MI2 = nullptr;
      Register DstReg, SrcReg;
      MachineInstr *DefMI;
      int TruncSize = -1;

      // If the previous instruction was marked for elimination, remove it now.
      if (ToErase) {
        ToErase->eraseFromParent();
        ToErase = nullptr;
      }

      // AND A, 0xFFFFFFFF will be turned into SLL/SRL pair due to immediate
      // for SBF ANDI is i32, and this case only happens on ALU64.
      if (MI.getOpcode() == SBF::SRL_ri &&
          MI.getOperand(2).getImm() == 32) {
        SrcReg = MI.getOperand(1).getReg();
        if (!MRI->hasOneNonDBGUse(SrcReg))
          continue;

        MI2 = MRI->getVRegDef(SrcReg);
        DstReg = MI.getOperand(0).getReg();

        if (!MI2 ||
            MI2->getOpcode() != SBF::SLL_ri ||
            MI2->getOperand(2).getImm() != 32)
          continue;

        // Update SrcReg.
        SrcReg = MI2->getOperand(1).getReg();
        DefMI = MRI->getVRegDef(SrcReg);
        if (DefMI)
          TruncSize = 4;
      } else if (MI.getOpcode() == SBF::AND_ri ||
                 MI.getOpcode() == SBF::AND_ri_32) {
        SrcReg = MI.getOperand(1).getReg();
        DstReg = MI.getOperand(0).getReg();
        DefMI = MRI->getVRegDef(SrcReg);

        if (!DefMI)
          continue;

        int64_t imm = MI.getOperand(2).getImm();
        if (imm == 0xff)
          TruncSize = 1;
        else if (imm == 0xffff)
          TruncSize = 2;
      }

      if (TruncSize == -1)
        continue;

      // The definition is PHI node, check all inputs.
      if (DefMI->isPHI()) {
        bool CheckFail = false;

        for (unsigned i = 1, e = DefMI->getNumOperands(); i < e; i += 2) {
          MachineOperand &opnd = DefMI->getOperand(i);
          if (!opnd.isReg()) {
            CheckFail = true;
            break;
          }

          MachineInstr *PhiDef = MRI->getVRegDef(opnd.getReg());
          if (!PhiDef || PhiDef->isPHI() ||
              !TruncSizeCompatible(TruncSize,
                                   PhiDef->getOpcode(), NewEncoding)) {
            CheckFail = true;
            break;
          }
        }

        if (CheckFail)
          continue;
      } else if (!TruncSizeCompatible(TruncSize,
                                      DefMI->getOpcode(), NewEncoding)) {
        continue;
      }

      BuildMI(MBB, MI, MI.getDebugLoc(), TII->get(SBF::MOV_rr), DstReg)
              .addReg(SrcReg);

      if (MI2)
        MI2->eraseFromParent();

      // Mark it to ToErase, and erase in the next iteration.
      ToErase = &MI;
      TruncElemNum++;
      Eliminated = true;
    }
  }

  return Eliminated;
}

} // end default namespace

INITIALIZE_PASS(SBFMIPeepholeTruncElim, "sbf-mi-trunc-elim",
                "SBF MachineSSA Peephole Optimization For TRUNC Eliminate",
                false, false)

char SBFMIPeepholeTruncElim::ID = 0;
FunctionPass* llvm::createSBFMIPeepholeTruncElimPass()
{
  return new SBFMIPeepholeTruncElim();
}
