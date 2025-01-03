; RUN: llc -march=sbf < %s | FileCheck --check-prefixes=CHECK,CHECK-V0 %s
; RUN: llc -march=sbf -mattr=+static-syscalls -show-mc-encoding < %s | FileCheck --check-prefixes=CHECK,CHECK-V3 %s


; Function Attrs: nounwind
define dso_local i32 @test(i32 noundef %a, i32 noundef %b) {
entry:
; CHECK-LABEL: test

; CHECK-V0: call 2
; CHECK-V3 syscall 2   # encoding: [0x95,0x00,0x00,0x00,0x01,0x00,0x00,0x00]
  %syscall_1 = tail call i32 inttoptr (i64 2 to ptr)(i32 noundef %a, i32 noundef %b)

; CHECK-V0: call 11
; CHECK-V3: syscall 11  # encoding: [0x95,0x00,0x00,0x00,0x0b,0x00,0x00,0x00]
  %syscall_2 = tail call i32 inttoptr (i64 11 to ptr)(i32 noundef %a, i32 noundef %b)

; CHECK-V0: call 112
; CHECK-V3: syscall 112
  %syscall_3 = tail call i32 inttoptr (i64 112 to ptr)(i32 noundef %a, i32 noundef %b)

; CHECK: mov64 r1, 89
; CHECK: mov64 r2, 87
; CHECK-V0: call 112
; CHECK-V3: syscall 112
  %syscall_4 = tail call i32 inttoptr (i64 112 to ptr)(i32 89,  i32 87)

  %add_1 = add i32 %syscall_1, %syscall_2
  %add_2 = add i32 %add_1, %syscall_3
  %add_3 = add i32 %add_2, %syscall_4
  ret i32 %add_3
}
