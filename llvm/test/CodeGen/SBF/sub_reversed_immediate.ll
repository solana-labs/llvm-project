; RUN: llc < %s -march=sbf -mattr=+alu32 | FileCheck %s


; Function Attrs: norecurse nounwind readnone
define dso_local i64 @sub_ri_64(i64 %a) #0 {
entry:
; CHECK-LABEL: sub_ri_64:
  %sub = sub nsw i64 50, %a
; CHECK: sub64 r{{[0-9]+}}, 50
  ret i64 %sub
}

; Function Attrs: norecurse nounwind readnone
define dso_local i32 @sub_ri_32(i32 %a) #0 {
entry:
; CHECK-LABEL: sub_ri_32:
  %sub = sub nsw i32 50, %a
; CHECK: sub32 w{{[0-9]+}}, 50
  ret i32 %sub
}


; Function Attrs: norecurse nounwind readnone
define dso_local i64 @neg_64(i64 %a) #0 {
entry:
; CHECK-LABEL: neg_64:
  %sub = sub nsw i64 0, %a
; CHECK: sub64 r{{[0-9]+}}, 0
  ret i64 %sub
}

; Function Attrs: norecurse nounwind readnone
define dso_local i32 @neg_32(i32 %a) #0 {
entry:
; CHECK-LABEL: neg_32:
  %sub = sub nsw i32 0, %a
; CHECK: sub32 w{{[0-9]+}}, 0
  ret i32 %sub
}
