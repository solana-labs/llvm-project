; RUN: llc < %s -march=sbf -show-mc-encoding | FileCheck --check-prefix=CHECK-v1 %s
; RUN: llc < %s -march=sbf -mcpu=sbfv2 -show-mc-encoding | FileCheck --check-prefix=CHECK-v2 %s

define void @test() #0 {
entry:
; CHECK-LABEL: test:

; CHECK-v1: mov64 r1, 123 # encoding: [0xb7,0x01,0x00,0x00,0x7b,0x00,0x00,0x00]
; CHECK-v2: mov64 r1, 123
; CHECK-v1: call f_i16
  call void @f_i16(i16 123)

; CHECK-v1: mov64 r1, 12345678 # encoding: [0xb7,0x01,0x00,0x00,0x4e,0x61,0xbc,0x00]
; CHECK-v2: mov64 r1, 12345678
; CHECK-v1: call f_i32
  call void @f_i32(i32 12345678)

; 72623859790382856 = 0x0102030405060708
; 84281096 = 0x05060708
; 16909060 = 0x01020304

; CHECK-v2: mov32 r1, 84281096  # encoding: [0xb4,0x01,0x00,0x00,0x08,0x07,0x06,0x05]
; CHECK-v2: hor64 r1, 16909060  # encoding: [0xf7,0x01,0x00,0x00,0x04,0x03,0x02,0x01]

; CHECK-v1: lddw r1, 72623859790382856 # encoding: [0x18,0x01,0x00,0x00,0x08,0x07,0x06,0x05,0x00,0x00,0x00,0x00,0x04,0x03,0x02,0x01]
; CHECK-v1: call f_i64
  call void @f_i64(i64 72623859790382856)

; CHECK-v1: mov64 r1, 1234
; CHECK-v1: mov64 r2, 5678
; CHECK-v1: call f_i32_i32
  call void @f_i32_i32(i32 1234, i32 5678)

; CHECK-v1: mov64 r1, 2
; CHECK-v1: mov64 r2, 3
; CHECK-v1: mov64 r3, 4
; CHECK-v1: call f_i16_i32_i16
  call void @f_i16_i32_i16(i16 2, i32 3, i16 4)

; 7262385979038285 = 0x0019CD1A00809A4D
; 8428109 = 0x00809A4D
; 1690906 = 0x0019CD1A
; CHECK-v2: mov32 r2, 8428109
; CHECK-v2: hor64 r2, 1690906

; CHECK-v1: mov64 r1, 5
; CHECK-v1: lddw r2, 7262385979038285
; CHECK-v1: mov64 r3, 6
; CHECK-v1: call f_i16_i64_i16
  call void @f_i16_i64_i16(i16 5, i64 7262385979038285, i16 6)

  ret void
}

@g_i16 = common global i16 0, align 2
@g_i32 = common global i32 0, align 2
@g_i64 = common global i64 0, align 4

define void @f_i16(i16 %a) #0 {
; CHECK-v1: f_i16:
; CHECK-v1: stxh [r2 + 0], r1 # encoding: [0x6b,0x12,0x00,0x00,0x00,0x00,0x00,0x00]
  store volatile i16 %a, i16* @g_i16, align 2
  ret void
}

define void @f_i32(i32 %a) #0 {
; CHECK-v1: f_i32:
; CHECK-v1: stxw [r2 + 0], r1 # encoding: [0x63,0x12,0x00,0x00,0x00,0x00,0x00,0x00]
  store volatile i32 %a, i32* @g_i32, align 2
  ret void
}

define void @f_i64(i64 %a) #0 {
; CHECK-v1: f_i64:
; CHECK-v1: stxdw [r2 + 0], r1  # encoding: [0x7b,0x12,0x00,0x00,0x00,0x00,0x00,0x00]
  store volatile i64 %a, i64* @g_i64, align 2
  ret void
}

define void @f_i32_i32(i32 %a, i32 %b) #0 {
; CHECK-v1: f_i32_i32:
; CHECK-v1: stxw [r3 + 0], r1
  store volatile i32 %a, i32* @g_i32, align 4
; CHECK-v1: stxw [r3 + 0], r2
  store volatile i32 %b, i32* @g_i32, align 4
  ret void
}

define void @f_i16_i32_i16(i16 %a, i32 %b, i16 %c) #0 {
; CHECK-v1: f_i16_i32_i16:
; CHECK-v1: stxh [r4 + 0], r1
  store volatile i16 %a, i16* @g_i16, align 2
; CHECK-v1: stxw [r1 + 0], r2
  store volatile i32 %b, i32* @g_i32, align 4
; CHECK-v1: stxh [r4 + 0], r3
  store volatile i16 %c, i16* @g_i16, align 2
  ret void
}

define void @f_i16_i64_i16(i16 %a, i64 %b, i16 %c) #0 {
; CHECK-v1: f_i16_i64_i16:
; CHECK-v1: stxh [r4 + 0], r1
  store volatile i16 %a, i16* @g_i16, align 2
; CHECK-v1: stxdw [r1 + 0], r2 # encoding: [0x7b,0x21,0x00,0x00,0x00,0x00,0x00,0x00]
  store volatile i64 %b, i64* @g_i64, align 8
; CHECK-v1: stxh [r4 + 0], r3
  store volatile i16 %c, i16* @g_i16, align 2
  ret void
}
