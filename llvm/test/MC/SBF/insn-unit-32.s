# RUN: llvm-mc -triple sbf --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump  -d -r %t | FileCheck %s
# RUN: llvm-objdump  --mattr=+alu32 -d -r %t | FileCheck %s

// ======== BPF_ALU Class ========
  add32 w0, w1    // BPF_ADD  | BPF_X
  sub32 w1, w2    // BPF_SUB  | BPF_X
  mul32 w2, w3    // BPF_MUL  | BPF_X
  div32 w3, w4    // BPF_DIV  | BPF_X
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
// CHECK: b4 09 00 00 01 00 00 00      mov32 w9, 0x1
// CHECK: b4 09 00 00 ff ff ff ff      mov32 w9, -0x1
// CHECK: c4 0a 00 00 40 00 00 00      arsh32 w10, 0x40

  jeq w0, w1, Llabel0   // BPF_JEQ  | BPF_X
  jne w3, w4, Llabel0   // BPF_JNE  | BPF_X
// CHECK: 1e 10 0b 00 00 00 00 00 	jeq w0, w1, +0xb
// CHECK: 5e 43 0a 00 00 00 00 00 	jne w3, w4, +0xa

  jgt w1, w2, Llabel0    // BPF_JGT  | BPF_X
  jge w2, w3, Llabel0   // BPF_JGE  | BPF_X
  jsgt w4, w5, Llabel0   // BPF_JSGT | BPF_X
  jsge w5, w6, Llabel0  // BPF_JSGE | BPF_X
// CHECK: 2e 21 09 00 00 00 00 00 	jgt w1, w2, +0x9
// CHECK: 3e 32 08 00 00 00 00 00 	jge w2, w3, +0x8
// CHECK: 6e 54 07 00 00 00 00 00 	jsgt w4, w5, +0x7
// CHECK: 7e 65 06 00 00 00 00 00 	jsge w5, w6, +0x6

  jlt w6, w7, Llabel0    // BPF_JLT  | BPF_X
  jle w7, w8, Llabel0   // BPF_JLE  | BPF_X
  jslt w8, w9, Llabel0   // BPF_JSLT | BPF_X
  jsle w9, w10, Llabel0 // BPF_JSLE | BPF_X
// CHECK: ae 76 05 00 00 00 00 00 	jlt w6, w7, +0x5
// CHECK: be 87 04 00 00 00 00 00 	jle w7, w8, +0x4
// CHECK: ce 98 03 00 00 00 00 00 	jslt w8, w9, +0x3
// CHECK: de a9 02 00 00 00 00 00 	jsle w9, w10, +0x2

  jeq w0, 0, Llabel0           // BPF_JEQ  | BPF_K
  jne w3, -1, Llabel0          // BPF_JNE  | BPF_K
// CHECK: 16 00 01 00 00 00 00 00 	jeq w0, 0x0, +0x1
// CHECK: 56 03 00 00 ff ff ff ff 	jne w3, -0x1, +0x0

Llabel0 :
  jgt w1, 64, Llabel0           // BPF_JGT  | BPF_K
  jge w2, 0xffffffff, Llabel0  // BPF_JGE  | BPF_K
  jsgt w4, 0xffffffff, Llabel0  // BPF_JSGT | BPF_K
  jsge w5, 0x7fffffff, Llabel0 // BPF_JSGE | BPF_K
// CHECK: 26 01 ff ff 40 00 00 00 	jgt w1, 0x40, -0x1
// CHECK: 36 02 fe ff ff ff ff ff 	jge w2, -0x1, -0x2
// CHECK: 66 04 fd ff ff ff ff ff 	jsgt w4, -0x1, -0x3
// CHECK: 76 05 fc ff ff ff ff 7f 	jsge w5, 0x7fffffff, -0x4

  jlt w6, 0xff, Llabel0         // BPF_JLT  | BPF_K
  jle w7, 0xffff, Llabel0      // BPF_JLE  | BPF_K
  jslt w8, 0, Llabel0           // BPF_JSLT | BPF_K
  jsle w9, -1, Llabel0         // BPF_JSLE | BPF_K
// CHECK: a6 06 fb ff ff 00 00 00 	jlt w6, 0xff, -0x5
// CHECK: b6 07 fa ff ff ff 00 00 	jle w7, 0xffff, -0x6
// CHECK: c6 08 f9 ff 00 00 00 00 	jslt w8, 0x0, -0x7
// CHECK: d6 09 f8 ff ff ff ff ff 	jsle w9, -0x1, -0x8
