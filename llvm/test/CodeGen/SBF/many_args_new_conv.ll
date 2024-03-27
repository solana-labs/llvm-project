; RUN: llc -O2 -march=sbf -mcpu=sbfv2 < %s | FileCheck %s

; Function Attrs: nounwind uwtable
define i32 @caller_no_alloca(i32 %a, i32 %b, i32 %c) #0 {
entry:
; CHECK-LABEL: caller_no_alloca

; No changes to the stack pointer
; CHECK-NOT: add64 r11

; Saving arguments on the stack
; CHECK: mov64 r4, 55
; CHECK: stxdw [r10 - 32], r4
; CHECK: mov64 r4, 60
; CHECK: stxdw [r10 - 40], r4
; CHECK: mov64 r4, 50
; CHECK: stxdw [r10 - 24], r4
; CHECK: mov64 r4, 4
; CHECK: stxdw [r10 - 16], r4
; CHECK: mov64 r4, 3
; CHECK: stxdw [r10 - 8], r4
; CHECK: mov64 r4, 1
; CHECK: mov64 r5, 2
; CHECK: call callee_alloca

  %call = tail call i32 @callee_alloca(i32 %a, i32 %b, i32 %c, i32 1, i32 2, i32 3, i32 4, i32 50, i32 55, i32 60) #3
  ret i32 %call
}

; Function Attrs: nounwind uwtable
define i32 @caller_alloca(i32 %a, i32 %b, i32 %c) #0 {
; CHECK-LABEL: caller_alloca
; CHECK: add64 r11, -24
; CHECK: ldxw r1, [r10 - 4]

; Saving arguments in the stack
; CHECK: mov64 r4, 55

; Offset in the callee: (-56) - (-24) = -32
; CHECK: stxdw [r10 - 56], r4
; CHECK: mov64 r4, 60
; Offset in the callee: (-64) - (-24) = -40
; CHECK: stxdw [r10 - 64], r4
; CHECK: mov64 r4, 50
; Offset in the callee: (-48) - (-24) = -24
; CHECK: stxdw [r10 - 48], r4
; CHECK: mov64 r4, 4
; Offset in the callee: (-40) - (-24) = -16
; CHECK: stxdw [r10 - 40], r4
; CHECK: mov64 r4, 3
; Offset in the callee: (-32) - (-24) = -8
; CHECK: stxdw [r10 - 32], r4
; CHECK: mov64 r4, 1
; CHECK: mov64 r5, 2
; CHECK: call callee_no_alloca

entry:
  %g = alloca i32
  %g1 = load i32, ptr %g
  %call = tail call i32 @callee_no_alloca(i32 %g1, i32 %b, i32 %c, i32 1, i32 2, i32 3, i32 4, i32 50, i32 55, i32 60) #3
  %h = alloca i128
  %h1 = load i32, ptr %h
  %res = sub i32 %call, %h1
  ret i32 %res
}

; Function Attrs: nounwind uwtable
define i32 @callee_alloca(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %p, i32 %y, i32 %a1, i32 %a2) #1 {
; CHECK-LABEL: callee_alloca
; Loading arguments
; CHECK: ldxdw r2, [r10 - 8]
; CHECK: ldxdw r2, [r10 - 16]
; CHECK: ldxdw r2, [r10 - 24]
; CHECK: ldxdw r2, [r10 - 32]
; CHECK: ldxdw r2, [r10 - 40]
; Loading allocated i32
; CHECK: ldxw r0, [r10 - 44]

entry:
  %o = alloca i32
  %g = add i32 %a, %b
  %h = sub i32 %g, %c
  %i = add i32 %h, %d
  %j = sub i32 %i, %e
  %k = add i32 %j, %f
  %l = add i32 %k, %p
  %m = add i32 %l, %y
  %n = add i32 %m, %a1
  %q = add i32 %n, %a2
  %r = load i32, ptr %o
  %s = add i32 %r, %q
  ret i32 %s
}

; Function Attrs: nounwind uwtable
define i32 @callee_no_alloca(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e, i32 %f, i32 %p, i32 %y, i32 %a1, i32 %a2) #1 {
; CHECK-LABEL: callee_no_alloca
; Loading arguments
; CHECK: ldxdw r1, [r10 - 8]
; CHECK: ldxdw r1, [r10 - 16]
; CHECK: ldxdw r1, [r10 - 24]
; CHECK: ldxdw r1, [r10 - 32]
; CHECK: ldxdw r1, [r10 - 40]
entry:
  %g = add i32 %a, %b
  %h = sub i32 %g, %c
  %i = add i32 %h, %d
  %j = sub i32 %i, %e
  %k = add i32 %j, %f
  %l = add i32 %k, %p
  %m = add i32 %l, %y
  %n = add i32 %m, %a1
  %q = add i32 %n, %a2
  ret i32 %q
}