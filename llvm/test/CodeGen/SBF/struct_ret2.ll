; RUN: llc < %s -march=sbf | FileCheck %s

; Function Attrs: nounwind uwtable
define { i64, i32 } @foo(i32 %a, i32 %b, i32 %c) #0 {
; CHECK-LABEL: foo:
; CHECK: call bar
; CHECK: r1 = *(u64 *)(r10 - 16)
; CHECK: r2 = *(u32 *)(r10 - 8)
; CHECK: *(u32 *)(r6 + 8) = r2
; CHECK: *(u64 *)(r6 + 0) = r1
entry:
  %call = tail call { i64, i32 } @bar(i32 %a, i32 %b, i32 %c, i32 1, i32 2) #3
  ret { i64, i32 } %call
}

declare { i64, i32 } @bar(i32, i32, i32, i32, i32) #1
