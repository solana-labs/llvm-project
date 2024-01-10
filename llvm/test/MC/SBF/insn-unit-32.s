# RUN: llvm-mc -triple sbf --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump  -d -r %t | FileCheck %s --check-prefixes=CHECK,CHECK-alu64
# RUN: llvm-objdump  --mattr=+alu32 -d -r %t | FileCheck %s --check-prefixes=CHECK,CHECK-alu32

// ======== BPF_ALU Class ========
  neg32 w1    // BPF_NEG
  add32 w0, w1    // BPF_ADD  | BPF_X
  sub32 w1, w2    // BPF_SUB  | BPF_X
  mul32 w2, w3    // BPF_MUL  | BPF_X
  div32 w3, w4    // BPF_DIV  | BPF_X
// CHECK: 84 01 00 00 00 00 00 00      neg32 w1
// CHECK: 0c 10 00 00 00 00 00 00      add32 w0, w1
// CHECK: 1c 21 00 00 00 00 00 00      sub32 w1, w2
// CHECK: 2c 32 00 00 00 00 00 00      mul32 w2, w3
// CHECK: 3c 43 00 00 00 00 00 00      div32 w3, w4

  or32 w4, w5     // BPF_OR   | BPF_X
  and32 w5, w6    // BPF_AND  | BPF_X
  lsh32 w6, w7    // BPF_LSH  | BPF_X
  rsh32 w7, w8    // BPF_RSH  | BPF_X
  xor32 w8, w9    // BPF_XOR  | BPF_X
  mov32 w9, w10   // BPF_MOV  | BPF_X
  arsh32 w10, w0  // BPF_ARSH | BPF_X
// CHECK: 4c 54 00 00 00 00 00 00      or32 w4, w5
// CHECK: 5c 65 00 00 00 00 00 00      and32 w5, w6
// CHECK: 6c 76 00 00 00 00 00 00      lsh32 w6, w7
// CHECK: 7c 87 00 00 00 00 00 00      rsh32 w7, w8
// CHECK: ac 98 00 00 00 00 00 00      xor32 w8, w9
// CHECK: bc a9 00 00 00 00 00 00      mov32 w9, w10
// CHECK: cc 0a 00 00 00 00 00 00      arsh32 w10, w0

  add32 w0, 1           // BPF_ADD  | BPF_K
  sub32 w1, 0x1         // BPF_SUB  | BPF_K
  mul32 w2, -4          // BPF_MUL  | BPF_K
  div32 w3, 5           // BPF_DIV  | BPF_K
// CHECK: 04 00 00 00 01 00 00 00      add32 w0, 0x1
// CHECK: 14 01 00 00 01 00 00 00      sub32 w1, 0x1
// CHECK: 24 02 00 00 fc ff ff ff      mul32 w2, -0x4
// CHECK: 34 03 00 00 05 00 00 00      div32 w3, 0x5

  or32 w4, 0xff         // BPF_OR   | BPF_K
  and32 w5, 0xFF        // BPF_AND  | BPF_K
  lsh32 w6, 63          // BPF_LSH  | BPF_K
  rsh32 w7, 32          // BPF_RSH  | BPF_K
  xor32 w8, 0           // BPF_XOR  | BPF_K
  mov32 w9, 1           // BPF_MOV  | BPF_K
  mov32 w9, 0xffffffff  // BPF_MOV  | BPF_K
  arsh32 w10, 64        // BPF_ARSH | BPF_K
// CHECK: 44 04 00 00 ff 00 00 00      or32 w4, 0xff
// CHECK: 54 05 00 00 ff 00 00 00      and32 w5, 0xff
// CHECK: 64 06 00 00 3f 00 00 00      lsh32 w6, 0x3f
// CHECK: 74 07 00 00 20 00 00 00      rsh32 w7, 0x20
// CHECK: a4 08 00 00 00 00 00 00      xor32 w8, 0x0
// CHECK-alu64: b4 09 00 00 01 00 00 00      mov32 r9, 0x1
// CHECK-alu64: b4 09 00 00 ff ff ff ff      mov32 r9, -0x1
// CHECK-alu32: b4 09 00 00 01 00 00 00      mov32 w9, 0x1
// CHECK-alu32: b4 09 00 00 ff ff ff ff      mov32 w9, -0x1
// CHECK: c4 0a 00 00 40 00 00 00      arsh32 w10, 0x40
