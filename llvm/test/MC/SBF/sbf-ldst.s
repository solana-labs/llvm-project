# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 --show-encoding \
# RUN:     | FileCheck %s --check-prefix=CHECK-ASM-NEW
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj \
# RUN:     | llvm-objdump -d -r - \
# RUN:     | FileCheck --check-prefix=CHECK-OBJ-NEW %s
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj \
# RUN:     | llvm-objdump --output-asm-variant=1 -d -r - \
# RUN:     | FileCheck --check-prefix=CHECK-OBJ-OLD %s
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 --show-encoding \
# RUN:     | FileCheck %s --check-prefix=CHECK32-ASM-NEW
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj \
# RUN:     | llvm-objdump --mattr=+alu32 -d -r - \
# RUN:     | FileCheck --check-prefix=CHECK32-OBJ-NEW %s
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj \
# RUN:     | llvm-objdump --mattr=+alu32 --output-asm-variant=1 -d -r - \
# RUN:     | FileCheck --check-prefix=CHECK32-OBJ-OLD %s


# TODO: Test immediate field ranges and some hex immediates.

# CHECK-OBJ-NEW: lddw r7, 32768
# CHECK-OBJ-NEW: lddw r0, 9151314442816847872
# CHECK-OBJ-NEW: lddw r1, -1
# CHECK-OBJ-NEW: lddw r3, 0
# CHECK-OBJ-NEW: 0000000000000030:  R_SBF_64_64        the_symbol
# CHECK-OBJ-OLD: r7 = 32768 ll
# CHECK-OBJ-OLD: r0 = 9151314442816847872 ll
# CHECK-OBJ-OLD: r1 = -1 ll
# CHECK-OBJ-OLD: r3 = 0 ll
# CHECK-OBJ-OLD: 0000000000000030:  R_SBF_64_64        the_symbol
# CHECK-ASM-NEW: encoding: [0x18,0x07,0x00,0x00,0x00,0x80,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x18,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x7f]
# CHECK-ASM-NEW: encoding: [0x18,0x01,0x00,0x00,0xff,0xff,0xff,0xff,0x00,0x00,0x00,0x00,0xff,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x18'A',0x03'A',A,A,A,A,A,A,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: # fixup A - offset: 0, value: the_symbol, kind: FK_SecRel_8
lddw r7, 32768
lddw r0, 9151314442816847872
lddw r1, -1
lddw r3, the_symbol



# CHECK-OBJ-NEW: ldxb r6, [r1 + 17]
# CHECK-OBJ-NEW: ldxb r1, [r10 - 3]
# CHECK-OBJ-NEW: ldxh r8, [r2 + 32]
# CHECK-OBJ-NEW: ldxw r4, [r3 + 64]
# CHECK-OBJ-NEW: ldxdw r0, [r4 + 128]
# CHECK-OBJ-OLD: r6 = *(u8 *)(r1 + 17)
# CHECK-OBJ-OLD: r1 = *(u8 *)(r10 - 3)
# CHECK-OBJ-OLD: r8 = *(u16 *)(r2 + 32)
# CHECK-OBJ-OLD: r4 = *(u32 *)(r3 + 64)
# CHECK-OBJ-OLD: r0 = *(u64 *)(r4 + 128)
# CHECK-ASM-NEW: encoding: [0x71,0x16,0x11,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x71,0xa1,0xfd,0xff,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x69,0x28,0x20,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x61,0x34,0x40,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x79,0x40,0x80,0x00,0x00,0x00,0x00,0x00]
ldxb r6, [r1 + 17]
ldxb r1, [r10 - 3]
ldxh r8, [r2 + 32]
ldxw r4, [r3 + 64]
ldxdw r0, [r4 + 128]



# CHECK32-OBJ-NEW: ldxb w6, [r1 + 17]
# CHECK32-OBJ-NEW: ldxb w1, [r10 - 3]
# CHECK32-OBJ-NEW: ldxh w8, [r2 + 32]
# CHECK32-OBJ-NEW: ldxw w4, [r3 + 64]
# CHECK32-OBJ-OLD: w6 = *(u8 *)(r1 + 17)
# CHECK32-OBJ-OLD: w1 = *(u8 *)(r10 - 3)
# CHECK32-OBJ-OLD: w8 = *(u16 *)(r2 + 32)
# CHECK32-OBJ-OLD: w4 = *(u32 *)(r3 + 64)
# CHECK32-ASM-NEW: encoding: [0x71,0x16,0x11,0x00,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0x71,0xa1,0xfd,0xff,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0x69,0x28,0x20,0x00,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0x61,0x34,0x40,0x00,0x00,0x00,0x00,0x00]
ldxb w6, [r1 + 17]
ldxb w1, [r10 - 3]
ldxh w8, [r2 + 32]
ldxw w4, [r3 + 64]



