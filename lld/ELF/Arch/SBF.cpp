//===- SBF.cpp ------------------------------------------------------------===//
//
//                             The LLVM Linker
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "InputFiles.h"
#include "Symbols.h"
#include "Target.h"
#include "lld/Common/ErrorHandler.h"
#include "llvm/Object/ELF.h"
#include "llvm/Support/Endian.h"
#include <iostream>

using namespace llvm;
using namespace llvm::object;
using namespace llvm::support::endian;
using namespace llvm::ELF;

namespace lld {
namespace elf {

namespace {
class SBF final : public TargetInfo {
public:
  SBF();
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  RelType getDynRel(RelType type) const override;
  int64_t getImplicitAddend(const uint8_t *buf, RelType type) const override;
  void relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const override;
  uint32_t calcEFlags() const override;
};
} // namespace

SBF::SBF() {
  relativeRel = R_SBF_64_RELATIVE;
  symbolicRel = R_SBF_64_64;
  defaultCommonPageSize = 8;
  defaultMaxPageSize = 8;
  defaultImageBase = 0;
}

RelExpr SBF::getRelExpr(RelType type, const Symbol &s,
                        const uint8_t *loc) const {
  switch (type) {
    case R_SBF_64_32:
      return R_PC;
    case R_SBF_64_ABS32:
    case R_SBF_64_NODYLD32:
    case R_SBF_64_ABS64:
    case R_SBF_64_64:
      return R_ABS;
    default:
      error(getErrorLocation(loc) + "unrecognized reloc " + toString(type));
  }
  return R_NONE;
}

RelType SBF::getDynRel(RelType type) const {
  switch (type) {
    case R_SBF_64_ABS64:
        // R_SBF_64_ABS64 is symbolic like R_SBF_64_64, which is set as our
        // symbolicRel in the constructor. Return R_SBF_64_64 here so that if
        // the symbol isn't preemptible, we emit a _RELATIVE relocation instead
        // and skip emitting the symbol.
        //
        // See https://github.com/anza-xyz/llvm-project/blob/6b6aef5dbacef31a3c7b3a54f7f1ba54cafc7077/lld/ELF/Relocations.cpp#L1179
        return R_SBF_64_64;
    default:
        return type;
  }
}

int64_t SBF::getImplicitAddend(const uint8_t *buf, RelType type) const {
  switch (type) {
  case R_SBF_64_ABS32:
    return SignExtend64<32>(read32le(buf));
  default:
    return 0;
  }
}

void SBF::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  switch (rel.type) {
    case R_SBF_64_32: {
      // Relocation of a symbol
      write32le(loc + 4, ((val - 8) / 8) & 0xFFFFFFFF);
      break;
    }
    case R_SBF_64_ABS32:
    case R_SBF_64_NODYLD32: {
      // Relocation used by .BTF.ext and DWARF
      write32le(loc, val & 0xFFFFFFFF);
      break;
    }
    case R_SBF_64_64: {
      // Relocation of a lddw instruction
      // 64 bit address is divided into the imm of this and the following
      // instructions, lower 32 first.
      write32le(loc + 4, val & 0xFFFFFFFF);
      write32le(loc + 8 + 4, val >> 32);
      break;
    }
    case R_SBF_64_ABS64: {
      // The relocation type is used for normal 64-bit data. The
      // actual to-be-relocated data is stored at r_offset and the
      // read/write data bitsize is 64 (8 bytes). The relocation can
      // be resolved with the symbol value plus implicit addend.
      write64le(loc, val);
      break;
    }
    default:
      error(getErrorLocation(loc) + "unrecognized reloc " + toString(rel.type));
  }
}

static uint32_t getEFlags(InputFile *file) {
  if (config->ekind == ELF64BEKind)
    return cast<ObjFile<ELF64BE>>(file)->getObj().getHeader().e_flags;
  return cast<ObjFile<ELF64LE>>(file)->getObj().getHeader().e_flags;
}

uint32_t SBF::calcEFlags() const {
  uint32_t ret = 0;

  // Ensure that all the object files were compiled with the same flags, as
  // different flags indicate different ABIs.
  for (InputFile *f : ctx.objectFiles) {
    uint32_t flags = getEFlags(f);
    if (ret == 0) {
      ret = flags;
    } else if (ret != flags) {
      error("can not link object files with incompatible flags");
    }
  }

  return ret;
}

TargetInfo *getSBFTargetInfo() {
  static SBF target;
  return &target;
}

} // namespace elf
} // namespace lld
