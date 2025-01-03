# RUN: llvm-mc -triple=sbf-solana-solana -filetype=obj < %s \
# RUN:   | llvm-readobj --file-headers - \
# RUN:   | FileCheck -check-prefix=CHECK-NONE %s
# RUN: llvm-mc -triple=sbf-solana-solana -mcpu=v1 -filetype=obj < %s \
# RUN:   | llvm-readobj --file-headers - \
# RUN:   | FileCheck -check-prefix=CHECK-SBFV1 %s
# RUN: llvm-mc -triple=sbf-solana-solana -mcpu=v1 -filetype=obj < %s \
# RUN:   | llvm-readobj --file-headers - \
# RUN:   | FileCheck -check-prefix=CHECK-SBFV1 %s
# RUN: llvm-mc -triple=sbf-solana-solana -mcpu=v3 -filetype=obj < %s \
# RUN:   | llvm-readobj --file-headers - \
# RUN:   | FileCheck -check-prefix=CHECK-SBFV3 %s


# CHECK-NONE:       Flags [ (0x0)
# CHECK-NONE-NEXT:  ]

# CHECK-SBFV1:       Flags [ (0x1)
# CHECK-SBFV1-NEXT:    0x1
# CHECK-SBFV1-NEXT:  ]

# CHECK-SBFV2:       Flags [ (0x2)
# CHECK-SBFV2-NEXT:    0x2
# CHECK-SBFV2-NEXT:  ]

# CHECK-SBFV3:       Flags [ (0x3)
# CHECK-SBFV3-NEXT:    0x1
# CHECK-SBFV3-NEXT:    0x2
# CHECK-SBFV3-NEXT:  ]

mov64 r0, r0
