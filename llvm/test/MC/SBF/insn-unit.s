# RUN: llvm-mc -triple sbf --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump  -d -r %t | FileCheck --check-prefixes CHECK,CHECK-64 %s
# RUN: llvm-objdump  --mattr=+alu32 -d -r %t | FileCheck --check-prefixes CHECK,CHECK-32 %s

// ======== BPF_LD Class ========
// Some extra whitespaces are deliberately added to test the parser.


  lddw r9, 0xffffffff    // BPF_LD | BPF_DW | BPF_IMM
  lddw r9, 8589934591    // BPF_LD | BPF_DW | BPF_IMM
  lddw r9, 0x1ffffffff   // BPF_LD | BPF_DW | BPF_IMM
  lddw r9, dummy_map     // BPF_LD | BPF_DW | BPF_IMM
// CHECK: 18 09 00 00 ff ff ff ff 00 00 00 00 00 00 00 00 	lddw r9, 0xffffffff
// CHECK: 18 09 00 00 ff ff ff ff 00 00 00 00 01 00 00 00 	lddw r9, 0x1ffffffff
// CHECK: 18 09 00 00 ff ff ff ff 00 00 00 00 01 00 00 00 	lddw r9, 0x1ffffffff
// CHECK: 18 09 00 00 00 00 00 00 00 00 00 00 00 00 00 00 	lddw r9, 0x0
// CHECK: 0000000000000030:  R_SBF_64_64	dummy_map

// ======== BPF_LDX Class ========
  ldxb r5, [r0 + 0]   // BPF_LDX | BPF_B
  ldxh r6, [r1 + 8]  // BPF_LDX | BPF_H
  ldxw r7, [r2 + 16] // BPF_LDX | BPF_W
  ldxdw r8, [r3 - 30] // BPF_LDX | BPF_DW
// CHECK-64: 71 05 00 00 00 00 00 00 	ldxb r5, [r0 + 0x0]
// CHECK-64: 69 16 08 00 00 00 00 00 	ldxh r6, [r1 + 0x8]
// CHECK-64: 61 27 10 00 00 00 00 00 	ldxw r7, [r2 + 0x10]
// CHECK-32: 71 05 00 00 00 00 00 00 	ldxb w5, [r0 + 0x0]
// CHECK-32: 69 16 08 00 00 00 00 00 	ldxh w6, [r1 + 0x8]
// CHECK-32: 61 27 10 00 00 00 00 00 	ldxw w7, [r2 + 0x10]
// CHECK: 79 38 e2 ff 00 00 00 00 	ldxdw r8, [r3 - 0x1e]

// ======== BPF_STX Class ========
  stxb [r0 + 0], r7    // BPF_STX | BPF_B
  stxh [r1 + 8], r8   // BPF_STX | BPF_H
  stxw [r2 + 16], r9  // BPF_STX | BPF_W
  stxdw [r3 - 30], r10 // BPF_STX | BPF_DW
// CHECK-64: 73 70 00 00 00 00 00 00 	stxb [r0 + 0x0], r7
// CHECK-64: 6b 81 08 00 00 00 00 00 	stxh [r1 + 0x8], r8
// CHECK-64: 63 92 10 00 00 00 00 00 	stxw [r2 + 0x10], r9
// CHECK-32: 73 70 00 00 00 00 00 00 	stxb [r0 + 0x0], w7
// CHECK-32: 6b 81 08 00 00 00 00 00 	stxh [r1 + 0x8], w8
// CHECK-32: 63 92 10 00 00 00 00 00 	stxw [r2 + 0x10], w9
// CHECK: 7b a3 e2 ff 00 00 00 00 	stxdw [r3 - 0x1e], r10

// ======== BPF_JMP Class ========
  ja Llabel0               // BPF_JA
  call 1                     // BPF_CALL
  exit                       // BPF_EXIT
// CHECK: 05 00 1a 00 00 00 00 00 	ja +0x1a
// CHECK: 85 00 00 00 01 00 00 00 	call 0x1
// CHECK: 95 00 00 00 00 00 00 00 	exit

  jeq r0, r1, Llabel0   // BPF_JEQ  | BPF_X
  jne r3, r4, Llabel0   // BPF_JNE  | BPF_X
