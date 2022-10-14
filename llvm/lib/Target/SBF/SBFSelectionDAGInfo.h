//===-- SBFSelectionDAGInfo.h - SBF SelectionDAG Info -----------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file defines the SBF subclass for SelectionDAGTargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SBF_SBFSELECTIONDAGINFO_H
#define LLVM_LIB_TARGET_SBF_SBFSELECTIONDAGINFO_H

#include "llvm/CodeGen/SelectionDAGTargetInfo.h"

namespace llvm {

class SBFSelectionDAGInfo : public SelectionDAGTargetInfo {
public:
  SBFSelectionDAGInfo() : isSolana(false) {}
  SDValue EmitTargetCodeForMemcpy(SelectionDAG &DAG, const SDLoc &dl,
                                  SDValue Chain, SDValue Dst, SDValue Src,
                                  SDValue Size, Align Alignment,
                                  bool isVolatile, bool AlwaysInline,
                                  MachinePointerInfo DstPtrInfo,
                                  MachinePointerInfo SrcPtrInfo) const override;

  unsigned getCommonMaxStoresPerMemFunc() const {
    return isSolana ? 4 : 128;
  }
  void setSolanaFlag(bool value) const {
    isSolana = value;
  }

private:
  mutable bool isSolana;

};

}

#endif
