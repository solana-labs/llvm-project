; RUN: llc -march=sbf < %s 2>&1 | FileCheck --check-prefix=CHECK-64 %s
; RUN: llc -march=sbf -mattr=+alu32 < %s 2>&1 | FileCheck --check-prefix=CHECK-32 %s

; This file is generated with the source command and source
; $ clang -target bpf -O2 -S -emit-llvm t.c
; $ cat t.c
; int test(int *ptr, unsigned long long a) {
;    __sync_fetch_and_add(ptr, a);
;    return *ptr;
; }
;
; NOTE: passing unsigned long long as the second operand of __sync_fetch_and_add
; could effectively create sub-register reference coming from indexing a full
; register which could then exerceise hasLivingDefs inside BPFMIChecker.cpp.

define dso_local i32 @test(i32* nocapture %ptr, i64 %a) {
entry:
  %conv = trunc i64 %a to i32
  %0 = atomicrmw add i32* %ptr, i32 %conv seq_cst
; CHECK-64: ldxw r0, [r1 + 0]
; CHECK-64: add64 r0, r2
; CHECK-64: stxw [r1 + 0], r0

; CHECK-32: ldxw w0, [r1 + 0]
; CHECK-32: add32 w0, w2
; CHECK-32: stxw [r1 + 0], w0

  %1 = load i32, i32* %ptr, align 4
  ret i32 %1
}