// CHECK: 1d 10 17 00 00 00 00 00 	jeq r0, r1, +0x17
// CHECK: 5d 43 16 00 00 00 00 00 	jne r3, r4, +0x16

  jgt r1, r2, Llabel0    // BPF_JGT  | BPF_X
  jge r2, r3, Llabel0   // BPF_JGE  | BPF_X
  jsgt r4, r5, Llabel0   // BPF_JSGT | BPF_X
  jsge r5, r6, Llabel0  // BPF_JSGE | BPF_X
// CHECK: 2d 21 15 00 00 00 00 00 	jgt r1, r2, +0x15
// CHECK: 3d 32 14 00 00 00 00 00 	jge r2, r3, +0x14
// CHECK: 6d 54 13 00 00 00 00 00 	jsgt r4, r5, +0x13
// CHECK: 7d 65 12 00 00 00 00 00 	jsge r5, r6, +0x12

  jlt r6, r7, Llabel0    // BPF_JLT  | BPF_X
  jle r7, r8, Llabel0   // BPF_JLE  | BPF_X
  jslt r8, r9, Llabel0   // BPF_JSLT | BPF_X
  jsle r9, r10, Llabel0 // BPF_JSLE | BPF_X
// CHECK: ad 76 11 00 00 00 00 00 	jlt r6, r7, +0x11
// CHECK: bd 87 10 00 00 00 00 00 	jle r7, r8, +0x10
// CHECK: cd 98 0f 00 00 00 00 00 	jslt r8, r9, +0xf
// CHECK: dd a9 0e 00 00 00 00 00 	jsle r9, r10, +0xe

  jeq r0, 0, Llabel0           // BPF_JEQ  | BPF_K
  jne r3, -1, Llabel0          // BPF_JNE  | BPF_K
// CHECK: 15 00 0d 00 00 00 00 00 	jeq r0, 0x0, +0xd
// CHECK: 55 03 0c 00 ff ff ff ff 	jne r3, -0x1, +0xc

  jgt r1, 64, Llabel0           // BPF_JGT  | BPF_K
  jge r2, 0xffffffff, Llabel0  // BPF_JGE  | BPF_K
  jsgt r4, 0xffffffff, Llabel0  // BPF_JSGT | BPF_K
  jsge r5, 0x7fffffff, Llabel0 // BPF_JSGE | BPF_K
// CHECK: 25 01 0b 00 40 00 00 00 	jgt r1, 0x40, +0xb
// CHECK: 35 02 0a 00 ff ff ff ff 	jge r2, -0x1, +0xa
// CHECK: 65 04 09 00 ff ff ff ff 	jsgt r4, -0x1, +0x9
// CHECK: 75 05 08 00 ff ff ff 7f 	jsge r5, 0x7fffffff, +0x8

  jlt r6, 0xff, Llabel0         // BPF_JLT  | BPF_K
  jle r7, 0xffff, Llabel0      // BPF_JLE  | BPF_K
  jslt r8, 0, Llabel0           // BPF_JSLT | BPF_K
  jsle r9, -1, Llabel0         // BPF_JSLE | BPF_K
// CHECK: a5 06 07 00 ff 00 00 00 	jlt r6, 0xff, +0x7
// CHECK: b5 07 06 00 ff ff 00 00 	jle r7, 0xffff, +0x6
// CHECK: c5 08 05 00 00 00 00 00 	jslt r8, 0x0, +0x5
// CHECK: d5 09 04 00 ff ff ff ff 	jsle r9, -0x1, +0x4

// ======== BPF_ALU64 Class ========
  add64 r0, r1    // BPF_ADD  | BPF_X
  sub64 r1, r2    // BPF_SUB  | BPF_X
  mul64 r2, r3    // BPF_MUL  | BPF_X
  div64 r3, r4    // BPF_DIV  | BPF_X
