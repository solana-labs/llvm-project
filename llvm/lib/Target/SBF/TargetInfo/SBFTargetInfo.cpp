//===-- SBFTargetInfo.cpp - SBF Target Implementation ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "TargetInfo/SBFTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

Target &llvm::getTheSBFXTarget() {
  static Target TheSBFTarget;
  return TheSBFTarget;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeSBFTargetInfo() {
  RegisterTarget<Triple::sbf, /*HasJIT=*/true> XX(
      getTheSBFXTarget(), "sbf", "SBF new (little endian)", "SBF");
}
