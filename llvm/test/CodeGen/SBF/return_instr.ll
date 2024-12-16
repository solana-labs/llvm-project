; RUN: llc < %s -march=sbf -show-mc-encoding | FileCheck --check-prefix=CHECK-V1 %s
; RUN: llc < %s -march=sbf -mattr=+static-syscalls -show-mc-encoding | FileCheck --check-prefix=CHECK-V2 %s

define dso_local i64 @rem(i64 %a) local_unnamed_addr #0 {
entry:
; CHECK-LABEL: rem
  %rem = urem i64 %a, 15

; CHECK-V1: exit    # encoding: [0x95,0x00,0x00,0x00,0x00,0x00,0x00,0x00]
; CHECK-V2: return  # encoding: [0x9d,0x00,0x00,0x00,0x00,0x00,0x00,0x00]


  ret i64 %rem
}