//===---------------- SBFAdjustOpt.cpp - Adjust Optimization --------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Adjust optimization to make the code more kernel verifier friendly.
//
//===----------------------------------------------------------------------===//

#include "SBF.h"
#include "SBFCORE.h"
#include "SBFTargetMachine.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/PatternMatch.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/User.h"
#include "llvm/IR/Value.h"
#include "llvm/Transforms/Utils/BasicBlockUtils.h"

#define DEBUG_TYPE "sbf-adjust-opt"

using namespace llvm;
using namespace llvm::PatternMatch;

static cl::opt<bool> DisableSBFavoidSpeculation(
    "sbf-disable-avoid-speculation", cl::Hidden,
    cl::desc("SBF: Disable Avoiding Speculative Code Motion."),
    cl::init(false));

namespace {

class SBFAdjustOptImpl {
  struct PassThroughInfo {
    Instruction *Input;
    Instruction *UsedInst;
    uint32_t OpIdx;
    PassThroughInfo(Instruction *I, Instruction *U, uint32_t Idx)
        : Input(I), UsedInst(U), OpIdx(Idx) {}
  };

public:
  SBFAdjustOptImpl(Module *M) : M(M) {}

  bool run();

private:
  Module *M;
  SmallVector<PassThroughInfo, 16> PassThroughs;

  void adjustInst(Instruction &I);
  bool avoidSpeculation(Instruction &I);
  bool insertPassThrough();
};

} // End anonymous namespace

bool SBFAdjustOptImpl::run() {
  for (Function &F : *M)
    for (auto &BB : F) {
      for (auto &I : BB)
        adjustInst(I);
    }
  return insertPassThrough();
}

bool SBFAdjustOptImpl::insertPassThrough() {
  for (auto &Info : PassThroughs) {
    auto *CI = SBFCoreSharedInfo::insertPassThrough(
        M, Info.UsedInst->getParent(), Info.Input, Info.UsedInst);
    Info.UsedInst->setOperand(Info.OpIdx, CI);
  }

  return !PassThroughs.empty();
}


// To avoid speculative hoisting certain computations out of
// a basic block.
bool SBFAdjustOptImpl::avoidSpeculation(Instruction &I) {
  if (auto *LdInst = dyn_cast<LoadInst>(&I)) {
    if (auto *GV = dyn_cast<GlobalVariable>(LdInst->getOperand(0))) {
      if (GV->hasAttribute(SBFCoreSharedInfo::AmaAttr) ||
          GV->hasAttribute(SBFCoreSharedInfo::TypeIdAttr))
        return false;
    }
  }

  if (!isa<LoadInst>(&I) && !isa<CallInst>(&I))
    return false;

  // For:
  //   B1:
  //     var = ...
  //     ...
  //     /* icmp may not be in the same block as var = ... */
  //     comp1 = icmp <opcode> var, <const>;
  //     if (comp1) goto B2 else B3;
  //   B2:
  //     ... var ...
  // change to:
  //   B1:
  //     var = ...
  //     ...
  //     /* icmp may not be in the same block as var = ... */
  //     comp1 = icmp <opcode> var, <const>;
  //     if (comp1) goto B2 else B3;
  //   B2:
  //     var = __builtin_bpf_passthrough(seq_num, var);
  //     ... var ...
  bool isCandidate = false;
  SmallVector<PassThroughInfo, 4> Candidates;
  for (User *U : I.users()) {
    Instruction *Inst = dyn_cast<Instruction>(U);
    if (!Inst)
      continue;

    // May cover a little bit more than the
    // above pattern.
    if (auto *Icmp1 = dyn_cast<ICmpInst>(Inst)) {
      Value *Icmp1Op1 = Icmp1->getOperand(1);
      if (!isa<Constant>(Icmp1Op1))
        return false;
      isCandidate = true;
      continue;
    }

    // Ignore the use in the same basic block as the definition.
    if (Inst->getParent() == I.getParent())
      continue;

    // use in a different basic block, If there is a call or
    // load/store insn before this instruction in this basic
    // block. Most likely it cannot be hoisted out. Skip it.
    for (auto &I2 : *Inst->getParent()) {
      if (isa<CallInst>(&I2))
        return false;
      if (isa<LoadInst>(&I2) || isa<StoreInst>(&I2))
        return false;
      if (&I2 == Inst)
        break;
    }

    // It should be used in a GEP or a simple arithmetic like
    // ZEXT/SEXT which is used for GEP.
    if (Inst->getOpcode() == Instruction::ZExt ||
        Inst->getOpcode() == Instruction::SExt) {
      PassThroughInfo Info(&I, Inst, 0);
      Candidates.push_back(Info);
    } else if (auto *GI = dyn_cast<GetElementPtrInst>(Inst)) {
      // traverse GEP inst to find Use operand index
      unsigned i, e;
      for (i = 1, e = GI->getNumOperands(); i != e; ++i) {
        Value *V = GI->getOperand(i);
        if (V == &I)
          break;
      }
      if (i == e)
        continue;

      PassThroughInfo Info(&I, GI, i);
      Candidates.push_back(Info);
    }
  }

  if (!isCandidate || Candidates.empty())
    return false;

  llvm::append_range(PassThroughs, Candidates);
  return true;
}

void SBFAdjustOptImpl::adjustInst(Instruction &I) {
  if (!DisableSBFavoidSpeculation && avoidSpeculation(I))
    return;
}

PreservedAnalyses SBFAdjustOptPass::run(Module &M, ModuleAnalysisManager &AM) {
  return SBFAdjustOptImpl(&M).run() ? PreservedAnalyses::none()
                                    : PreservedAnalyses::all();
}
