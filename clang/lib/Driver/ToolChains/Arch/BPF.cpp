//===--- BPF.cpp - Tools Implementations ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "BPF.h"
#include "clang/Driver/Driver.h"
#include "clang/Driver/DriverDiagnostic.h"
#include "clang/Driver/Options.h"
#include "llvm/Option/ArgList.h"

using namespace clang::driver;
using namespace clang::driver::tools;
using namespace clang;
using namespace llvm::opt;

static bool DecodeBPFFeatures(const Driver &D, StringRef text,
                              std::vector<StringRef> &Features) {
  SmallVector<StringRef, 8> Split;
  text.split(Split, StringRef("+"), -1, false);

  for (StringRef Feature : Split) {
    if (Feature == "solana")
      Features.push_back("+solana");
    else
      return false;
  }
  return true;
}

static bool
getBPFArchFeaturesFromMarch(const Driver &D, StringRef March,
                            const ArgList &Args,
                            std::vector<StringRef> &Features) {
  std::string MarchLowerCase = March.lower();
  std::pair<StringRef, StringRef> Split = StringRef(MarchLowerCase).split("+");

  return (Split.first == "bpfel" || Split.first == "bpfeb") &&
    (Split.second.size() == 0 || DecodeBPFFeatures(D, Split.second, Features));
}

void bpf::getBPFTargetFeatures(const Driver &D, const ArgList &Args,
                               std::vector<StringRef> &Features) {
  Arg *A;
  bool success = true;
  if ((A = Args.getLastArg(options::OPT_march_EQ)))
    success = getBPFArchFeaturesFromMarch(D, A->getValue(), Args, Features);
  if (!success)
    D.Diag(diag::err_drv_clang_unsupported) << A->getAsString(Args);
}
