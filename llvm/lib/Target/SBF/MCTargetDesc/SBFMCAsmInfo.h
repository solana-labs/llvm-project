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

class SBFMCAsmInfo : public MCAsmInfo {
public:
  explicit SBFMCAsmInfo(const Triple &TT, const MCTargetOptions &Options) {
    if (TT.getArch() == Triple::bpfeb)
      IsLittleEndian = false;

    PrivateGlobalPrefix = ".L";
    WeakRefDirective = "\t.weak\t";

    UsesELFSectionDirectiveForBSS = true;
    HasSingleParameterDotFile = true;
    HasDotTypeDotSizeDirective = true;

    SupportsDebugInformation = true;
    ExceptionsType = ExceptionHandling::DwarfCFI;
    MinInstAlignment = 8;

    // the default is 4 and it only affects dwarf elf output
    // so if not set correctly, the dwarf data will be
    // messed up in random places by 4 bytes. .debug_line
    // section will be parsable, but with odd offsets and
    // line numbers, etc.
    CodePointerSize = 8;

    UseIntegratedAssembler = false;
  }

  void setDwarfUsesRelocationsAcrossSections(bool enable) {
    DwarfUsesRelocationsAcrossSections = enable;
  }

  void setSupportsDebugInformation(bool enable) {
    SupportsDebugInformation = enable;
  }
};
}

#endif
