//=- SBFFunctionInfo.cpp - SBF Machine Function Info ---------=//

//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
///
/// \file
/// This file implements SBF-specific per-machine-function
/// information.
///
//===----------------------------------------------------------------------===//

#include "SBFFunctionInfo.h"

namespace llvm {

void SBFFunctionInfo::storeFrameIndexArgument(int FI) {
  frameIndexes.insert(FI);
}

bool SBFFunctionInfo::containsFrameIndex(int FI) const {
  return frameIndexes.find(FI) != frameIndexes.end();
}

} // namespace llvm