# CHECK-OBJ-NEW: stxb [r1 + 17], r6
# CHECK-OBJ-NEW: stxb [r10 - 3], r1
# CHECK-OBJ-NEW: stxh [r2 + 32], r8
# CHECK-OBJ-NEW: stxw [r3 + 64], r4
# CHECK-OBJ-NEW: stxdw [r4 + 128], r0
# CHECK-OBJ-OLD: *(u8 *)(r1 + 17) = r6
# CHECK-OBJ-OLD: *(u8 *)(r10 - 3) = r1
# CHECK-OBJ-OLD: *(u16 *)(r2 + 32) = r8
# CHECK-OBJ-OLD: *(u32 *)(r3 + 64) = r4
# CHECK-OBJ-OLD: *(u64 *)(r4 + 128) = r0
# CHECK-ASM-NEW: encoding: [0x73,0x61,0x11,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x73,0x1a,0xfd,0xff,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x6b,0x82,0x20,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x63,0x43,0x40,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x7b,0x04,0x80,0x00,0x00,0x00,0x00,0x00]
stxb [r1 + 17], r6
stxb [r10 - 3], r1
stxh [r2 + 32], r8
stxw [r3 + 64], r4
stxdw [r4 + 128], r0



# CHECK32-OBJ-NEW: stxb [r1 + 17], w6
# CHECK32-OBJ-NEW: stxb [r10 - 3], w1
# CHECK32-OBJ-NEW: stxh [r2 + 32], w8
# CHECK32-OBJ-NEW: stxw [r3 + 64], w4
# CHECK32-OBJ-OLD: *(u8 *)(r1 + 17) = w6
# CHECK32-OBJ-OLD: *(u8 *)(r10 - 3) = w1
# CHECK32-OBJ-OLD: *(u16 *)(r2 + 32) = w8
# CHECK32-OBJ-OLD: *(u32 *)(r3 + 64) = w4
# CHECK32-ASM-NEW: encoding: [0x73,0x61,0x11,0x00,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0x73,0x1a,0xfd,0xff,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0x6b,0x82,0x20,0x00,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0x63,0x43,0x40,0x00,0x00,0x00,0x00,0x00]
stxb [r1 + 17], w6
stxb [r10 - 3], w1
stxh [r2 + 32], w8
stxw [r3 + 64], w4


# XADDW (NoALU32).
# CHECK-OBJ-NEW: stxxaddw [r8 + 4], r2
# CHECK-OBJ-OLD: lock *(u32 *)(r8 + 4) += r2
# CHECK-ASM-NEW: encoding: [0xc3,0x28,0x04,0x00,0x00,0x00,0x00,0x00]
stxxaddw [r8 + 4], r2



# XADDD, XANDD, XORD, XXORD (NoALU32).
# CHECK-OBJ-NEW: stxxadddw [r8 - 16], r0
# CHECK-OBJ-NEW: stxxanddw [r8 - 32], r1
# CHECK-OBJ-NEW: stxxordw [r8 - 64], r2
# CHECK-OBJ-NEW: stxxxordw [r8 - 128], r3
# CHECK-OBJ-OLD: lock *(u64 *)(r8 - 16) += r0
# CHECK-OBJ-OLD: lock *(u64 *)(r8 - 32) &= r1
# CHECK-OBJ-OLD: lock *(u64 *)(r8 - 64) |= r2
# CHECK-OBJ-OLD: lock *(u64 *)(r8 - 128) ^= r3
# CHECK-ASM-NEW: encoding: [0xdb,0x08,0xf0,0xff,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdb,0x18,0xe0,0xff,0x50,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdb,0x28,0xc0,0xff,0x40,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdb,0x38,0x80,0xff,0xa0,0x00,0x00,0x00]
stxxadddw [r8 - 16], r0
stxxanddw [r8 - 32], r1
stxxordw [r8 - 64], r2
stxxxordw [r8 - 128], r3



# XADDW32, XANDW32, XORW32, XXORW32 (ALU32).
# CHECK32-OBJ-NEW: stxxaddw [r8 - 16], w4
# CHECK32-OBJ-NEW: stxxandw [r8 - 32], w5
# CHECK32-OBJ-NEW: stxxorw [r8 - 64], w6
# CHECK32-OBJ-NEW: stxxxorw [r8 - 128], w7
# CHECK32-OBJ-OLD: lock *(u32 *)(r8 - 16) += w4
# CHECK32-OBJ-OLD: lock *(u32 *)(r8 - 32) &= w5
# CHECK32-OBJ-OLD: lock *(u32 *)(r8 - 64) |= w6
# CHECK32-OBJ-OLD: lock *(u32 *)(r8 - 128) ^= w7
# CHECK32-ASM-NEW: encoding: [0xc3,0x48,0xf0,0xff,0x00,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x58,0xe0,0xff,0x50,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x68,0xc0,0xff,0x40,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x78,0x80,0xff,0xa0,0x00,0x00,0x00]
stxxaddw [r8 - 16], w4
stxxandw [r8 - 32], w5
stxxorw [r8 - 64], w6
stxxxorw [r8 - 128], w7



