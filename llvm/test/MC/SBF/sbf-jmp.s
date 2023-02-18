# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 --show-encoding \
# RUN:     | FileCheck %s --check-prefix=CHECK-ASM-NEW
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj \
# RUN:     | llvm-objdump -d -r - \
# RUN:     | FileCheck --check-prefix=CHECK-OBJ-NEW %s
# RUN: llvm-mc %s -triple=sbf-solana-solana --mcpu=sbfv2 -filetype=obj \
# RUN:     | llvm-objdump --output-asm-variant=1 -d -r - \
# RUN:     | FileCheck --check-prefix=CHECK-OBJ-OLD %s



# TODO: Test immediate field ranges, etc.

mylabelback:
# CHECK-OBJ-NEW: ja +8
# CHECK-OBJ-NEW: ja -2 <mylabelback>
# CHECK-OBJ-NEW: ja +0 <mylabelfwd>
# CHECK-OBJ-OLD: goto +8
# CHECK-OBJ-OLD: goto -2
# CHECK-OBJ-OLD: goto +0
# CHECK-ASM-NEW: encoding: [0x05,0x00,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x05'A',A,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: # fixup A - offset: 0, value: mylabelback, kind: FK_PCRel_2
# CHECK-ASM-NEW: encoding: [0x05'A',A,0x00,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: # fixup A - offset: 0, value: mylabelfwd, kind: FK_PCRel_2
ja +8
ja mylabelback
ja mylabelfwd

mylabelfwd:

# CHECK-OBJ-NEW: jeq r0, r9, +1
# CHECK-OBJ-NEW: jne r0, r9, +1
# CHECK-OBJ-NEW: jgt r0, r9, +1
# CHECK-OBJ-NEW: jge r0, r9, +1
# CHECK-OBJ-NEW: jlt r0, r9, +1
# CHECK-OBJ-NEW: jle r0, r9, +1
# CHECK-OBJ-NEW: jsgt r0, r9, +1
# CHECK-OBJ-NEW: jsge r0, r9, +1
# CHECK-OBJ-NEW: jslt r0, r9, +1
# CHECK-OBJ-NEW: jsle r0, r9, +1
# CHECK-OBJ-OLD: if r0 == r9 goto +1
# CHECK-OBJ-OLD: if r0 != r9 goto +1
# CHECK-OBJ-OLD: if r0 > r9 goto +1
# CHECK-OBJ-OLD: if r0 >= r9 goto +1
# CHECK-OBJ-OLD: if r0 < r9 goto +1
# CHECK-OBJ-OLD: if r0 <= r9 goto +1
# CHECK-OBJ-OLD: if r0 s> r9 goto +1
# CHECK-OBJ-OLD: if r0 s>= r9 goto +1
# CHECK-OBJ-OLD: if r0 s< r9 goto +1
# CHECK-OBJ-OLD: if r0 s<= r9 goto +1
# CHECK-ASM-NEW: encoding: [0x1d,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x5d,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x2d,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x3d,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xad,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xbd,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x6d,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x7d,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xcd,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdd,0x90,0x01,0x00,0x00,0x00,0x00,0x00]
jeq r0, r9, +1
jne r0, r9, +1
jgt r0, r9, +1
jge r0, r9, +1
jlt r0, r9, +1
jle r0, r9, +1
jsgt r0, r9, +1
jsge r0, r9, +1
jslt r0, r9, +1
jsle r0, r9, +1

# CHECK-OBJ-NEW: jeq r3, r2, +1
# CHECK-OBJ-NEW: jne r3, r2, +1
# CHECK-OBJ-NEW: jgt r3, r2, +1
# CHECK-OBJ-NEW: jge r3, r2, +1
# CHECK-OBJ-NEW: jlt r3, r2, +1
# CHECK-OBJ-NEW: jle r3, r2, +1
# CHECK-OBJ-NEW: jsgt r3, r2, +1
# CHECK-OBJ-NEW: jsge r3, r2, +1
# CHECK-OBJ-NEW: jslt r3, r2, +1
# CHECK-OBJ-NEW: jsle r3, r2, +1
# CHECK-OBJ-OLD: if r3 == r2 goto +1
# CHECK-OBJ-OLD: if r3 != r2 goto +1
# CHECK-OBJ-OLD: if r3 > r2 goto +1
# CHECK-OBJ-OLD: if r3 >= r2 goto +1
# CHECK-OBJ-OLD: if r3 < r2 goto +1
# CHECK-OBJ-OLD: if r3 <= r2 goto +1
# CHECK-OBJ-OLD: if r3 s> r2 goto +1
# CHECK-OBJ-OLD: if r3 s>= r2 goto +1
# CHECK-OBJ-OLD: if r3 s< r2 goto +1
# CHECK-OBJ-OLD: if r3 s<= r2 goto +1
# CHECK-ASM-NEW: encoding: [0x1d,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x5d,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x2d,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x3d,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xad,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xbd,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x6d,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x7d,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xcd,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xdd,0x23,0x01,0x00,0x00,0x00,0x00,0x00]
jeq r3, r2, +1
jne r3, r2, +1
jgt r3, r2, +1
jge r3, r2, +1
jlt r3, r2, +1
jle r3, r2, +1
jsgt r3, r2, +1
jsge r3, r2, +1
jslt r3, r2, +1
jsle r3, r2, +1

