; RUN: llc < %s -march=sbf -mattr=+alu32 | FileCheck  --check-prefix=CHECK-v1 %s
; RUN: llc < %s -march=sbf -mattr=+alu32 -mcpu=sbfv2 | FileCheck  --check-prefix=CHECK-v2 %s


; Function Attrs: norecurse nounwind readnone
define dso_local i64 @sub_imm_minus_reg_64(i64 %a) #0 {
entry:
; CHECK-LABEL: sub_imm_minus_reg_64:
  %sub = sub nsw i64 50, %a

; CHECK-v1: mov64 r{{[0-9]+}}, 50
; CHECK-v1: sub64 r{{[0-9]+}}, r{{[0-9]+}}

; CHECK-v2: sub64 r{{[0-9]+}}, 50
  ret i64 %sub
}

; Function Attrs: norecurse nounwind readnone
define dso_local i64 @sub_reg_minus_imm_64(i64 %a) #0 {
entry:
; CHECK-LABEL: sub_reg_minus_imm_64:
  %t = sub nsw i64 %a, 50
; CHECK-v1: add64 r{{[0-9]+}}, -50

; CHECK-v2: add64 r{{[0-9]+}}, -50
  ret i64 %t
}


; Function Attrs: norecurse nounwind readnone
define dso_local i32 @sub_imm_minus_reg_32(i32 %a) #0 {
entry:
; CHECK-LABEL: sub_imm_minus_reg_32:
  %sub = sub nsw i32 50, %a

; CHECK-v1: mov32 w{{[0-9]+}}, 50
; CHECK-v1: sub32 w{{[0-9]+}}, w{{[0-9]+}}

; CHECK-v2: sub32 w{{[0-9]+}}, 50

  ret i32 %sub
}

; Function Attrs: norecurse nounwind readnone
define dso_local i32 @sub_reg_minus_imm_32(i32 %a) #0 {
entry:
; CHECK-LABEL: sub_reg_minus_imm_32:
  %t = sub nsw i32 %a, 50

; CHECK-v1: add32 w{{[0-9]+}}, -50

; CHECK-v2: add32 w{{[0-9]+}}, -50
  ret i32 %t
}


; Function Attrs: norecurse nounwind readnone
define dso_local i64 @neg_64(i64 %a) #0 {
entry:
; CHECK-LABEL: neg_64:
  %sub = sub nsw i64 0, %a

; CHECK-v1: neg64 r{{[0-9]+}}
; CHECK-v2: sub64 r{{[0-9]+}}, 0

  ret i64 %sub
}

; Function Attrs: norecurse nounwind readnone
define dso_local i32 @neg_32(i32 %a) #0 {
entry:
; CHECK-LABEL: neg_32:
  %sub = sub nsw i32 0, %a

; CHECK-v1: neg32 w{{[0-9]+}}
; CHECK-v2: sub32 w{{[0-9]+}}, 0

  ret i32 %sub
}