# XFADDD, XFANDD, XFORD, XFXORD (NoALU32).
# CHECK-OBJ-NEW: stxxfadddw [r8 - 16], r0
# CHECK-OBJ-NEW: stxxfanddw [r8 - 32], r1
# CHECK-OBJ-NEW: stxxfordw [r8 - 64], r2
# CHECK-OBJ-NEW: stxxfxordw [r8 - 128], r3
# CHECK-OBJ-OLD: r0 = atomic_fetch_add((u64 *)(r8 - 16), r0)
# CHECK-OBJ-OLD: r1 = atomic_fetch_and((u64 *)(r8 - 32), r1)
# CHECK-OBJ-OLD: r2 = atomic_fetch_or((u64 *)(r8 - 64), r2)
# CHECK-OBJ-OLD: r3 = atomic_fetch_xor((u64 *)(r8 - 128), r3)
# CHECK-ASM-NEW: encoding: [0xdb,0x08,0xf0,0xff,0x01,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdb,0x18,0xe0,0xff,0x51,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdb,0x28,0xc0,0xff,0x41,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdb,0x38,0x80,0xff,0xa1,0x00,0x00,0x00]
stxxfadddw [r8 - 16], r0
stxxfanddw [r8 - 32], r1
stxxfordw [r8 - 64], r2
stxxfxordw [r8 - 128], r3



# XFADDW32, XFANDW32, XFORW32, XFXORW32 (ALU32).
# CHECK32-OBJ-NEW: stxxfaddw [r8 - 16], w0
# CHECK32-OBJ-NEW: stxxfandw [r8 - 32], w1
# CHECK32-OBJ-NEW: stxxforw [r8 - 64], w2
# CHECK32-OBJ-NEW: stxxfxorw [r8 - 128], w3
# CHECK32-OBJ-OLD: w0 = atomic_fetch_add((u32 *)(r8 - 16), w0)
# CHECK32-OBJ-OLD: w1 = atomic_fetch_and((u32 *)(r8 - 32), w1)
# CHECK32-OBJ-OLD: w2 = atomic_fetch_or((u32 *)(r8 - 64), w2)
# CHECK32-OBJ-OLD: w3 = atomic_fetch_xor((u32 *)(r8 - 128), w3)
# CHECK32-ASM-NEW: encoding: [0xc3,0x08,0xf0,0xff,0x01,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x18,0xe0,0xff,0x51,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x28,0xc0,0xff,0x41,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x38,0x80,0xff,0xa1,0x00,0x00,0x00]
stxxfaddw [r8 - 16], w0
stxxfandw [r8 - 32], w1
stxxforw [r8 - 64], w2
stxxfxorw [r8 - 128], w3



# XCHGD, XCHGW32
# CHECK-OBJ-NEW: stxxchgdw [r8 - 16], r7
# CHECK-OBJ-OLD: r7 = xchg_64(r8 - 16, r7)
# CHECK32-OBJ-NEW: stxxchgw [r8 - 16], w0
# CHECK32-OBJ-OLD: w0 = xchg32_32(r8 - 16, w0)
# CHECK-ASM-NEW: encoding: [0xdb,0x78,0xf0,0xff,0xe1,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x08,0xf0,0xff,0xe1,0x00,0x00,0x00]
stxxchgdw [r8 - 16], r7
stxxchgw [r8 - 16], w0



# CMPXCHGD, CMPXCHGW32
# CHECK-OBJ-NEW: stxcmpxchgdw [r8 - 16], r5
# CHECK-OBJ-OLD: r0 = cmpxchg_64(r8 - 16, r0, r5)
# CHECK32-OBJ-NEW: stxcmpxchgw [r8 - 16], w5
# CHECK32-OBJ-OLD: w0 = cmpxchg32_32(r8 - 16, w0, w5)
# CHECK-ASM-NEW: encoding: [0xdb,0x58,0xf0,0xff,0xf1,0x00,0x00,0x00]
# CHECK32-ASM-NEW: encoding: [0xc3,0x58,0xf0,0xff,0xf1,0x00,0x00,0x00]
stxcmpxchgdw [r8 - 16], r5
stxcmpxchgw [r8 - 16], w5



# Obsolete ldabs/ldind for completeness.
# CHECK-OBJ-NEW: ldabsb 64
# CHECK-OBJ-NEW: ldabsh 128
# CHECK-OBJ-NEW: ldabsw 0
# CHECK-OBJ-NEW: ldindb r5
# CHECK-OBJ-NEW: ldindh r9
# CHECK-OBJ-NEW: ldindw r7
# CHECK-OBJ-OLD: r0 = *(u8 *)skb[64]
# CHECK-OBJ-OLD: r0 = *(u16 *)skb[128]
# CHECK-OBJ-OLD: r0 = *(u32 *)skb[0]
# CHECK-OBJ-OLD: r0 = *(u8 *)skb[r5]
# CHECK-OBJ-OLD: r0 = *(u16 *)skb[r9]
# CHECK-OBJ-OLD: r0 = *(u32 *)skb[r7]
# CHECK-ASM-NEW: encoding: [0x30,0x00,0x00,0x00,0x40,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x28,0x00,0x00,0x00,0x80,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x20,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x50,0x50,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x48,0x90,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x40,0x70,0x00,0x00,0x00,0x00,0x00,0x00]
ldabsb 64
ldabsh 128
ldabsw 0
ldindb r5
ldindh r9
ldindw r7
