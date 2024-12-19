; RUN: llc -march=sbf -mattr=+static-syscalls < %s | FileCheck --check-prefix=CHECK %s

; Syscall declaration in C:
;
; int c_declaration(int a, int b) {
;    int (*const syscall)(int a, int b) = (void*)50;
;    return syscall(a, b);
; }
; The following is the unoptimized output from clang:

define dso_local i32 @c_declaration(i32 noundef %a, i32 noundef %b) #0 {
entry:
  %a.addr = alloca i32, align 4
  %b.addr = alloca i32, align 4
  %syscall = alloca ptr, align 8
  store i32 %a, ptr %a.addr, align 4
  store i32 %b, ptr %b.addr, align 4
  store ptr inttoptr (i64 50 to ptr), ptr %syscall, align 8
  %0 = load i32, ptr %a.addr, align 4
  %1 = load i32, ptr %b.addr, align 4

; Ensure the syscall instruction is emitted
; CHECK: syscall 50

  %call = call i32 inttoptr (i64 50 to ptr)(i32 noundef %0, i32 noundef %1)
  ret i32 %call
}

; Syscall declaration in Rust:
;
;  #[no_mangle]
;  pub unsafe fn rust_declaration(b: u64) -> u32 {
;      let syscall : extern "C" fn(b: u64) -> u32 = core::mem::transmute(60u64);
;      return syscall(b);
;  }
; The following is the unoptimized output from rustc:

define i32 @rust_declaration(i64 %b) unnamed_addr {
start:
  %syscall.dbg.spill = alloca [8 x i8], align 8
  %b.dbg.spill = alloca [8 x i8], align 8
  store i64 %b, ptr %b.dbg.spill, align 8
  store ptr getelementptr (i8, ptr null, i64 60), ptr %syscall.dbg.spill, align 8

; Ensure the syscall instruction is emitted
; CHECK: syscall 60

  %_0 = call i32 getelementptr (i8, ptr null, i64 60)(i64 %b)
  ret i32 %_0
}