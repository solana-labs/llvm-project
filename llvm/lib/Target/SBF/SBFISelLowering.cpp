//===-- SBFISelLowering.cpp - SBF DAG Lowering Implementation  ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the interfaces that SBF uses to lower LLVM code into a
// selection DAG.
//
//===----------------------------------------------------------------------===//

#include "SBFFunctionInfo.h"
#include "SBFRegisterInfo.h"
#include "SBFSubtarget.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/ValueTypes.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/DiagnosticPrinter.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "sbf-lower"

static cl::opt<bool> SBFExpandMemcpyInOrder("sbf-expand-memcpy-in-order",
  cl::Hidden, cl::init(false),
  cl::desc("Expand memcpy into load/store pairs in order"));

static void fail(const SDLoc &DL, SelectionDAG &DAG, const Twine &Msg) {
  MachineFunction &MF = DAG.getMachineFunction();
  DAG.getContext()->diagnose(
      DiagnosticInfoUnsupported(MF.getFunction(), Msg, DL.getDebugLoc()));
}

SBFTargetLowering::SBFTargetLowering(const TargetMachine &TM,
                                     const SBFSubtarget &STI)
    : TargetLowering(TM), Subtarget(&STI) {

  // Set up the register classes.
  addRegisterClass(MVT::i64, &SBF::GPRRegClass);
  if (STI.getHasAlu32())
    addRegisterClass(MVT::i32, &SBF::GPR32RegClass);

  // Compute derived properties from the register classes
  computeRegisterProperties(STI.getRegisterInfo());

  setStackPointerRegisterToSaveRestore(SBF::R10);

//  if (STI.getHasStaticSyscalls())
//    setOperationAction(ISD::TRAP, MVT::Other, Custom);

  setOperationAction(ISD::BR_CC, MVT::i64, Custom);
  setOperationAction(ISD::BR_JT, MVT::Other, Expand);
  setOperationAction(ISD::BRIND, MVT::Other, Expand);
  setOperationAction(ISD::BRCOND, MVT::Other, Expand);

  setOperationAction(ISD::GlobalAddress, MVT::i64, Custom);

  setOperationAction(ISD::DYNAMIC_STACKALLOC, MVT::i64, Custom);
  setOperationAction(ISD::STACKSAVE, MVT::Other, Expand);
  setOperationAction(ISD::STACKRESTORE, MVT::Other, Expand);

  setOperationAction(ISD::INTRINSIC_W_CHAIN, MVT::Other, Custom);

  for (auto VT : {MVT::i8, MVT::i16, MVT::i32, MVT::i64}) {
    // Implement custom lowering for all atomic operations
    setOperationAction(ISD::ATOMIC_SWAP, VT, Custom);
    setOperationAction(ISD::ATOMIC_CMP_SWAP_WITH_SUCCESS, VT, Custom);
    setOperationAction(ISD::ATOMIC_CMP_SWAP, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_ADD, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_AND, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_MAX, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_MIN, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_NAND, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_OR, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_SUB, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_UMAX, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_UMIN, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD_XOR, VT, Custom);
    setOperationAction(ISD::ATOMIC_LOAD, VT, Expand);
    setOperationAction(ISD::ATOMIC_STORE, VT, Expand);
  }


  if (STI.getHasPqrClass() && STI.getHasAlu32()) {
    setOperationAction(ISD::MULHU, MVT::i32, Expand);
    setOperationAction(ISD::MULHS, MVT::i32, Expand);
  }

  for (auto VT : { MVT::i32, MVT::i64 }) {
    if (VT == MVT::i32 && !STI.getHasAlu32())
      continue;

    if (!STI.getHasPqrClass()) {
      setOperationAction(ISD::SDIV, VT, Expand);
      setOperationAction(ISD::SREM, VT, Expand);
      setOperationAction(ISD::MULHU, VT, Expand);
      setOperationAction(ISD::MULHS, VT, Expand);
    }

    setOperationAction(ISD::SDIVREM, VT, Expand);
    setOperationAction(ISD::UDIVREM, VT, Expand);
    setOperationAction(ISD::UMUL_LOHI, VT, Expand);
    setOperationAction(ISD::SMUL_LOHI, VT, Expand);
    setOperationAction(ISD::ROTR, VT, Expand);
    setOperationAction(ISD::ROTL, VT, Expand);
    setOperationAction(ISD::SHL_PARTS, VT, Expand);
    setOperationAction(ISD::SRL_PARTS, VT, Expand);
    setOperationAction(ISD::SRA_PARTS, VT, Expand);
    setOperationAction(ISD::CTPOP, VT, Expand);

    setOperationAction(ISD::SETCC, VT, Expand);
    setOperationAction(ISD::SELECT, VT, Expand);
    setOperationAction(ISD::SELECT_CC, VT, Custom);
  }

  if (STI.getHasPqrClass() && STI.getHasAlu32()) {
    setOperationAction(ISD::MULHU, MVT::i32, Expand);
    setOperationAction(ISD::MULHS, MVT::i32, Expand);
  }

  if (STI.getHasAlu32()) {
    setOperationAction(ISD::BSWAP, MVT::i32, Promote);
    setOperationAction(ISD::BR_CC, MVT::i32, Custom);
    setOperationAction(ISD::CTTZ, MVT::i32, Expand);
    setOperationAction(ISD::CTLZ, MVT::i32, Expand);
    setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i32, Expand);
    setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i32, Expand);
  }

  setOperationAction(ISD::CTTZ, MVT::i64, Expand);
  setOperationAction(ISD::CTLZ, MVT::i64, Expand);
  setOperationAction(ISD::CTTZ_ZERO_UNDEF, MVT::i64, Expand);
  setOperationAction(ISD::CTLZ_ZERO_UNDEF, MVT::i64, Expand);

  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i1, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i8, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i16, Expand);
  setOperationAction(ISD::SIGN_EXTEND_INREG, MVT::i32, Expand);

  // Extended load operations for i1 types must be promoted
  for (MVT VT : MVT::integer_valuetypes()) {
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::ZEXTLOAD, VT, MVT::i1, Promote);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i1, Promote);

    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i8, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i16, Expand);
    setLoadExtAction(ISD::SEXTLOAD, VT, MVT::i32, Expand);
  }

  setBooleanContents(ZeroOrOneBooleanContent);

  // Function alignments
  setMinFunctionAlignment(Align(8));
  setPrefFunctionAlignment(Align(8));

  if (SBFExpandMemcpyInOrder) {
    // LLVM generic code will try to expand memcpy into load/store pairs at this
    // stage which is before quite a few IR optimization passes, therefore the
    // loads and stores could potentially be moved apart from each other which
    // will cause trouble to memcpy pattern matcher inside kernel eBPF JIT
    // compilers.
    //
    // When -sbf-expand-memcpy-in-order specified, we want to defer the expand
    // of memcpy to later stage in IR optimization pipeline so those load/store
    // pairs won't be touched and could be kept in order. Hence, we set
    // MaxStoresPerMem* to zero to disable the generic getMemcpyLoadsAndStores
    // code path, and ask LLVM to use target expander EmitTargetCodeForMemcpy.
    MaxStoresPerMemset = MaxStoresPerMemsetOptSize = 0;
    MaxStoresPerMemcpy = MaxStoresPerMemcpyOptSize = 0;
    MaxStoresPerMemmove = MaxStoresPerMemmoveOptSize = 0;
    MaxLoadsPerMemcmp = 0;
  } else {
    auto SelectionDAGInfo = STI.getSelectionDAGInfo();
    // inline memcpy() for kernel to see explicit copy
    unsigned CommonMaxStores =
      SelectionDAGInfo->getCommonMaxStoresPerMemFunc();

    MaxStoresPerMemset = MaxStoresPerMemsetOptSize = CommonMaxStores;
    MaxStoresPerMemcpy = MaxStoresPerMemcpyOptSize = CommonMaxStores;
    MaxStoresPerMemmove = MaxStoresPerMemmoveOptSize = CommonMaxStores;
    MaxLoadsPerMemcmp = MaxLoadsPerMemcmpOptSize = CommonMaxStores;
  }

  // CPU/Feature control
  HasAlu32 = STI.getHasAlu32();
  HasJmpExt = STI.getHasJmpExt();
  SBFRegisterInfo::FrameLength = 4096;
}

