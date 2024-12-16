# RUN: llvm-mc -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj -o %t %s
# RUN: llvm-objdump -d -r %t | FileCheck --check-prefix=CHECK %s

return

// CHECK: 9d 00 00 00 00 00 00 00	return