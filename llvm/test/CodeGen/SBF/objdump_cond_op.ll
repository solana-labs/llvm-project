; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj -o - %s | llvm-objdump -d - | FileCheck %s

; Source Code:
; int gbl;
; int test(int a, int b) {
;   if (a == 2) {
;     gbl = gbl * gbl * 2;
;     goto out;
;   }
;   if (a != b) {
;     gbl = gbl * 4;
;   }
; out:
;   return gbl;
; }

@gbl = common local_unnamed_addr global i32 0, align 4

define i32 @test(i32, i32) local_unnamed_addr #0 {
  %3 = icmp eq i32 %0, 2
  br i1 %3, label %4, label %8

; <label>:4:                                      ; preds = %2
  %5 = load i32, i32* @gbl, align 4
  %6 = shl i32 %5, 1
  %7 = mul i32 %6, %5
  br label %13
; CHECK: lsh64 r1, 32
; CHECK: rsh64 r1, 32
; CHECK: jne r1, 2, +6 <LBB0_2>

; <label>:8:                                      ; preds = %2
  %9 = icmp eq i32 %0, %1
  %10 = load i32, i32* @gbl, align 4
  br i1 %9, label %15, label %11

; CHECK: lddw r1, 0
; CHECK: ldxw r0, [r1 + 0]
; CHECK: mul64 r0, r0
; CHECK: lsh64 r0, 1
; CHECK: ja +7 <LBB0_4>

; <label>:11:                                     ; preds = %8
  %12 = shl nsw i32 %10, 2
  br label %13

; CHECK-LABEL: <LBB0_2>:
; CHECK: lddw r3, 0
; CHECK: ldxw r0, [r3 + 0]
; CHECK: lsh64 r2, 32
; CHECK: rsh64 r2, 32
; CHECK: jeq r1, r2, +4 <LBB0_5>
; CHECK: lsh64 r0, 2

; <label>:13:                                     ; preds = %4, %11
  %14 = phi i32 [ %12, %11 ], [ %7, %4 ]
  store i32 %14, i32* @gbl, align 4
  br label %15
; CHECK-LABEL: <LBB0_4>:
; CHECK: lddw r1, 0
; CHECK: stxw [r1 + 0], r0

; <label>:15:                                     ; preds = %8, %13
  %16 = phi i32 [ %14, %13 ], [ %10, %8 ]
  ret i32 %16
; CHECK-LABEL: <LBB0_5>:
; CHECK: exit
}
attributes #0 = { norecurse nounwind }
