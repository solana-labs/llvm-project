//===-- SBFRegisterInfo.td - SBF Register defs -------------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the SBF register file
//===----------------------------------------------------------------------===//

let Namespace = "SBF" in {
  def sub_32 : SubRegIndex<32>;
}

class Wi<bits<16> Enc, string n> : Register<n> {
  let HWEncoding = Enc;
  let Namespace = "SBF";
}

// Registers are identified with 4-bit ID numbers.
// Ri - 64-bit integer registers
class Ri<bits<16> Enc, string n, list<Register> subregs>
  : RegisterWithSubRegs<n, subregs> {
  let HWEncoding = Enc;
  let Namespace = "SBF";
  let SubRegIndices = [sub_32];
}

foreach I = 0-11 in {
  // 32-bit Integer (alias to low part of 64-bit register).
  def W#I  : Wi<I,  "w"#I>,  DwarfRegNum<[I]>;
  // 64-bit Integer registers
  def R#I  : Ri<I,  "r"#I,  [!cast<Wi>("W"#I)]>,  DwarfRegNum<[I]>;
}

// Register classes.
def GPR32 : RegisterClass<"SBF", [i32], 64, (add
  (sequence "W%u", 1, 9),
  W0, // Return value
  W11, // Stack Ptr
  W10  // Frame Ptr
)>;

def GPR : RegisterClass<"SBF", [i64], 64, (add
  (sequence "R%u", 1, 9),
  R0, // Return value
  R11, // Stack Ptr
  R10  // Frame Ptr
)>;
