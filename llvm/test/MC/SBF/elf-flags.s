# RUN: llvm-mc -triple=sbf-solana-solana -filetype=obj < %s \
# RUN:   | llvm-readobj --file-headers - \
# RUN:   | FileCheck -check-prefix=CHECK-NONE %s
# RUN: llvm-mc -triple=sbf-solana-solana -mcpu=sbfv2 -filetype=obj < %s \
# RUN:   | llvm-readobj --file-headers - \
# RUN:   | FileCheck -check-prefix=CHECK-SBFV2 %s

# CHECK-NONE:       Flags [ (0x0)
# CHECK-NONE-NEXT:  ]

# CHECK-SBFV2:       Flags [ (0x20)
# CHECK-SBFV2-NEXT:    0x20
# CHECK-SBFV2-NEXT:  ]

mov64 r0, r0