bool SBFTargetLowering::allowsMisalignedMemoryAccesses(
    EVT VT, unsigned, Align, MachineMemOperand::Flags, unsigned *Fast) const {
  if (!VT.isSimple()) {
    return false;
  }

  if (Fast) {
    *Fast = 1;
  }
  return true;
}

bool SBFTargetLowering::isOffsetFoldingLegal(
    const GlobalAddressSDNode *GA) const {
  return false;
}

bool SBFTargetLowering::isTruncateFree(Type *Ty1, Type *Ty2) const {
  if (!Ty1->isIntegerTy() || !Ty2->isIntegerTy())
    return false;
  unsigned NumBits1 = Ty1->getPrimitiveSizeInBits();
  unsigned NumBits2 = Ty2->getPrimitiveSizeInBits();
  return NumBits1 > NumBits2;
}

bool SBFTargetLowering::isTruncateFree(EVT VT1, EVT VT2) const {
  if (!VT1.isInteger() || !VT2.isInteger())
    return false;
  unsigned NumBits1 = VT1.getSizeInBits();
  unsigned NumBits2 = VT2.getSizeInBits();
  return NumBits1 > NumBits2;
}

bool SBFTargetLowering::isZExtFree(Type *Ty1, Type *Ty2) const {
  if (!getHasAlu32() || !Ty1->isIntegerTy() || !Ty2->isIntegerTy())
    return false;
  unsigned NumBits1 = Ty1->getPrimitiveSizeInBits();
  unsigned NumBits2 = Ty2->getPrimitiveSizeInBits();
  return NumBits1 == 32 && NumBits2 == 64;
}

bool SBFTargetLowering::isZExtFree(EVT VT1, EVT VT2) const {
  if (!getHasAlu32() || !VT1.isInteger() || !VT2.isInteger())
    return false;
  unsigned NumBits1 = VT1.getSizeInBits();
  unsigned NumBits2 = VT2.getSizeInBits();
  return NumBits1 == 32 && NumBits2 == 64;
}

SBFTargetLowering::ConstraintType
SBFTargetLowering::getConstraintType(StringRef Constraint) const {
  if (Constraint.size() == 1) {
    switch (Constraint[0]) {
    default:
      break;
    case 'w':
      return C_RegisterClass;
    }
  }

  return TargetLowering::getConstraintType(Constraint);
}

std::pair<unsigned, const TargetRegisterClass *>
SBFTargetLowering::getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI,
                                                StringRef Constraint,
                                                MVT VT) const {
  if (Constraint.size() == 1)
    // GCC Constraint Letters
    switch (Constraint[0]) {
    case 'r': // GENERAL_REGS
      return std::make_pair(0U, &SBF::GPRRegClass);
    case 'w':
      if (HasAlu32)
        return std::make_pair(0U, &SBF::GPR32RegClass);
      break;
    default:
      break;
    }

  return TargetLowering::getRegForInlineAsmConstraint(TRI, Constraint, VT);
}

void SBFTargetLowering::ReplaceNodeResults(SDNode *N,
                                           SmallVectorImpl<SDValue> &Results,
                                           SelectionDAG &DAG) const {
  const char *err_msg;
  uint32_t Opcode = N->getOpcode();
  switch (Opcode) {
  default:
    report_fatal_error("Unhandled custom legalization");
  case ISD::ATOMIC_SWAP:
  case ISD::ATOMIC_CMP_SWAP_WITH_SUCCESS:
  case ISD::ATOMIC_CMP_SWAP:
  case ISD::ATOMIC_LOAD_ADD:
  case ISD::ATOMIC_LOAD_AND:
  case ISD::ATOMIC_LOAD_MAX:
  case ISD::ATOMIC_LOAD_MIN:
  case ISD::ATOMIC_LOAD_NAND:
  case ISD::ATOMIC_LOAD_OR:
  case ISD::ATOMIC_LOAD_SUB:
  case ISD::ATOMIC_LOAD_UMAX:
  case ISD::ATOMIC_LOAD_UMIN:
  case ISD::ATOMIC_LOAD_XOR:
    // We do lowering during legalization, see LowerOperation()
    return;
  }

  SDLoc DL(N);
  fail(DL, DAG, err_msg);
}

