; RUN: not llc -march=bpf < %s 2> %t1
; RUN: FileCheck %s < %t1
; CHECK: variadic functions are not supported

; Function Attrs: nounwind readnone uwtable
define void @foo(i32 %a, ...) #0 {
entry:
  ret void
}
