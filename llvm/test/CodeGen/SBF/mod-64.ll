; RUN: llc -O2 -march=sbf < %s | FileCheck %s

; Function Attrs: norecurse nounwind readnone
define dso_local i64 @rem(i64 %a, i64 %b) local_unnamed_addr #0 {
entry:
  %rem = urem i64 %a, %b
; CHECK: mod64 r{{[0-9]+}}, r{{[0-9]+}}
  ret i64 %rem
}

; Function Attrs: norecurse nounwind readnone
define dso_local i64 @rem_i(i64 %a) local_unnamed_addr #0 {
entry:
  %rem = urem i64 %a, 15
; CHECK: mod64 r{{[0-9]+}}, 15
  ret i64 %rem
}