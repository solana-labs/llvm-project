# RUN: llvm-mc -triple sbf --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump --output-asm-variant=1 -d -r %t | FileCheck %s

.syntax_old

w1 s/= w2   // BPF_SDIV | BPF_X
// CHECK: ec 21 00 00 00 00 00 00      w1 s/= w2

w3 s/= 6    // BPF_SDIV | BPF_K
// CHECK: e4 03 00 00 06 00 00 00      w3 s/= 6


r4 s/= r5   // BPF_SDIV | BPF_X
// CHECK: ef 54 00 00 00 00 00 00 	r4 s/= r5

r5 s/= 6    // BPF_SDIV | BPF_K
// CHECK: e7 05 00 00 06 00 00 00 	r5 s/= 6
