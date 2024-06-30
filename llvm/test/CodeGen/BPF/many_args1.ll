; RUN: not llc -march=bpf < %s 2> %t1
; RUN: FileCheck %s < %t1
; CHECK: error: <unknown>:0:0: in function foo i32 (i32, i32, i32): too many args to {{t10|0x[0-f]+}}: i64 = GlobalAddress<ptr @bar> 0

; Function Attrs: nounwind uwtable
define i32 @foo(i32 %a, i32 %b, i32 %c) #0 {
entry:
  %call = tail call i32 @bar(i32 %a, i32 %b, i32 %c, i32 1, i32 2, i32 3) #3
  ret i32 %call
}

declare i32 @bar(i32, i32, i32, i32, i32, i32) #1