SDValue SBFTargetLowering::LowerOperation(SDValue Op, SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  case ISD::BR_CC:
    return LowerBR_CC(Op, DAG);
  case ISD::GlobalAddress:
    return LowerGlobalAddress(Op, DAG);
  case ISD::SELECT_CC:
    return LowerSELECT_CC(Op, DAG);
  case ISD::ATOMIC_SWAP:
  case ISD::ATOMIC_CMP_SWAP_WITH_SUCCESS:
  case ISD::ATOMIC_CMP_SWAP:
  case ISD::ATOMIC_LOAD_ADD:
  case ISD::ATOMIC_LOAD_AND:
  case ISD::ATOMIC_LOAD_MAX:
  case ISD::ATOMIC_LOAD_MIN:
  case ISD::ATOMIC_LOAD_NAND:
  case ISD::ATOMIC_LOAD_OR:
  case ISD::ATOMIC_LOAD_SUB:
  case ISD::ATOMIC_LOAD_UMAX:
  case ISD::ATOMIC_LOAD_UMIN:
  case ISD::ATOMIC_LOAD_XOR:
    return LowerATOMICRMW(Op, DAG);
  case ISD::INTRINSIC_W_CHAIN:
    // continue the expansion as defined with tablegen
    return SDValue();
  case ISD::DYNAMIC_STACKALLOC:
    report_fatal_error("Unsupported dynamic stack allocation");
//  case ISD::TRAP:
//  {
//    SDValue Callee = DAG.getConstant(1, SDLoc(Op), MVT::i64);
//    SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
//    SmallVector<SDValue, 2> Ops;
//    Ops.push_back(Op.getOperand(0));
//    Ops.push_back(Callee);
//    SDValue call = DAG.getNode(SBFISD::CALL, SDLoc(Op), NodeTys, Ops);
//    SDValue val = DAG.getNode(SBFISD::TRAP_RET, SDLoc(Op), MVT::Other, call);
//    return val;
//  }
  default:
    llvm_unreachable("unimplemented operation");
  }
}

// Calling Convention Implementation
#include "SBFGenCallingConv.inc"

SDValue SBFTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  switch (CallConv) {
  default:
    report_fatal_error("Unsupported calling convention");
  case CallingConv::C:
  case CallingConv::Fast:
    break;
  }

  MachineFunction &MF = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  // Assign locations to all of the incoming arguments.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  if (!Subtarget->getHasDynamicFrames() && Ins.size() > MaxArgs) {
    // Pass args 1-4 via registers, remaining args via stack, referenced via
    // SBF::R5
    CCInfo.AnalyzeFormalArguments(Ins,
                                  getHasAlu32() ? CC_SBF32_X : CC_SBF64_X);
  } else {
    // Pass args 1-5 via registers, remaining args via stack, if any.
    CCInfo.AnalyzeFormalArguments(Ins, getHasAlu32() ? CC_SBF32 : CC_SBF64);
  }

  for (auto &VA : ArgLocs) {
    if (VA.isRegLoc()) {
      // Argument passed in registers
      EVT RegVT = VA.getLocVT();
      MVT::SimpleValueType SimpleTy = RegVT.getSimpleVT().SimpleTy;
      switch (SimpleTy) {
      default: {
        errs() << "LowerFormalArguments Unhandled argument type: "
               << RegVT.getEVTString() << '\n';
        llvm_unreachable(nullptr);
      }
      case MVT::i32:
      case MVT::i64:
        Register VReg = RegInfo.createVirtualRegister(
            SimpleTy == MVT::i64 ? &SBF::GPRRegClass : &SBF::GPR32RegClass);
        RegInfo.addLiveIn(VA.getLocReg(), VReg);
        SDValue ArgValue = DAG.getCopyFromReg(Chain, DL, VReg, RegVT);

        // If this is a value that has been promoted to a wider type, insert an
        // assert[sz]ext to capture this, then truncate to the right size.
        if (VA.getLocInfo() == CCValAssign::SExt)
          ArgValue = DAG.getNode(ISD::AssertSext, DL, RegVT, ArgValue,
                                 DAG.getValueType(VA.getValVT()));
        else if (VA.getLocInfo() == CCValAssign::ZExt)
          ArgValue = DAG.getNode(ISD::AssertZext, DL, RegVT, ArgValue,
                                 DAG.getValueType(VA.getValVT()));

        if (VA.getLocInfo() != CCValAssign::Full)
          ArgValue = DAG.getNode(ISD::TRUNCATE, DL, VA.getValVT(), ArgValue);

        InVals.push_back(ArgValue);

        break;
      }
    } else {
      // Argument passed via stack
      assert(VA.isMemLoc() && "Should be isMemLoc");

      EVT PtrVT = DAG.getTargetLoweringInfo().getPointerTy(DAG.getDataLayout());
      EVT LocVT = VA.getLocVT();

      SDValue SDV;
      if (Subtarget->getHasDynamicFrames()) {
        // In the new convention, arguments are in at the end of the callee
        // frame.
        uint64_t Size = PtrVT.getFixedSizeInBits() / 8;
        int64_t Offset = -static_cast<int64_t>(VA.getLocMemOffset() + Size);
        int FrameIndex =
            MF.getFrameInfo().CreateFixedObject(Size, Offset, false);
        SDValue DstAddr = DAG.getFrameIndex(FrameIndex, PtrVT);
        MachinePointerInfo DstInfo =
            MachinePointerInfo::getFixedStack(MF, FrameIndex, Offset);
        SDV = DAG.getLoad(LocVT, DL, Chain, DstAddr, DstInfo);
      } else {
        unsigned Offset = SBFRegisterInfo::FrameLength - VA.getLocMemOffset();

        // Arguments relative to SBF::R5
        unsigned reg = MF.addLiveIn(SBF::R5, &SBF::GPRRegClass);
        SDValue Const = DAG.getConstant(Offset, DL, MVT::i64);
        SDV = DAG.getCopyFromReg(Chain, DL, reg,
                                 getPointerTy(MF.getDataLayout()));
        SDV = DAG.getNode(ISD::SUB, DL, PtrVT, SDV, Const);
        SDV = DAG.getLoad(LocVT, DL, Chain, SDV, MachinePointerInfo());
      }

      InVals.push_back(SDV);
    }
  }

  if (IsVarArg) {
    fail(DL, DAG, "Functions with VarArgs are not supported");
  }

  return Chain;
}

