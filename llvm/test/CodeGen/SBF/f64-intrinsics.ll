; RUN: llc -march=sbf -mattr=+alu32 < %s | FileCheck -check-prefix=CHECK32 %s
; RUN: llc -march=sbf < %s | FileCheck -check-prefix=CHECK64 %s

; TODO: Add much more coverage. Currently this a sign extension regression
; test (SBFTargetLowering::shouldSignExtendTypeInLibCall).

declare double @llvm.powi.f64.i32(double, i32)

define double @powi_f64(double %a, i32 %b) nounwind {
; CHECK32-LABEL: powi_f64:
; CHECK32:       # %bb.0:
; CHECK32-NEXT:    call __powidf2
; CHECK32-NEXT:    exit
;
; CHECK64-LABEL: powi_f64:
; CHECK64:       # %bb.0:
; CHECK64-NEXT:    r2 <<= 32
; CHECK64-NEXT:    r2 s>>= 32
; CHECK64-NEXT:    call __powidf2
; CHECK64-NEXT:    exit
  %1 = call double @llvm.powi.f64.i32(double %a, i32 %b)
  ret double %1
}

