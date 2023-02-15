//===- SBFDisassembler.cpp - Disassembler for SBF ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file is part of the SBF Disassembler.
//
//===----------------------------------------------------------------------===//

#include "MCTargetDesc/SBFMCTargetDesc.h"
#include "TargetInfo/SBFTargetInfo.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCDecoderOps.h"
#include "llvm/MC/MCDisassembler/MCDisassembler.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/Support/MathExtras.h"
#include <cstdint>

using namespace llvm;

#define DEBUG_TYPE "sbf-disassembler"

typedef MCDisassembler::DecodeStatus DecodeStatus;

namespace {

/// A disassembler class for SBF.
class SBFDisassembler : public MCDisassembler {
public:
  enum SBF_CLASS {
    SBF_LD = 0x0,
    SBF_LDX = 0x1,
    SBF_ST = 0x2,
    SBF_STX = 0x3,
    SBF_ALU = 0x4,
    SBF_JMP = 0x5,
    SBF_JMP32 = 0x6,
    SBF_ALU64 = 0x7
  };

  enum SBF_SIZE {
    SBF_W = 0x0,
    SBF_H = 0x1,
    SBF_B = 0x2,
    SBF_DW = 0x3
  };

  enum SBF_MODE {
    SBF_IMM = 0x0,
    SBF_ABS = 0x1,
    SBF_IND = 0x2,
    SBF_MEM = 0x3,
    SBF_LEN = 0x4,
    SBF_MSH = 0x5,
    SBF_ATOMIC = 0x6
  };

  SBFDisassembler(const MCSubtargetInfo &STI, MCContext &Ctx)
      : MCDisassembler(STI, Ctx) {}
  ~SBFDisassembler() override = default;

  DecodeStatus getInstruction(MCInst &Instr, uint64_t &Size,
                              ArrayRef<uint8_t> Bytes, uint64_t Address,
                              raw_ostream &CStream) const override;

  uint8_t getInstClass(uint64_t Inst) const { return (Inst >> 56) & 0x7; };
  uint8_t getInstSize(uint64_t Inst) const { return (Inst >> 59) & 0x3; };
  uint8_t getInstMode(uint64_t Inst) const { return (Inst >> 61) & 0x7; };
};

} // end anonymous namespace

static MCDisassembler *createSBFDisassembler(const Target &T,
                                             const MCSubtargetInfo &STI,
                                             MCContext &Ctx) {
  return new SBFDisassembler(STI, Ctx);
}


extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeSBFDisassembler() {
  // Register the disassembler.
  TargetRegistry::RegisterMCDisassembler(getTheSBFXTarget(),
                                         createSBFDisassembler);
}

static const unsigned GPRDecoderTable[] = {
    SBF::R0,  SBF::R1,  SBF::R2,  SBF::R3,  SBF::R4,  SBF::R5,
    SBF::R6,  SBF::R7,  SBF::R8,  SBF::R9,  SBF::R10, SBF::R11};