const unsigned SBFTargetLowering::MaxArgs = 5;

SDValue SBFTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                                     SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  auto &Outs = CLI.Outs;
  auto &OutVals = CLI.OutVals;
  auto &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  bool &IsTailCall = CLI.IsTailCall;
  CallingConv::ID CallConv = CLI.CallConv;
  bool IsVarArg = CLI.IsVarArg;
  MachineFunction &MF = DAG.getMachineFunction();

  // SBF target does not support tail call optimization.
  IsTailCall = false;

  switch (CallConv) {
  default:
    report_fatal_error("Unsupported calling convention");
  case CallingConv::Fast:
  case CallingConv::C:
    break;
  }

  // Analyze operands of the call, assigning locations to each operand.
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  if (Outs.size() > MaxArgs) {
    if (Subtarget->getHasDynamicFrames()) {
      // Pass args 1-5 via registers, remaining args via stack
      CCInfo.AnalyzeCallOperands(Outs, getHasAlu32() ? CC_SBF32 : CC_SBF64);
    } else {
      // Pass args 1-4 via registers, remaining args via stack, referenced via
      // SBF::R5
      CCInfo.AnalyzeCallOperands(Outs, getHasAlu32() ? CC_SBF32_X : CC_SBF64_X);
    }
  } else {
    // Pass all args via registers
    CCInfo.AnalyzeCallOperands(Outs, getHasAlu32() ? CC_SBF32 : CC_SBF64);
  }

  unsigned NumBytes = CCInfo.getStackSize();


  auto PtrVT = getPointerTy(MF.getDataLayout());
  Chain = DAG.getCALLSEQ_START(Chain, NumBytes, 0, CLI.DL);

  SmallVector<std::pair<unsigned, SDValue>, MaxArgs> RegsToPass;

  // Walk arg assignments
  bool HasStackArgs = false;
  unsigned e, i, ae = ArgLocs.size();
  for (i = 0, e = ae; i != e; ++i) {
    CCValAssign &VA = ArgLocs[i];
    SDValue Arg = OutVals[i];

    // Promote the value if needed.
    switch (VA.getLocInfo()) {
    default:
      llvm_unreachable("Unknown loc info");
    case CCValAssign::Full:
      break;
    case CCValAssign::SExt:
      Arg = DAG.getNode(ISD::SIGN_EXTEND, CLI.DL, VA.getLocVT(), Arg);
      break;
    case CCValAssign::ZExt:
      Arg = DAG.getNode(ISD::ZERO_EXTEND, CLI.DL, VA.getLocVT(), Arg);
      break;
    case CCValAssign::AExt:
      Arg = DAG.getNode(ISD::ANY_EXTEND, CLI.DL, VA.getLocVT(), Arg);
      break;
    }

    if (VA.isMemLoc()) {
      HasStackArgs = true;
      break;
    }

    // Push arguments into RegsToPass vector
    if (VA.isRegLoc())
      RegsToPass.push_back(std::make_pair(VA.getLocReg(), Arg));
    else
      llvm_unreachable("call arg pass bug");
  }

  SDValue InGlue;

  if (HasStackArgs) {
    SBFFunctionInfo * SBFFuncInfo = MF.getInfo<SBFFunctionInfo>();
    // Stack arguments have to be walked in reverse order by inserting
    // chained stores, this ensures their order is not changed by the scheduler
    // and that the push instruction sequence generated is correct, otherwise they
    // can be freely intermixed.
    for (ae = i, i = ArgLocs.size(); i != ae; --i) {
      unsigned Loc = i - 1;
      CCValAssign &VA = ArgLocs[Loc];
      SDValue Arg = OutVals[Loc];

      assert(VA.isMemLoc());

      EVT PtrVT = DAG.getTargetLoweringInfo().getPointerTy(DAG.getDataLayout());
      SDValue DstAddr;
      MachinePointerInfo DstInfo;
      int FrameIndex;
      int64_t Offset = static_cast<int64_t>(VA.getLocMemOffset());
      uint64_t Size = VA.getLocVT().getFixedSizeInBits() / 8;
      if (Subtarget->getHasDynamicFrames()) {
        // In the new call convention, arguments are stored in the callee frame
        // We must increase the offset, simply because offset zero belongs to
        // the caller.
        Offset += Size;
      }

      FrameIndex = MF.getFrameInfo().CreateFixedObject(
          Size, Offset, false);
      SBFFuncInfo->storeFrameIndexArgument(FrameIndex);
      DstAddr = DAG.getFrameIndex(FrameIndex, PtrVT);
      DstInfo = MachinePointerInfo::getFixedStack(MF, FrameIndex, Offset);
      Chain = DAG.getStore(Chain, CLI.DL, Arg, DstAddr, DstInfo);
    }

    if (!Subtarget->getHasDynamicFrames()) {
      // Pass the current stack frame pointer via SBF::R5, gluing the
      // instruction to instructions passing the first 4 arguments in
      // registers below.
      SDValue FramePtr = DAG.getCopyFromReg(
          Chain, CLI.DL, Subtarget->getRegisterInfo()->getFrameRegister(MF),
          getPointerTy(MF.getDataLayout()));
      Chain = DAG.getCopyToReg(Chain, CLI.DL, SBF::R5, FramePtr, InGlue);
      InGlue = Chain.getValue(1);
    }

  }

  // Build a sequence of copy-to-reg nodes chained together with token chain and
  // flag operands which copy the outgoing args into registers.  The InGlue is
  // necessary since all emitted instructions must be stuck together.
  for (auto &Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, CLI.DL, Reg.first, Reg.second, InGlue);
    InGlue = Chain.getValue(1);
  }

  // If the callee is a GlobalAddress node (quite common, every direct call is)
  // turn it into a TargetGlobalAddress node so that legalize doesn't hack it.
  // Likewise ExternalSymbol -> TargetExternalSymbol.
  if (GlobalAddressSDNode *G = dyn_cast<GlobalAddressSDNode>(Callee)) {
    Callee = DAG.getTargetGlobalAddress(G->getGlobal(), CLI.DL, PtrVT,
                                        G->getOffset(), 0);
  } else if (ExternalSymbolSDNode *E = dyn_cast<ExternalSymbolSDNode>(Callee)) {
    Callee = DAG.getTargetExternalSymbol(E->getSymbol(), PtrVT, 0);
  }

  // Returns a chain & a flag for retval copy to use.
  SDVTList NodeTys = DAG.getVTList(MVT::Other, MVT::Glue);
  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);

  // Add argument registers to the end of the list so that they are
  // known live into the call.
  for (auto &Reg : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg.first, Reg.second.getValueType()));

  if (HasStackArgs && !Subtarget->getHasDynamicFrames()) {
    Ops.push_back(DAG.getRegister(SBF::R5, MVT::i64));
  }

  if (InGlue.getNode())
    Ops.push_back(InGlue);

  Chain = DAG.getNode(SBFISD::CALL, CLI.DL, NodeTys, Ops);
  InGlue = Chain.getValue(1);

  DAG.addNoMergeSiteInfo(Chain.getNode(), CLI.NoMerge);

  // Create the CALLSEQ_END node.
  Chain = DAG.getCALLSEQ_END(Chain, NumBytes, 0, InGlue, CLI.DL);
  InGlue = Chain.getValue(1);

  // Handle result values, copying them out of physregs into vregs that we
  // return.
  return LowerCallResult(Chain, InGlue, CallConv, IsVarArg, Ins, CLI.DL, DAG,
                         InVals);
}

