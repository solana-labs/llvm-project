add_llvm_component_library(LLVMSBFInfo
  SBFTargetInfo.cpp

  LINK_COMPONENTS
  MC
  Support

  ADD_TO_COMPONENT
  SBF
  )
