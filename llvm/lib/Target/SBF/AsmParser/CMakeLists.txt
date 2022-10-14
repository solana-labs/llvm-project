add_llvm_component_library(LLVMSBFAsmParser
  SBFAsmParser.cpp

  LINK_COMPONENTS
  MC
  MCParser
  SBFDesc
  SBFInfo
  Support

  ADD_TO_COMPONENT
  SBF
  )