bool SBFTargetLowering::shouldSignExtendTypeInLibCall(EVT Type, bool IsSigned) const {
  return IsSigned || Type == MVT::i32;
}

bool SBFTargetLowering::CanLowerReturn(
    CallingConv::ID CallConv, MachineFunction &MF, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs, LLVMContext &Context) const {
  // At minimal return Outs.size() <= 1, or check valid types in CC.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, Context);
  return CCInfo.CheckReturn(Outs, getHasAlu32() ? RetCC_SBF32 : RetCC_SBF64);
}

SDValue
SBFTargetLowering::LowerReturn(SDValue Chain, CallingConv::ID CallConv,
                               bool IsVarArg,
                               const SmallVectorImpl<ISD::OutputArg> &Outs,
                               const SmallVectorImpl<SDValue> &OutVals,
                               const SDLoc &DL, SelectionDAG &DAG) const {
  unsigned Opc = SBFISD::RET_GLUE;

  // CCValAssign - represent the assignment of the return value to a location
  SmallVector<CCValAssign, 16> RVLocs;
  MachineFunction &MF = DAG.getMachineFunction();

  // CCState - Info about the registers and stack slot.
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, *DAG.getContext());

  if (Outs.size() > 1) {
    fail(DL, DAG, "Only a single return supported");
    assert(false);
  }

  // Analize return values.
  CCInfo.AnalyzeReturn(Outs, getHasAlu32() ? RetCC_SBF32 : RetCC_SBF64);

  SDValue Flag;
  SmallVector<SDValue, 4> RetOps(1, Chain);

  // Copy the result values into the output registers.
  for (unsigned i = 0; i != RVLocs.size(); ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() && "Can only return in registers!");

    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(), OutVals[i], Flag);

    // Guarantee that all emitted copies are stuck together,
    // avoiding something bad.
    Flag = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  RetOps[0] = Chain; // Update chain.

  // Add the flag if we have it.
  if (Flag.getNode())
    RetOps.push_back(Flag);

  return DAG.getNode(Opc, DL, MVT::Other, RetOps);
}

SDValue SBFTargetLowering::LowerCallResult(
    SDValue Chain, SDValue InGlue, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {

  MachineFunction &MF = DAG.getMachineFunction();
  // Assign locations to each value returned by this call.
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, *DAG.getContext());

  if (Ins.size() > 1) {
    fail(DL, DAG, "Only a single return supported");
    assert(false);
  }

  CCInfo.AnalyzeCallResult(Ins, getHasAlu32() ? RetCC_SBF32 : RetCC_SBF64);

  // Copy all of the result registers out of their specified physreg.
  for (auto &Val : RVLocs) {
    Chain = DAG.getCopyFromReg(Chain, DL, Val.getLocReg(),
                               Val.getValVT(), InGlue).getValue(1);
    InGlue = Chain.getValue(2);
    InVals.push_back(Chain.getValue(0));
  }

  return Chain;
}

static void NegateCC(SDValue &LHS, SDValue &RHS, ISD::CondCode &CC) {
  switch (CC) {
  default:
    break;
  case ISD::SETULT:
  case ISD::SETULE:
  case ISD::SETLT:
  case ISD::SETLE:
    CC = ISD::getSetCCSwappedOperands(CC);
    std::swap(LHS, RHS);
    break;
  }
}

