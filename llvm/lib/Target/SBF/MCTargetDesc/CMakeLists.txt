add_llvm_component_library(LLVMSBFDesc
  SBFMCTargetDesc.cpp
  SBFAsmBackend.cpp
  SBFInstPrinter.cpp
  SBFMCCodeEmitter.cpp
  SBFELFObjectWriter.cpp

  LINK_COMPONENTS
  MC
  SBFInfo
  Support

  ADD_TO_COMPONENT
  SBF
  )
