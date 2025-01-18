; RUN: llc -O2 -march=sbf -mcpu=v3 < %s | FileCheck %s

declare void @dummy_func(i8, ptr, ptr, ptr, ptr, ptr, ptr)

define internal fastcc void @test_func(ptr %0, ptr %1, ptr %args, ptr %2) {
start:
; CHECK: add64 r10, -64
  %right = alloca [8 x i8], align 8
  %left = alloca [8 x i8], align 8
  store ptr %0, ptr %left, align 8
  store ptr %1, ptr %right, align 8
  call void @dummy_func(i8 0, ptr %left, ptr %left, ptr %right, ptr %right, ptr %args, ptr %2)
  unreachable
; CHECK: call dummy_func
; CHECK-NOT: add64 r10, 64
; CHECK: return
}