SDValue SBFTargetLowering::LowerBR_CC(SDValue Op, SelectionDAG &DAG) const {
  SDValue Chain = Op.getOperand(0);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(1))->get();
  SDValue LHS = Op.getOperand(2);
  SDValue RHS = Op.getOperand(3);
  SDValue Dest = Op.getOperand(4);
  SDLoc DL(Op);

  if (!getHasJmpExt())
    NegateCC(LHS, RHS, CC);

  bool IsSignedCmp = (CC == ISD::SETGT ||
                      CC == ISD::SETGE ||
                      CC == ISD::SETLT ||
                      CC == ISD::SETLE);
  bool Is32Num = LHS.getValueType() == MVT::i32 ||
                 RHS.getValueType() == MVT::i32;

  if (getHasAlu32() && Is32Num) {
    if (isIntOrFPConstant(RHS) || isIntOrFPConstant(LHS)) {
      // Immediate values are sign extended in SBF, so we sign extend the
      // registers for a correct comparison.
      LHS = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::i64, LHS);
      RHS = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::i64, RHS);
    } else if (IsSignedCmp) {
      // If the comparison is signed, we sign extend registers
      LHS = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::i64, LHS);
      RHS = DAG.getNode(ISD::SIGN_EXTEND, DL, MVT::i64, RHS);
    } else {
      // If the comparison is unsigned, we zero extend registers
      LHS = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i64, LHS);
      RHS = DAG.getNode(ISD::ZERO_EXTEND, DL, MVT::i64, RHS);
    }
  }

  return DAG.getNode(SBFISD::BR_CC, DL, Op.getValueType(), Chain, LHS, RHS,
                     DAG.getConstant(CC, DL, MVT::i64), Dest);
}

SDValue SBFTargetLowering::LowerSELECT_CC(SDValue Op, SelectionDAG &DAG) const {
  SDValue LHS = Op.getOperand(0);
  SDValue RHS = Op.getOperand(1);
  SDValue TrueV = Op.getOperand(2);
  SDValue FalseV = Op.getOperand(3);
  ISD::CondCode CC = cast<CondCodeSDNode>(Op.getOperand(4))->get();
  SDLoc DL(Op);

  if (!getHasJmpExt())
    NegateCC(LHS, RHS, CC);

  SDValue TargetCC = DAG.getConstant(CC, DL, LHS.getValueType());
  SDVTList VTs = DAG.getVTList(Op.getValueType(), MVT::Glue);
  SDValue Ops[] = {LHS, RHS, TargetCC, TrueV, FalseV};

  return DAG.getNode(SBFISD::SELECT_CC, DL, VTs, Ops);
}

