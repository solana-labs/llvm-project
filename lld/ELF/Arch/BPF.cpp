//===- BPF.cpp ------------------------------------------------------------===//
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

using namespace llvm;
using namespace llvm::object;
using namespace llvm::support::endian;
using namespace llvm::ELF;

namespace lld {
namespace elf {

namespace {
class BPF final : public TargetInfo {
public:
  BPF();
  RelExpr getRelExpr(RelType type, const Symbol &s,
                     const uint8_t *loc) const override;
  RelType getDynRel(RelType type) const override;
  int64_t getImplicitAddend(const uint8_t *buf, RelType type) const override;
  void relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const override;
  uint32_t calcEFlags() const override;
};
} // namespace

BPF::BPF() {
  noneRel = R_BPF_NONE;
  relativeRel = R_BPF_64_RELATIVE;
  symbolicRel = R_BPF_64_64;
}

RelExpr BPF::getRelExpr(RelType type, const Symbol &s,
                        const uint8_t *loc) const {
  switch (type) {
    case R_BPF_64_32:
      return R_PC;
    case R_BPF_64_ABS32:
    case R_BPF_64_NODYLD32:
    case R_BPF_64_ABS64:
    case R_BPF_64_64:
      return R_ABS;
    default:
      error(getErrorLocation(loc) + "unrecognized reloc " + toString(type));
  }
  return R_NONE;
}

RelType BPF::getDynRel(RelType type) const {
  return type;
}

int64_t BPF::getImplicitAddend(const uint8_t *buf, RelType type) const {
  return 0;
}

void BPF::relocate(uint8_t *loc, const Relocation &rel, uint64_t val) const {
  switch (rel.type) {
    case R_BPF_64_32: {
      // Relocation of a symbol
      write32le(loc + 4, ((val - 8) / 8) & 0xFFFFFFFF);
      break;
    }
    case R_BPF_64_ABS32:
    case R_BPF_64_NODYLD32: {
      // Relocation used by .BTF.ext and DWARF
      write32le(loc, val & 0xFFFFFFFF);
      break;
    }
    case R_BPF_64_64: {
      // Relocation of a lddw instruction
      // 64 bit address is divided into the imm of this and the following
      // instructions, lower 32 first.
      write32le(loc + 4, val & 0xFFFFFFFF);
      write32le(loc + 8 + 4, val >> 32);
      break;
    }
    case R_BPF_64_ABS64: {
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

uint32_t BPF::calcEFlags() const {
  uint32_t ret = 0;

  // Ensure that all the object files were compiled with the same flags, as
  // different flags indicate different ABIs.
  for (InputFile *f : objectFiles) {
    uint32_t flags = getEFlags(f);
    if (ret == 0) {
      ret = flags;
    } else if (ret != flags) {
      error("can not link object files with incompatible flags");
    }
  }

  return ret;
}

TargetInfo *getBPFTargetInfo() {
  static BPF target;
  return &target;
}

} // namespace elf
} // namespace lld