static DecodeStatus DecodeGPRRegisterClass(MCInst &Inst, unsigned RegNo,
                                           uint64_t /*Address*/,
                                           const MCDisassembler * /*Decoder*/) {
  if (RegNo > 11)
    return MCDisassembler::Fail;

  unsigned Reg = GPRDecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static const unsigned GPR32DecoderTable[] = {
    SBF::W0,  SBF::W1,  SBF::W2,  SBF::W3,  SBF::W4,  SBF::W5,
    SBF::W6,  SBF::W7,  SBF::W8,  SBF::W9,  SBF::W10, SBF::W11};

static DecodeStatus
DecodeGPR32RegisterClass(MCInst &Inst, unsigned RegNo, uint64_t /*Address*/,
                         const MCDisassembler * /*Decoder*/) {
  if (RegNo > 11)
    return MCDisassembler::Fail;

  unsigned Reg = GPR32DecoderTable[RegNo];
  Inst.addOperand(MCOperand::createReg(Reg));
  return MCDisassembler::Success;
}

static DecodeStatus decodeMemoryOpValue(MCInst &Inst, unsigned Insn,
                                        uint64_t Address,
                                        const MCDisassembler *Decoder) {
  unsigned Register = (Insn >> 16) & 0xf;
  if (Register > 11)
    return MCDisassembler::Fail;

  Inst.addOperand(MCOperand::createReg(GPRDecoderTable[Register]));
  unsigned Offset = (Insn & 0xffff);
  Inst.addOperand(MCOperand::createImm(SignExtend32<16>(Offset)));

  return MCDisassembler::Success;
}

#include "SBFGenDisassemblerTables.inc"
static DecodeStatus readInstruction64(ArrayRef<uint8_t> Bytes, uint64_t Address,
                                      uint64_t &Size, uint64_t &Insn,
                                      bool IsLittleEndian) {
  uint64_t Lo, Hi;

  if (Bytes.size() < 8) {
    Size = 0;
    return MCDisassembler::Fail;
  }

  Size = 8;
  if (IsLittleEndian) {
    Hi = (Bytes[0] << 24) | (Bytes[1] << 16) | (Bytes[2] << 0) | (Bytes[3] << 8);
    Lo = (Bytes[4] << 0) | (Bytes[5] << 8) | (Bytes[6] << 16) | (Bytes[7] << 24);
  } else {
    Hi = (Bytes[0] << 24) | ((Bytes[1] & 0x0F) << 20) | ((Bytes[1] & 0xF0) << 12) |
         (Bytes[2] << 8) | (Bytes[3] << 0);
    Lo = (Bytes[4] << 24) | (Bytes[5] << 16) | (Bytes[6] << 8) | (Bytes[7] << 0);
  }
  Insn = Make_64(Hi, Lo);

  return MCDisassembler::Success;
}

DecodeStatus SBFDisassembler::getInstruction(MCInst &Instr, uint64_t &Size,
                                             ArrayRef<uint8_t> Bytes,
                                             uint64_t Address,
                                             raw_ostream &CStream) const {
  bool IsLittleEndian = getContext().getAsmInfo()->isLittleEndian();
  uint64_t Insn, Hi;
  DecodeStatus Result;

  Result = readInstruction64(Bytes, Address, Size, Insn, IsLittleEndian);
  if (Result == MCDisassembler::Fail) return MCDisassembler::Fail;

  uint8_t InstClass = getInstClass(Insn);
  uint8_t InstMode = getInstMode(Insn);
  if ((InstClass == SBF_LDX || InstClass == SBF_STX) &&
      getInstSize(Insn) != SBF_DW &&
      (InstMode == SBF_MEM || InstMode == SBF_ATOMIC) &&
      STI.getFeatureBits()[SBF::ALU32])
    Result = decodeInstruction(DecoderTableSBFALU3264, Instr, Insn, Address,
                               this, STI);
  else
    Result = decodeInstruction(DecoderTableSBF64, Instr, Insn, Address, this,
                               STI);

  if (Result == MCDisassembler::Fail) return MCDisassembler::Fail;

  switch (Instr.getOpcode()) {
  case SBF::LD_imm64:
  case SBF::LD_pseudo: {
    if (Bytes.size() < 16) {
      Size = 0;
      return MCDisassembler::Fail;
    }
    Size = 16;
    if (IsLittleEndian)
      Hi = (Bytes[12] << 0) | (Bytes[13] << 8) | (Bytes[14] << 16) | (Bytes[15] << 24);
    else
      Hi = (Bytes[12] << 24) | (Bytes[13] << 16) | (Bytes[14] << 8) | (Bytes[15] << 0);
    auto& Op = Instr.getOperand(1);
    Op.setImm(Make_64(Hi, Op.getImm()));
    break;
  }
  case SBF::LD_ABS_B:
  case SBF::LD_ABS_H:
  case SBF::LD_ABS_W:
  case SBF::LD_IND_B:
  case SBF::LD_IND_H:
  case SBF::LD_IND_W: {
    auto Op = Instr.getOperand(0);
    Instr.clear();
    Instr.addOperand(MCOperand::createReg(SBF::R6));
    Instr.addOperand(Op);
    break;
  }
  }

  return Result;
}

typedef DecodeStatus (*DecodeFunc)(MCInst &MI, unsigned insn, uint64_t Address,
                                   const MCDisassembler *Decoder);