SDValue SBFTargetLowering::LowerATOMICRMW(SDValue Op, SelectionDAG &DAG) const {
  SDLoc DL(Op);
  AtomicSDNode *AN = cast<AtomicSDNode>(Op);
  assert(AN && "Expected custom lowering of an atomic load node");

  SDValue Chain = AN->getChain();
  SDValue Ptr = AN->getBasePtr();
  EVT PtrVT = AN->getMemoryVT();
  EVT RetVT = Op.getValueType();

  // Load the current value
  SDValue Load =
      DAG.getExtLoad(ISD::EXTLOAD, DL, RetVT, Chain, Ptr, MachinePointerInfo(),
                     PtrVT, AN->getAlign());
  Chain = Load.getValue(1);

  // Most ops return the current value, except CMP_SWAP_WITH_SUCCESS see below
  SDValue Ret = Load;
  SDValue RetFlag;

  // Val contains the new value we want to set. For CMP_SWAP, Cmp contains the
  // expected current value.
  SDValue Cmp, Val;
  if (AN->isCompareAndSwap()) {
    Cmp = Op.getOperand(2);
    Val = Op.getOperand(3);

    // The Cmp value must match the pointer type
    EVT CmpVT = Cmp->getValueType(0);
    if (CmpVT != RetVT) {
      Cmp = RetVT.bitsGT(CmpVT) ? DAG.getNode(ISD::SIGN_EXTEND, DL, RetVT, Cmp)
                                : DAG.getNode(ISD::TRUNCATE, DL, RetVT, Cmp);
    }
  } else {
    Val = AN->getVal();
  }

  // The new value type must match the pointer type
  EVT ValVT = Val->getValueType(0);
  if (ValVT != RetVT) {
    Val = RetVT.bitsGT(ValVT) ? DAG.getNode(ISD::SIGN_EXTEND, DL, RetVT, Val)
                              : DAG.getNode(ISD::TRUNCATE, DL, RetVT, Val);
    ValVT = Val->getValueType(0);
  }

  SDValue NewVal;
  switch (Op.getOpcode()) {
  case ISD::ATOMIC_SWAP:
    NewVal = Val;
    break;
  case ISD::ATOMIC_CMP_SWAP_WITH_SUCCESS: {
    EVT RetFlagVT = AN->getValueType(1);
    NewVal = DAG.getSelectCC(DL, Load, Cmp, Val, Load, ISD::SETEQ);
    RetFlag = DAG.getSelectCC(
        DL, Load, Cmp, DAG.getBoolConstant(true, DL, RetFlagVT, RetFlagVT),
        DAG.getBoolConstant(false, DL, RetFlagVT, RetFlagVT), ISD::SETEQ);
    break;
  }
  case ISD::ATOMIC_CMP_SWAP:
    NewVal = DAG.getSelectCC(DL, Load, Cmp, Val, Load, ISD::SETEQ);
    break;
  case ISD::ATOMIC_LOAD_ADD:
    NewVal = DAG.getNode(ISD::ADD, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_SUB:
    NewVal = DAG.getNode(ISD::SUB, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_AND:
    NewVal = DAG.getNode(ISD::AND, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_NAND: {
    NewVal =
        DAG.getNOT(DL, DAG.getNode(ISD::AND, DL, ValVT, Load, Val), ValVT);
    break;
  }
  case ISD::ATOMIC_LOAD_OR:
    NewVal = DAG.getNode(ISD::OR, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_XOR:
    NewVal = DAG.getNode(ISD::XOR, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_MIN:
    NewVal = DAG.getNode(ISD::SMIN, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_UMIN:
    NewVal = DAG.getNode(ISD::UMIN, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_MAX:
    NewVal = DAG.getNode(ISD::SMAX, DL, ValVT, Load, Val);
    break;
  case ISD::ATOMIC_LOAD_UMAX:
    NewVal = DAG.getNode(ISD::UMAX, DL, ValVT, Load, Val);
    break;
  default:
    llvm_unreachable("unknown atomicrmw op");
  }

  Chain =
      DAG.getTruncStore(Chain, DL, NewVal, Ptr, MachinePointerInfo(), PtrVT);

  if (RetFlag) {
    // CMP_SWAP_WITH_SUCCESS returns {value, success, chain}
    Ret = DAG.getMergeValues({Ret, RetFlag, Chain}, DL);
  } else {
    // All the other ops return {value, chain}
    Ret = DAG.getMergeValues({Ret, Chain}, DL);
  }

  return Ret;
}

const char *SBFTargetLowering::getTargetNodeName(unsigned Opcode) const {
  switch ((SBFISD::NodeType)Opcode) {
  case SBFISD::FIRST_NUMBER:
    break;
  case SBFISD::RET_GLUE:
    return "SBFISD::RET_GLUE";
  case SBFISD::CALL:
    return "SBFISD::CALL";
  case SBFISD::SELECT_CC:
    return "SBFISD::SELECT_CC";
  case SBFISD::BR_CC:
    return "SBFISD::BR_CC";
  case SBFISD::Wrapper:
    return "SBFISD::Wrapper";
  case SBFISD::MEMCPY:
    return "SBFISD::MEMCPY";
//  case SBFISD::TRAP_RET:
//    return "SBFISD::TRAP_RET";
  }
  return nullptr;
}

SDValue SBFTargetLowering::LowerGlobalAddress(SDValue Op,
                                              SelectionDAG &DAG) const {
  auto N = cast<GlobalAddressSDNode>(Op);
  assert(N->getOffset() == 0 && "Invalid offset for global address");

  SDLoc DL(Op);
  const GlobalValue *GV = N->getGlobal();
  SDValue GA = DAG.getTargetGlobalAddress(GV, DL, MVT::i64);

  return DAG.getNode(SBFISD::Wrapper, DL, MVT::i64, GA);
}

unsigned
SBFTargetLowering::EmitSubregExt(MachineInstr &MI, MachineBasicBlock *BB,
                                 unsigned Reg, bool isSigned) const {
  const TargetInstrInfo &TII = *BB->getParent()->getSubtarget().getInstrInfo();
  const TargetRegisterClass *RC = getRegClassFor(MVT::i64);
  MachineFunction *F = BB->getParent();
  DebugLoc DL = MI.getDebugLoc();

  MachineRegisterInfo &RegInfo = F->getRegInfo();

  if (!isSigned) {
    unsigned MovOp =
        Subtarget->getHasExplicitSignExt()
                         ? SBF::MOV_32_64_no_sext : SBF::MOV_32_64;
    Register PromotedReg0 = RegInfo.createVirtualRegister(RC);
    BuildMI(BB, DL, TII.get(MovOp), PromotedReg0).addReg(Reg);
    return PromotedReg0;
  }
  Register PromotedReg0 = RegInfo.createVirtualRegister(RC);
  BuildMI(BB, DL, TII.get(SBF::MOV_32_64), PromotedReg0).addReg(Reg);
  if (Subtarget->getHasExplicitSignExt())
    return PromotedReg0;

  Register PromotedReg1 = RegInfo.createVirtualRegister(RC);
  Register PromotedReg2 = RegInfo.createVirtualRegister(RC);
  BuildMI(BB, DL, TII.get(SBF::SLL_ri), PromotedReg1)
    .addReg(PromotedReg0).addImm(32);
  BuildMI(BB, DL, TII.get(SBF::SRA_ri), PromotedReg2)
    .addReg(PromotedReg1).addImm(32);

  return PromotedReg2;
}

MachineBasicBlock *
SBFTargetLowering::EmitInstrWithCustomInserterMemcpy(MachineInstr &MI,
                                                     MachineBasicBlock *BB)
                                                     const {
  MachineFunction *MF = MI.getParent()->getParent();
  MachineRegisterInfo &MRI = MF->getRegInfo();
  MachineInstrBuilder MIB(*MF, MI);
  unsigned ScratchReg;

  // This function does custom insertion during lowering SBFISD::MEMCPY which
  // only has two register operands from memcpy semantics, the copy source
  // address and the copy destination address.
  //
  // Because we will expand SBFISD::MEMCPY into load/store pairs, we will need
  // a third scratch register to serve as the destination register of load and
  // source register of store.
  //
  // The scratch register here is with the Define | Dead | EarlyClobber flags.
  // The EarlyClobber flag has the semantic property that the operand it is
  // attached to is clobbered before the rest of the inputs are read. Hence it
  // must be unique among the operands to the instruction. The Define flag is
  // needed to coerce the machine verifier that an Undef value isn't a problem
  // as we anyway is loading memory into it. The Dead flag is needed as the
  // value in scratch isn't supposed to be used by any other instruction.
  ScratchReg = MRI.createVirtualRegister(&SBF::GPRRegClass);
  MIB.addReg(ScratchReg,
             RegState::Define | RegState::Dead | RegState::EarlyClobber);

  return BB;
}

MachineBasicBlock *
SBFTargetLowering::EmitInstrWithCustomInserter(MachineInstr &MI,
                                               MachineBasicBlock *BB) const {
  const TargetInstrInfo &TII = *BB->getParent()->getSubtarget().getInstrInfo();
  DebugLoc DL = MI.getDebugLoc();
  unsigned Opc = MI.getOpcode();
  bool isSelectRROp = (Opc == SBF::Select ||
                       Opc == SBF::Select_64_32 ||
                       Opc == SBF::Select_32 ||
                       Opc == SBF::Select_32_64);

  bool isMemcpyOp = Opc == SBF::MEMCPY;
  bool isAtomicFence = Opc == SBF::ATOMIC_FENCE;

#ifndef NDEBUG
  bool isSelectRIOp = (Opc == SBF::Select_Ri ||
                       Opc == SBF::Select_Ri_64_32 ||
                       Opc == SBF::Select_Ri_32 ||
                       Opc == SBF::Select_Ri_32_64);


  assert((isSelectRROp || isSelectRIOp || isMemcpyOp || isAtomicFence) &&
         "Unexpected instr type to insert");
#endif

  if (isMemcpyOp)
    return EmitInstrWithCustomInserterMemcpy(MI, BB);

  if (isAtomicFence) {
    // this is currently a nop
    MI.eraseFromParent();
    return BB;
  }

  bool is32BitCmp = (Opc == SBF::Select_32 ||
                     Opc == SBF::Select_32_64 ||
                     Opc == SBF::Select_Ri_32 ||
                     Opc == SBF::Select_Ri_32_64);

  // To "insert" a SELECT instruction, we actually have to insert the diamond
  // control-flow pattern.  The incoming instruction knows the destination vreg
  // to set, the condition code register to branch on, the true/false values to
  // select between, and a branch opcode to use.
  const BasicBlock *LLVM_BB = BB->getBasicBlock();
  MachineFunction::iterator I = ++BB->getIterator();

  // ThisMBB:
  // ...
  //  TrueVal = ...
  //  jmp_XX r1, r2 goto Copy1MBB
  //  fallthrough --> Copy0MBB
  MachineBasicBlock *ThisMBB = BB;
  MachineFunction *F = BB->getParent();
  MachineBasicBlock *Copy0MBB = F->CreateMachineBasicBlock(LLVM_BB);
  MachineBasicBlock *Copy1MBB = F->CreateMachineBasicBlock(LLVM_BB);

  F->insert(I, Copy0MBB);
  F->insert(I, Copy1MBB);
  // Update machine-CFG edges by transferring all successors of the current
  // block to the new block which will contain the Phi node for the select.
  Copy1MBB->splice(Copy1MBB->begin(), BB,
                   std::next(MachineBasicBlock::iterator(MI)), BB->end());
  Copy1MBB->transferSuccessorsAndUpdatePHIs(BB);
  // Next, add the true and fallthrough blocks as its successors.
  BB->addSuccessor(Copy0MBB);
  BB->addSuccessor(Copy1MBB);

  // Insert Branch if Flag
  int CC = MI.getOperand(3).getImm();
  int NewCC;
  switch (CC) {
#define SET_NEWCC(X, Y)                                                        \
  case ISD::X:                                                                 \
    NewCC = isSelectRROp ? SBF::Y##_rr : SBF::Y##_ri;                          \
    break
  SET_NEWCC(SETGT, JSGT);
  SET_NEWCC(SETUGT, JUGT);
  SET_NEWCC(SETGE, JSGE);
  SET_NEWCC(SETUGE, JUGE);
  SET_NEWCC(SETEQ, JEQ);
  SET_NEWCC(SETNE, JNE);
  SET_NEWCC(SETLT, JSLT);
  SET_NEWCC(SETULT, JULT);
  SET_NEWCC(SETLE, JSLE);
  SET_NEWCC(SETULE, JULE);
  default:
    report_fatal_error("unimplemented select CondCode " + Twine(CC));
  }

  Register LHS = MI.getOperand(1).getReg();
  bool isSignedCmp = (CC == ISD::SETGT ||
                      CC == ISD::SETGE ||
                      CC == ISD::SETLT ||
                      CC == ISD::SETLE);

  // SBF at the moment only has 64-bit comparison. Any 32-bit comparison needs
  // to be promoted. If we are comparing against an immediate value, we must
  // sign extend the registers. Likewise for signed comparisons. Unsigned
  // comparisons will zero extent registers.
  if (is32BitCmp)
    LHS = EmitSubregExt(MI, BB, LHS, isSignedCmp || !isSelectRROp);

  if (isSelectRROp) {
    Register RHS = MI.getOperand(2).getReg();

    if (is32BitCmp)
      RHS = EmitSubregExt(MI, BB, RHS, isSignedCmp);

    BuildMI(BB, DL, TII.get(NewCC)).addReg(LHS).addReg(RHS).addMBB(Copy1MBB);
  } else {
    int64_t imm32 = MI.getOperand(2).getImm();
    // Check before we build J*_ri instruction.
    assert (isInt<32>(imm32));
    BuildMI(BB, DL, TII.get(NewCC))
        .addReg(LHS).addImm(imm32).addMBB(Copy1MBB);
  }

  // Copy0MBB:
  //  %FalseValue = ...
  //  # fallthrough to Copy1MBB
  BB = Copy0MBB;

  // Update machine-CFG edges
  BB->addSuccessor(Copy1MBB);

  // Copy1MBB:
  //  %Result = phi [ %FalseValue, Copy0MBB ], [ %TrueValue, ThisMBB ]
  // ...
  BB = Copy1MBB;
  BuildMI(*BB, BB->begin(), DL, TII.get(SBF::PHI), MI.getOperand(0).getReg())
      .addReg(MI.getOperand(5).getReg())
      .addMBB(Copy0MBB)
      .addReg(MI.getOperand(4).getReg())
      .addMBB(ThisMBB);

  MI.eraseFromParent(); // The pseudo instruction is gone now.
  return BB;
}

EVT SBFTargetLowering::getSetCCResultType(const DataLayout &, LLVMContext &,
                                          EVT VT) const {
  return getHasAlu32() ? MVT::i32 : MVT::i64;
}

MVT SBFTargetLowering::getScalarShiftAmountTy(const DataLayout &DL,
                                              EVT VT) const {
  return (getHasAlu32() && VT == MVT::i32) ? MVT::i32 : MVT::i64;
}

bool SBFTargetLowering::isLegalAddressingMode(const DataLayout &DL,
                                              const AddrMode &AM, Type *Ty,
                                              unsigned AS,
                                              Instruction *I) const {
  // No global is ever allowed as a base.
  if (AM.BaseGV)
    return false;

  switch (AM.Scale) {
  case 0: // "r+i" or just "i", depending on HasBaseReg.
    break;
  case 1:
    if (!AM.HasBaseReg) // allow "r+i".
      break;
    return false; // disallow "r+r" or "r+r+i".
  default:
    return false;
  }

  return true;
}
