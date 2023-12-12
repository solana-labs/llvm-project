# RUN: llvm-mc -triple sbf --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump  --mattr=+alu32 -d -r %t | FileCheck --check-prefix=CHECK-32 %s
# RUN: llvm-objdump  -d -r %t | FileCheck %s

// ======== BPF_LDX Class ========
  ldxb w5, [r0 + 0]   // BPF_LDX | BPF_B
  ldxh w6, [r1 + 8]  // BPF_LDX | BPF_H
  ldxw w7, [r2 + 16] // BPF_LDX | BPF_W
// CHECK-32: 71 05 00 00 00 00 00 00 	ldxb w5, [r0 + 0x0]
// CHECK-32: 69 16 08 00 00 00 00 00 	ldxh w6, [r1 + 0x8]
// CHECK-32: 61 27 10 00 00 00 00 00 	ldxw w7, [r2 + 0x10]
// CHECK: 71 05 00 00 00 00 00 00 	ldxb r5, [r0 + 0x0]
// CHECK: 69 16 08 00 00 00 00 00 	ldxh r6, [r1 + 0x8]
// CHECK: 61 27 10 00 00 00 00 00 	ldxw r7, [r2 + 0x10]

// ======== BPF_STX Class ========
  stxb [r0 + 0], w7    // BPF_STX | BPF_B
  stxh [r1 + 8], w8   // BPF_STX | BPF_H
  stxw [r2 + 16], w9  // BPF_STX | BPF_W
  stxxaddw [r2 + 16], w9  // BPF_STX | BPF_W | BPF_XADD
// CHECK-32: 73 70 00 00 00 00 00 00 	stxb [r0 + 0x0], w7
// CHECK-32: 6b 81 08 00 00 00 00 00 	stxh [r1 + 0x8], w8
// CHECK-32: 63 92 10 00 00 00 00 00 	stxw [r2 + 0x10], w9
// CHECK-32: c3 92 10 00 00 00 00 00 	stxxaddw [r2 + 0x10], w9
// CHECK: 73 70 00 00 00 00 00 00 	stxb [r0 + 0x0], r7
// CHECK: 6b 81 08 00 00 00 00 00 	stxh [r1 + 0x8], r8
// CHECK: 63 92 10 00 00 00 00 00 	stxw [r2 + 0x10], r9
// CHECK: c3 92 10 00 00 00 00 00 	stxxaddw [r2 + 0x10], r9
