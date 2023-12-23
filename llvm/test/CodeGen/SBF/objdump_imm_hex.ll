; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj -o - %s | llvm-objdump -d - | FileCheck --check-prefix=CHECK-DEC %s
; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj -o - %s | llvm-objdump -d --print-imm-hex - | FileCheck --check-prefix=CHECK-HEX %s
; RUN: llc < %s -march=sbf -mcpu=sbfv2 -show-mc-encoding | FileCheck --check-prefix=CHECK-REL %s

; Source Code:
; int gbl;
; int test(unsigned long long a, unsigned long long b) {
;   int ret = 0;
;   if (a == 0xABCDABCDabcdabcdULL) {
;     gbl = gbl * gbl * 2;
;     ret = 1;
;     goto out;
;   }
;   if (b == 0xABCDabcdabcdULL) {
;     gbl = gbl * 4;
;     ret = 2;
;   }
;  out:
;   return ret;
; }

@gbl = common local_unnamed_addr global i32 0, align 4

; Function Attrs: norecurse nounwind
define i32 @test(i64, i64) local_unnamed_addr #0 {
; CHECK-LABEL: test
  %3 = icmp eq i64 %0, -6067004223159161907
  br i1 %3, label %4, label %8
; CHECK-DEC: b4 03 00 00 cd ab cd ab	mov32 w3, -0x54325433
; CHECK-DEC: f7 03 00 00 cd ab cd ab	hor64 r3, -0x54325433
; CHECK-DEC: 5d 31 07 00 00 00 00 00         jne r1, r3, +0x7
; CHECK-HEX: b4 03 00 00 cd ab cd ab	mov32 w3, -0x54325433
; CHECK-HEX: f7 03 00 00 cd ab cd ab	hor64 r3, -0x54325433
; CHECK-HEX: 5d 31 07 00 00 00 00 00         jne r1, r3, +0x7

; <label>:4:                                      ; preds = %2
; CHECK-DEC: b4 01 00 00 00 00 00 00	mov32 w1, 0x0
; CHECK-DEC: f7 01 00 00 00 00 00 00	hor64 r1, 0x0
; CHECK-HEX: b4 01 00 00 00 00 00 00	mov32 w1, 0x0
; CHECK-HEX: f7 01 00 00 00 00 00 00	hor64 r1, 0x0
; CHECK-REL:   fixup A - offset: 0, value: gbl, kind: FK_SecRel_8
  %5 = load i32, i32* @gbl, align 4
  %6 = shl i32 %5, 1
; CHECK-DEC: 67 01 00 00 01 00 00 00         lsh64 r1, 0x1
; CHECK-HEX: 67 01 00 00 01 00 00 00         lsh64 r1, 0x1
  %7 = mul i32 %6, %5
  br label %13

; <label>:8:                                      ; preds = %2
  %9 = icmp eq i64 %1, 188899839028173
; CHECK-DEC: b4 01 00 00 cd ab cd ab	mov32 w1, -0x54325433
; CHECK-DEC: f7 01 00 00 cd ab 00 00	hor64 r1, 0xabcd
; CHECK-HEX: b4 01 00 00 cd ab cd ab	mov32 w1, -0x54325433
; CHECK-HEX: f7 01 00 00 cd ab 00 00	hor64 r1, 0xabcd
  br i1 %9, label %10, label %16

; <label>:10:                                     ; preds = %8
; CHECK-DEC: b4 01 00 00 00 00 00 00	mov32 w1, 0x0
; CHECK-DEC: f7 01 00 00 00 00 00 00	hor64 r1, 0x0
; CHECK-HEX: b4 01 00 00 00 00 00 00	mov32 w1, 0x0
; CHECK-HEX: f7 01 00 00 00 00 00 00	hor64 r1, 0x0
; CHECK-REL: fixup A - offset: 0, value: gbl, kind: FK_SecRel_8
  %11 = load i32, i32* @gbl, align 4
  %12 = shl nsw i32 %11, 2
  br label %13

; <label>:13:                                     ; preds = %4, %10
  %14 = phi i32 [ %12, %10 ], [ %7, %4 ]
  %15 = phi i32 [ 2, %10 ], [ 1, %4 ]
  store i32 %14, i32* @gbl, align 4
; CHECK-DEC: 63 12 00 00 00 00 00 00         stxw [r2 + 0x0], r1
; CHECK-HEX: 63 12 00 00 00 00 00 00         stxw [r2 + 0x0], r1
  br label %16

; <label>:16:                                     ; preds = %13, %8
  %17 = phi i32 [ 0, %8 ], [ %15, %13 ]
  ret i32 %17
}

attributes #0 = { norecurse nounwind }
