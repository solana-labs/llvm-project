//=- SBFFunctionInfo.h - SBF machine function info -*- C++ -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares SBF-specific per-machine-function information.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_SBFFUNCTIONINFO_H
#define LLVM_SBFFUNCTIONINFO_H

#include "SBFSubtarget.h"
#include <unordered_set>

namespace llvm {

class SBFFunctionInfo final : public MachineFunctionInfo {
  std::unordered_set<int> frameIndexes;

public:
  SBFFunctionInfo(const Function &F, const SBFSubtarget *STI){};

  void storeFrameIndexArgument(int FI);
  bool containsFrameIndex(int FI) const;
};
} // namespace llvm

#endif // LLVM_SBFFUNCTIONINFO_H