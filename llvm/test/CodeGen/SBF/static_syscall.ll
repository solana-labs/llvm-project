; RUN: llc -march=sbf < %s | FileCheck --check-prefix=CHECK-V1 %s
; RUN: llc -march=sbf -mattr=+static-syscalls -show-mc-encoding < %s | FileCheck --check-prefix=CHECK-V2 %s


; Function Attrs: nounwind
define dso_local i32 @test(i32 noundef %a, i32 noundef %b) {
entry:
; CHECK-LABEL: test

; CHECK-V1: call -2
; CHECK-V2: syscall 1   # encoding: [0x95,0x00,0x00,0x00,0x01,0x00,0x00,0x00]
  %syscall_1 = tail call i32 inttoptr (i64 4294967294 to ptr)(i32 noundef %a, i32 noundef %b)

; CHECK-V1: call -12
; CHECK-V2: syscall 11  # encoding: [0x95,0x00,0x00,0x00,0x0b,0x00,0x00,0x00]
  %syscall_2 = tail call i32 inttoptr (i64 4294967284 to ptr)(i32 noundef %a, i32 noundef %b)

; CHECK-V1: call -112
; CHECK-V2: call -112
  %not_syscall = tail call i32 inttoptr (i64 4294967184 to ptr)(i32 noundef %a, i32 noundef %b)

  %add_1 = add i32 %syscall_1, %syscall_2
  %add_2 = add i32 %add_1, %not_syscall
  ret i32 %add_1
}
