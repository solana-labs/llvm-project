# RUN: llvm-mc %s -filetype=obj -triple=sbf-solana-solana --mcpu=sbfv2 | llvm-readobj -h - \
# RUN:     | FileCheck %s

# CHECK: Format: elf64-sbf
# CHECK: Arch: sbf
# CHECK: AddressSize: 64bit
# CHECK: ElfHeader {
# CHECK:   Ident {
# CHECK:     Magic: (7F 45 4C 46)
# CHECK:     Class: 64-bit (0x2)
# CHECK:     DataEncoding: LittleEndian (0x1)
# CHECK:     FileVersion: 1
# CHECK:     OS/ABI: SystemV (0x0)
# CHECK:     ABIVersion: 0
# CHECK:   }
# CHECK:   Type: Relocatable (0x1)
# CHECK:   Machine: EM_SBF (0x107)
# CHECK:   Version: 1
# CHECK:   Flags [ (0x20)
# CHECK:     0x20
# CHECK:   ]
# CHECK: }