// CHECK: 0f 10 00 00 00 00 00 00 	add64 r0, r1
// CHECK: 1f 21 00 00 00 00 00 00 	sub64 r1, r2
// CHECK: 2f 32 00 00 00 00 00 00 	mul64 r2, r3
// CHECK: 3f 43 00 00 00 00 00 00 	div64 r3, r4

Llabel0 :
  neg64 r2    // BPF_NEG
  or64 r4, r5    // BPF_OR   | BPF_X
  and64 r5, r6    // BPF_AND  | BPF_X
  lsh64 r6, r7   // BPF_LSH  | BPF_X
  rsh64 r7, r8   // BPF_RSH  | BPF_X
  xor64 r8, r9    // BPF_XOR  | BPF_X
  mov64 r9, r10    // BPF_MOV  | BPF_X
  arsh64 r10, r0 // BPF_ARSH | BPF_X
// CHECK: <Llabel0>:
// CHECK: 87 02 00 00 00 00 00 00	neg64 r2
// CHECK: 4f 54 00 00 00 00 00 00 	or64 r4, r5
// CHECK: 5f 65 00 00 00 00 00 00 	and64 r5, r6
// CHECK: 6f 76 00 00 00 00 00 00 	lsh64 r6, r7
// CHECK: 7f 87 00 00 00 00 00 00 	rsh64 r7, r8
// CHECK: af 98 00 00 00 00 00 00 	xor64 r8, r9
// CHECK: bf a9 00 00 00 00 00 00 	mov64 r9, r10
// CHECK: cf 0a 00 00 00 00 00 00 	arsh64 r10, r0

  be16 r1  // BPF_END  | BPF_TO_BE
  be32 r2  // BPF_END  | BPF_TO_BE
  be64 r3  // BPF_END  | BPF_TO_BE
// CHECK: dc 01 00 00 10 00 00 00 	be16 r1
// CHECK: dc 02 00 00 20 00 00 00 	be32 r2
// CHECK: dc 03 00 00 40 00 00 00 	be64 r3

  add64 r0, 1           // BPF_ADD  | BPF_K
  sub64 r1, 0x1         // BPF_SUB  | BPF_K
  mul64 r2, -4          // BPF_MUL  | BPF_K
  div64 r3, 5           // BPF_DIV  | BPF_K
// CHECK: 07 00 00 00 01 00 00 00 	add64 r0, 0x1
// CHECK: 17 01 00 00 01 00 00 00 	sub64 r1, 0x1
// CHECK: 27 02 00 00 fc ff ff ff 	mul64 r2, -0x4
// CHECK: 37 03 00 00 05 00 00 00 	div64 r3, 0x5

  or64 r4, 0xff        // BPF_OR   | BPF_K
  and64 r5, 0xFF        // BPF_AND  | BPF_K
  lsh64 r6, 63         // BPF_LSH  | BPF_K
  rsh64 r7, 32         // BPF_RSH  | BPF_K
  xor64 r8, 0           // BPF_XOR  | BPF_K
  mov64 r9, 1            // BPF_MOV  | BPF_K
  mov64 r9, 0xffffffff   // BPF_MOV  | BPF_K
  arsh64 r10, 64       // BPF_ARSH | BPF_K
  hor64 r3, 0xcafe      // SBF_HOR
// CHECK: 47 04 00 00 ff 00 00 00 	or64 r4, 0xff
// CHECK: 57 05 00 00 ff 00 00 00 	and64 r5, 0xff
// CHECK: 67 06 00 00 3f 00 00 00 	lsh64 r6, 0x3f
// CHECK: 77 07 00 00 20 00 00 00 	rsh64 r7, 0x20
// CHECK: a7 08 00 00 00 00 00 00 	xor64 r8, 0x0
// CHECK: b7 09 00 00 01 00 00 00 	mov64 r9, 0x1
// CHECK: b7 09 00 00 ff ff ff ff 	mov64 r9, -0x1
// CHECK: c7 0a 00 00 40 00 00 00 	arsh64 r10, 0x40
// CHECK: f7 03 00 00 fe ca 00 00	hor64 r3, 0xcafe
