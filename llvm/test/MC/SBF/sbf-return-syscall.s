# RUN: llvm-mc -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump -d -r %t | FileCheck --check-prefix=CHECK %s

syscall 9
return

// CHECK:  95 00 00 00 09 00 00 00 syscall 0x9
// CHECK: 9d 00 00 00 00 00 00 00	return