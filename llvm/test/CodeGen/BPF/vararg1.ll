; DISABLE: not llc -march=bpf < %s 2| FileCheck %s
; RUN: false
; XFAIL: *
; CHECK: with VarArgs

; Function Attrs: nounwind readnone uwtable
define void @foo(i32 %a, ...) #0 {
entry:
  ret void
}
