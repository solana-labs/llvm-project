; RUN: llc -march=sbf -mcpu=sbfv2 -mattr=+alu32 < %s | FileCheck %s

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define i64 @zeroext(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: zeroext
  %add1 = add i32 %a, %b
  %sext1 = zext i32 %add1 to i64
  %res = mul i64 %sext1, 3
  ret i64 %res;

; Zero extending involves no operation
; CHECK: mov32 w0, w1
; CHECK: add32 w0, w2
; CHECK: mul64 r0, 3
}


; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define i64 @signext(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: signext
  %add1 = add i32 %a, %b
  %sext1 = sext i32 %add1 to i64
  %res = mul i64 %sext1, 3
  ret i64 %res

; Sign extension is a mov32
; CHECK: add32 w1, w2
; CHECK: mov32 r0, w1
; CHECK: mul64 r0, 3
}


; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define i32 @trunc(i64 noundef %a, i64 noundef %b) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: trunc
  %add1 = add i64 %a, %b
  %sext1 = trunc i64 %add1 to i32
  %res = mul i32 %sext1, 3
  ret i32 %res

; Truncation needs the and32 bit mask
; CHECK: mov64 r0, r1
; CHECK: and32 w2, -1
; CHECK: and32 w0, -1
; CHECK: add32 w0, w2
; CHECK: mul32 w0, 3
}

!llvm.module.flags = !{!0, !1, !2, !3}
!llvm.ident = !{!4}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 8, !"PIC Level", i32 2}
!2 = !{i32 7, !"uwtable", i32 1}
!3 = !{i32 7, !"frame-pointer", i32 1}
!4 = !{!"clang version 16.0.5 (https://github.com/solana-labs/llvm-project.git b33adebdaaa2ac524e019c92b58e77b33cd216fb)"}
