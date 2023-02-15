//===-- SBFMCAsmInfo.cpp - SBF Asm properties -----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the SBFMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "SBFMCAsmInfo.h"
#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

cl::opt<unsigned> SBFAsmWriterVariant(
    "sbf-output-asm-variant", cl::Hidden, cl::init(0),
    cl::desc("Choose output assembly variant (0 = sbf[default], 1 = legacy)"));

SBFMCAsmInfo::SBFMCAsmInfo(const Triple &TT, const MCTargetOptions &Options) {
  AssemblerDialect = SBFAsmWriterVariant;

  PrivateGlobalPrefix = ".L";
  WeakRefDirective = "\t.weak\t";

  UsesELFSectionDirectiveForBSS = true;
  HasSingleParameterDotFile = true;
  HasDotTypeDotSizeDirective = true;

  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::DwarfCFI;
  MinInstAlignment = 8;

  // The default is 4 and it only affects dwarf elf output.
  // If not set correctly, the dwarf data will be
  // messed up in random places by 4 bytes. .debug_line
  // section will be parsable, but with odd offsets and
  // line numbers, etc.
  CodePointerSize = 8;
}
