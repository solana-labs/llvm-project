#ifndef LLVM_BPF_MACHINE_FUNCTION_INFO_H
#define LLVM_BPF_MACHINE_FUNCTION_INFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

/// Contains BPF-specific information for each MachineFunction.
class BPFMachineFunctionInfo : public MachineFunctionInfo {
  /// FrameIndex for start of varargs area.
  int VarArgsFrameIndex;

public:
  BPFMachineFunctionInfo()
      : VarArgsFrameIndex(0) {}

  explicit BPFMachineFunctionInfo(MachineFunction &MF)
      : VarArgsFrameIndex(0) {}

  int getVarArgsFrameIndex() const { return VarArgsFrameIndex; }
  void setVarArgsFrameIndex(int Idx) { VarArgsFrameIndex = Idx; }
};

} // namespace llvm

#endif // LLVM_BPF_MACHINE_FUNCTION_INFO_H
