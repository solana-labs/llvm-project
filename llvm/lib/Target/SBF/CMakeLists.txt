add_llvm_component_group(SBF)

set(LLVM_TARGET_DEFINITIONS SBF.td)

tablegen(LLVM SBFGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM SBFGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM SBFGenAsmWriter1.inc -gen-asm-writer -asmwriternum=1)
tablegen(LLVM SBFGenCallingConv.inc -gen-callingconv)
tablegen(LLVM SBFGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM SBFGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM SBFGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM SBFGenMCCodeEmitter.inc -gen-emitter)
tablegen(LLVM SBFGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM SBFGenSubtargetInfo.inc -gen-subtarget)

add_public_tablegen_target(SBFCommonTableGen)

add_llvm_target(SBFCodeGen
  SBFAbstractMemberAccess.cpp
  SBFAdjustOpt.cpp
  SBFAsmPrinter.cpp
  SBFCheckAndAdjustIR.cpp
  SBFFrameLowering.cpp
  SBFInstrInfo.cpp
  SBFIRPeephole.cpp
  SBFISelDAGToDAG.cpp
  SBFISelLowering.cpp
  SBFMCInstLower.cpp
  SBFPreserveDIType.cpp
  SBFRegisterInfo.cpp
  SBFSelectionDAGInfo.cpp
  SBFSubtarget.cpp
  SBFTargetMachine.cpp
  SBFMIPeephole.cpp
  SBFMIChecking.cpp
  SBFMISimplifyPatchable.cpp
  BTFDebug.cpp

  LINK_COMPONENTS
  Analysis
  AsmPrinter
  CodeGen
  Core
  MC
  SBFDesc
  SBFInfo
  IPO
  Scalar
  SelectionDAG
  Support
  Target
  TransformUtils

  ADD_TO_COMPONENT
  SBF
  )

add_subdirectory(AsmParser)
add_subdirectory(Disassembler)
add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