# CHECK-OBJ-NEW: jeq r3, 123, +8
# CHECK-OBJ-NEW: jne r3, 123, +8
# CHECK-OBJ-NEW: jgt r3, 123, +8
# CHECK-OBJ-NEW: jge r3, 123, +8
# CHECK-OBJ-NEW: jlt r3, 123, +8
# CHECK-OBJ-NEW: jle r3, 123, +8
# CHECK-OBJ-NEW: jsgt r3, 123, +8
# CHECK-OBJ-NEW: jsge r3, 123, +8
# CHECK-OBJ-NEW: jslt r3, 123, +8
# CHECK-OBJ-NEW: jsle r3, 123, +8
# CHECK-OBJ-OLD: if r3 == 123 goto +8
# CHECK-OBJ-OLD: if r3 != 123 goto +8
# CHECK-OBJ-OLD: if r3 > 123 goto +8
# CHECK-OBJ-OLD: if r3 >= 123 goto +8
# CHECK-OBJ-OLD: if r3 < 123 goto +8
# CHECK-OBJ-OLD: if r3 <= 123 goto +8
# CHECK-OBJ-OLD: if r3 s> 123 goto +8
# CHECK-OBJ-OLD: if r3 s>= 123 goto +8
# CHECK-OBJ-OLD: if r3 s< 123 goto +8
# CHECK-OBJ-OLD: if r3 s<= 123 goto +8
# CHECK-ASM-NEW: encoding: [0x15,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x55,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x25,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x35,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xa5,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xb5,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x65,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x75,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xc5,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xd5,0x03,0x08,0x00,0x7b,0x00,0x00,0x00]
jeq r3, 123, +8
jne r3, 123, +8
jgt r3, 123, +8
jge r3, 123, +8
jlt r3, 123, +8
jle r3, 123, +8
jsgt r3, 123, +8
jsge r3, 123, +8
jslt r3, 123, +8
jsle r3, 123, +8

# CHECK-OBJ-NEW: jeq r5, -123, +8
# CHECK-OBJ-NEW: jne r5, -123, +8
# CHECK-OBJ-NEW: jgt r5, -123, +8
# CHECK-OBJ-NEW: jge r5, -123, +8
# CHECK-OBJ-NEW: jlt r5, -123, +8
# CHECK-OBJ-NEW: jle r5, -123, +8
# CHECK-OBJ-NEW: jsgt r5, -123, +8
# CHECK-OBJ-NEW: jsge r5, -123, +8
# CHECK-OBJ-NEW: jslt r5, -123, +8
# CHECK-OBJ-NEW: jsle r5, -123, +8
# CHECK-OBJ-OLD: if r5 == -123 goto +8
# CHECK-OBJ-OLD: if r5 != -123 goto +8
# CHECK-OBJ-OLD: if r5 > -123 goto +8
# CHECK-OBJ-OLD: if r5 >= -123 goto +8
# CHECK-OBJ-OLD: if r5 < -123 goto +8
# CHECK-OBJ-OLD: if r5 <= -123 goto +8
# CHECK-OBJ-OLD: if r5 s> -123 goto +8
# CHECK-OBJ-OLD: if r5 s>= -123 goto +8
# CHECK-OBJ-OLD: if r5 s< -123 goto +8
# CHECK-OBJ-OLD: if r5 s<= -123 goto +8
# CHECK-ASM-NEW: encoding: [0x15,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x55,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x25,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x35,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xa5,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xb5,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x65,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x75,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xc5,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xd5,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
jeq r5, -123, +8
jne r5, -123, +8
jgt r5, -123, +8
jge r5, -123, +8
jlt r5, -123, +8
jle r5, -123, +8
jsgt r5, -123, +8
jsge r5, -123, +8
jslt r5, -123, +8
jsle r5, -123, +8

