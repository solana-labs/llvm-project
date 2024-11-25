; RUN: llc -march=sbf -mattr=+alu32 < %s | FileCheck --check-prefixes=CHECK-v1,CHECK %s
; RUN: llc -march=sbf -mattr=+alu32,+explicit-sext < %s | FileCheck --check-prefixes=CHECK-v2,CHECK %s


define dso_local i64 @my_sext(i32 %a) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: my_sext
  %res = sext i32 %a to i64

; CHECK-v1: mov32 r0, w1
; CHECK-v1: lsh64 r0, 32
; CHECK-v1: arsh64 r0, 32

; CHECK-v2: mov32 r0, w1
  ret i64 %res
}

define dso_local i64 @my_zext(i32 %a) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: my_zext
  %res = zext i32 %a to i64

; CHECK-v1: mov32 r0, w1
; CHECK-v2: mov64 w0, w1

  ret i64 %res
}

define dso_local i32 @my_trunc(i64 %a) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: my_trunc
  %res = trunc i64 %a to i32

; CHECK-v1: mov64 r0, r1
; CHECK-v2: mov64 r0, r1
; CHECK-v2: and32 w0, -1
  ret i32 %res
}

define dso_local i32 @copy_phys(i32 %a) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: copy_phys
  %res = add i32 %a, 2
  %b = sub i32 %res, 5
; CHECK-v1: mov32 w0, w1
; CHECK-v2: mov64 w0, w1
  ret i32 %b
}

define dso_local i32 @select_cc_imm(i32 %a, i32 %c, i32 %d) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: select_cc_imm
  %cmp = icmp sgt i32 %a, 10
; CHECK-v1: mov32 w0, w2
; CHECK-v2: mov64 w0, w2

; CHECK-v1: mov32 r1, w1
; CHECK-v1: lsh64 r1, 32
; CHECK-v1: arsh64 r1, 32
; CHECK-v2: mov32 r1, w1

  %c.d = select i1 %cmp, i32 %c, i32 %d
; CHECK-v1: mov32 w0, w3
; CHECK-v2: mov64 w0, w3

  ret i32 %c.d
}

define dso_local i32 @select_cc_reg(i32 %a, i32 %b, i32 %c, i32 %d) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: select_cc_reg
  %cmp = icmp sgt i32 %a, %b
; CHECK-v1: mov32 w0, w3
; CHECK-v2: mov64 w0, w3

; CHECK-v1: mov32 r1, w1
; CHECK-v1: lsh64 r1, 32
; CHECK-v1: arsh64 r1, 32
; CHECK-v2: mov32 r1, w1

; CHECK-v1: mov32 r2, w2
; CHECK-v1: lsh64 r2, 32
; CHECK-v1: arsh64 r2, 32
; CHECK-v2: mov32 r2, w2

  %c.d = select i1 %cmp, i32 %c, i32 %d
; CHECK-v1: mov32 w0, w4
; CHECK-v2: mov64 w0, w4
  ret i32 %c.d
}

define dso_local i64 @select_cc_imm_64(i32 %a, i64 %c, i64 %d) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: select_cc_imm_64
; CHECK-v1: mov64 r0, r2
  %cmp = icmp sgt i32 %a, 10
  %c.d = select i1 %cmp, i64 %c, i64 %d
; CHECK: mov64 r0, r3
  ret i64 %c.d
}

define dso_local i64 @select_cc_reg_64(i32 %a, i32 %b, i64 %c, i64 %d) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: select_cc_reg_64
; CHECK: mov64 r0, r3
  %cmp = icmp sgt i32 %a, %b
  %c.d = select i1 %cmp, i64 %c, i64 %d
; CHECK: mov64 r0, r4
  ret i64 %c.d
}