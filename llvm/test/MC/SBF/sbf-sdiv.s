# RUN: llvm-mc -triple sbf --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump -d -r %t | FileCheck %s

sdiv32 w1, w2   // BPF_SDIV | BPF_X
// CHECK: ec 21 00 00 00 00 00 00      sdiv32 w1, w2

sdiv32 w3, 6    // BPF_SDIV | BPF_K
// CHECK: e4 03 00 00 06 00 00 00      sdiv32 w3, 0x6


sdiv64 r4, r5   // BPF_SDIV | BPF_X
// CHECK: ef 54 00 00 00 00 00 00 	sdiv64 r4, r5

sdiv64 r5, 6    // BPF_SDIV | BPF_K
// CHECK: e7 05 00 00 06 00 00 00 	sdiv64 r5, 0x6
