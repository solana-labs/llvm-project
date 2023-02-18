; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj -o - %s | llvm-objdump -d - | FileCheck --check-prefix=CHECK-EL %s

define i32 @ld_pseudo() #0 {
entry:
  %call = tail call i64 @llvm.bpf.pseudo(i64 2, i64 3)
  tail call void inttoptr (i64 4 to void (i64, i32)*)(i64 %call, i32 4) #2
  ret i32 0
; CHECK-LABEL: ld_pseudo:
; CHECK-EL: ld_pseudo r1, 2, 3
}

declare i64 @llvm.bpf.pseudo(i64, i64) #2

define i32 @bswap(i64 %a, i64 %b, i64 %c) #0 {
entry:
  %0 = tail call i64 @llvm.bswap.i64(i64 %a)
  %conv = trunc i64 %b to i32
  %1 = tail call i32 @llvm.bswap.i32(i32 %conv)
  %conv1 = zext i32 %1 to i64
  %add = add i64 %conv1, %0
  %conv2 = trunc i64 %c to i16
  %2 = tail call i16 @llvm.bswap.i16(i16 %conv2)
  %conv3 = zext i16 %2 to i64
  %add4 = add i64 %add, %conv3
  %conv5 = trunc i64 %add4 to i32
  ret i32 %conv5
; CHECK-LABEL: bswap:
; CHECK-EL: be64 r1
; CHECK-EL: be32 r0
; CHECK-EL: add64 r0, r1
; CHECK-EL: be16 r3
; CHECK-EL: add64 r0, r3
}

declare i64 @llvm.bswap.i64(i64) #1
declare i32 @llvm.bswap.i32(i32) #1
declare i16 @llvm.bswap.i16(i16) #1
