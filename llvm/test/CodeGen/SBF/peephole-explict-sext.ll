; RUN: llc < %s -march=sbf -mattr=+alu32,+explicit-sext | FileCheck %s

define dso_local i32 @select_cc_32(i32 %a, i32 %b, i32 %c, i32 %d) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: select_cc_32
  %cmp = icmp ugt i32 %a, %b
; CHECK-NOT: mov64 r{{[0-9]+}}, w1
; CHECK-NOT: mov64 r{{[0-9]+}}, w2
; CHECK: jgt r1, r2,
  %c.d = select i1 %cmp, i32 %c, i32 %d
  ret i32 %c.d
}
