; RUN: llc -O2 -march=sbf -mcpu=sbfv2 < %s | FileCheck %s

; Function Attrs: nounwind uwtable
define i32 @foo(i32 %a, i32 %b, i32 %c) #0 {
; CHECK-LABEL: foo:
; CHECK: mov64 r4, 2
; CHECK: stxdw [r10 - 8], r4
; CHECK: mov64 r4, 3
; CHECK: stxdw [r10 - 16], r4
; CHECK: mov64 r5, r10
; CHECK: mov64 r4, 1
; CHECK: call bar
entry:
  %call = tail call i32 @bar(i32 %a, i32 %b, i32 %c, i32 1, i32 2, i32 3) #3
  ret i32 %call
}

; Function Attrs: nounwind uwtable
define i32 @bar(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f) #1 {
; CHECK-LABEL: bar:
; CHECK: ldxdw r1, [r5 - 8]
; CHECK: sub64 r0, r1
; CHECK: ldxdw r1, [r5 - 16]
; CHECK: add64 r0, r1
entry:
  %g = add i32 %a, %b
  %h = sub i32 %g, %c
  %i = add i32 %h, %d
  %j = sub i32 %i, %e
  %k = add i32 %j, %f
  ret i32 %k
}
