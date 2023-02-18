; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj -o - %s | llvm-objdump -d - | FileCheck %s
;
; Source:
;   int test() {
;     asm volatile("mov64 r0, r0" ::);
;     return 0;
;   }
; Compilation flag:
;   clang -target sbf -O2 -S -emit-llvm t.c

; Function Attrs: nounwind
define dso_local i32 @test() local_unnamed_addr {
entry:
  tail call void asm sideeffect "mov64 r0, r0", ""()
  ret i32 0
}
; CHECK-LABEL: test
; CHECK:       mov64 r0, r0
; CHECK:       mov64 r0, 0
