; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj -o - %s | llvm-objdump -d - | FileCheck %s

; CHECK: jsgt r2, r1,
; CHECK: call 0x1
; CHECK: return
; CHECK: call 0x2
; CHECK: return

define void @foo(i32 %a) {
%b = icmp sgt i32 %a, -1
br i1 %b, label %x, label %y
x:
call void inttoptr (i64 1 to void ()*)()
ret void
y:
call void inttoptr (i64 2 to void ()*)()
ret void
}