# CHECK-OBJ-NEW: jeq w6, w2, +8
# CHECK-OBJ-NEW: jne w6, w2, +8
# CHECK-OBJ-NEW: jgt w6, w2, +8
# CHECK-OBJ-NEW: jge w6, w2, +8
# CHECK-OBJ-NEW: jlt w6, w2, +8
# CHECK-OBJ-NEW: jle w6, w2, +8
# CHECK-OBJ-NEW: jsgt w6, w2, +8
# CHECK-OBJ-NEW: jsge w6, w2, +8
# CHECK-OBJ-NEW: jslt w6, w2, +8
# CHECK-OBJ-NEW: jsle w6, w2, +8
# CHECK-OBJ-OLD: if w6 == w2 goto +8
# CHECK-OBJ-OLD: if w6 != w2 goto +8
# CHECK-OBJ-OLD: if w6 > w2 goto +8
# CHECK-OBJ-OLD: if w6 >= w2 goto +8
# CHECK-OBJ-OLD: if w6 < w2 goto +8
# CHECK-OBJ-OLD: if w6 <= w2 goto +8
# CHECK-OBJ-OLD: if w6 s> w2 goto +8
# CHECK-OBJ-OLD: if w6 s>= w2 goto +8
# CHECK-OBJ-OLD: if w6 s< w2 goto +8
# CHECK-OBJ-OLD: if w6 s<= w2 goto +8
# CHECK-ASM-NEW: encoding: [0x1e,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x5e,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x2e,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x3e,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xae,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xbe,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x6e,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0x7e,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xce,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
# CHECK-ASM-NEW: encoding: [0xde,0x26,0x08,0x00,0x00,0x00,0x00,0x00]
jeq w6, w2, +8
jne w6, w2, +8
jgt w6, w2, +8
jge w6, w2, +8
jlt w6, w2, +8
jle w6, w2, +8
jsgt w6, w2, +8
jsge w6, w2, +8
jslt w6, w2, +8
jsle w6, w2, +8

# CHECK-OBJ-NEW: jeq w5, -123, +8
# CHECK-OBJ-NEW: jne w5, -123, +8
# CHECK-OBJ-NEW: jgt w5, -123, +8
# CHECK-OBJ-NEW: jge w5, -123, +8
# CHECK-OBJ-NEW: jlt w5, -123, +8
# CHECK-OBJ-NEW: jle w5, -123, +8
# CHECK-OBJ-NEW: jsgt w5, -123, +8
# CHECK-OBJ-NEW: jsge w5, -123, +8
# CHECK-OBJ-NEW: jslt w5, -123, +8
# CHECK-OBJ-NEW: jsle w5, -123, +8
# CHECK-OBJ-OLD: if w5 == -123 goto +8
# CHECK-OBJ-OLD: if w5 != -123 goto +8
# CHECK-OBJ-OLD: if w5 s> -123 goto +8
# CHECK-OBJ-OLD: if w5 s>= -123 goto +8
# CHECK-OBJ-OLD: if w5 s< -123 goto +8
# CHECK-OBJ-OLD: if w5 s<= -123 goto +8
# CHECK-ASM-NEW: encoding: [0x16,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x56,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x26,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x36,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xa6,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xb6,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x66,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0x76,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xc6,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
# CHECK-ASM-NEW: encoding: [0xd6,0x05,0x08,0x00,0x85,0xff,0xff,0xff]
jeq w5, -123, +8
jne w5, -123, +8
jgt w5, -123, +8
jge w5, -123, +8
jlt w5, -123, +8
jle w5, -123, +8
jsgt w5, -123, +8
jsge w5, -123, +8
jslt w5, -123, +8
jsle w5, -123, +8


# CHECK-OBJ-NEW: call 8
# CHECK-OBJ-OLD: call 8
# CHECK-ASM-NEW: encoding: [0x85,0x00,0x00,0x00,0x08,0x00,0x00,0x00]
call 8

# CHECK-OBJ-NEW: callx r4
# CHECK-OBJ-OLD: callx r4
# CHECK-ASM-NEW: encoding: [0x8d,0x00,0x00,0x00,0x04,0x00,0x00,0x00]
callx r4

# CHECK-OBJ-NEW: exit
# CHECK-OBJ-OLD: exit
# CHECK-ASM-NEW: encoding: [0x95,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
exit
