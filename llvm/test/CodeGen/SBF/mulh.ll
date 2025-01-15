; RUN: llc -O2 -march=sbf -mcpu=v2 < %s | FileCheck %s

define dso_local i32 @test_32_unsigned(i32 noundef %a, i32 noundef %b) {
entry:
; CHECK-LABEL: test_32_unsigned
  %conv = zext i32 %a to i64
  %conv1 = zext i32 %b to i64
  %mul = mul nuw i64 %conv1, %conv
  %shr = lshr i64 %mul, 32
  %conv2 = trunc i64 %shr to i32
  ret i32 %conv2

; CHECK: mov64 w0, w2
; CHECK: lmul64 r0, r1
; CHECK: rsh64 r0, 32
; CHECK: and32 w0, -1
}

define dso_local i32 @test_32_signed(i32 noundef %a, i32 noundef %b) {
entry:

; CHECK-LABEL: test_32_signed
  %conv = sext i32 %a to i64
  %conv1 = sext i32 %b to i64
  %mul = mul nsw i64 %conv1, %conv
  %shr = lshr i64 %mul, 32
  %conv2 = trunc i64 %shr to i32
  ret i32 %conv2

; CHECK: mov32 r1, w1
; CHECK: mov32 r0, w2
; CHECK: lmul64 r0, r1
; CHECK: rsh64 r0, 32
; CHECK: and32 w0, -1

}

define dso_local i64 @test_64_unsigned(i64 noundef %a, i64 noundef %b)  {
entry:
; CHECK-LABEL: test_64_unsigned
  %conv = zext i64 %a to i128
  %conv1 = zext i64 %b to i128
  %mul = mul nuw i128 %conv1, %conv
  %shr = lshr i128 %mul, 64
  %conv2 = trunc i128 %shr to i64
  ret i64 %conv2

; CHECK: uhmul64 r0, r1
}

define dso_local i64 @test_64_signed(i64 noundef %a, i64 noundef %b) {
entry:
; CHECK-LABEL: test_64_signed
  %conv = sext i64 %a to i128
  %conv1 = sext i64 %b to i128
  %mul = mul nsw i128 %conv1, %conv
  %shr = lshr i128 %mul, 64
  %conv2 = trunc i128 %shr to i64
  ret i64 %conv2

; CHECK: shmul64 r0, r1
}