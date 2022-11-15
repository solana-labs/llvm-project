//===-- SBFMCAsmInfo.h - SBF asm properties -------------------*- C++ -*--====//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the SBFMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SBF_MCTARGETDESC_SBFMCASMINFO_H
#define LLVM_LIB_TARGET_SBF_MCTARGETDESC_SBFMCASMINFO_H

#include "llvm/ADT/Triple.h"
#include "llvm/MC/MCAsmInfo.h"

namespace llvm {

// TODO: This should likely be subclassing MCAsmInfoELF.
class SBFMCAsmInfo : public MCAsmInfo {
public:
  explicit SBFMCAsmInfo(const Triple &TT, const MCTargetOptions &Options);

  void setDwarfUsesRelocationsAcrossSections(bool enable) {
    DwarfUsesRelocationsAcrossSections = enable;
  }

  void setSupportsDebugInformation(bool enable) {
    SupportsDebugInformation = enable;
  }
};

}
#endif
