; RUN: llc < %s -march=sbf -mattr=+alu32 | FileCheck %s
;
; Source:
; void test_func_64(long * vec) {
;     vec[0] = 50 - vec[0];
;     vec[1] = vec[3] - vec[2];
; }
;
; void test_func_32(int * vec) {
;     vec[0] = 50 - vec[0];
;     vec[1] = vec[3] - vec[2];
; }
;
; Compilation flag:
; clang -S -emit-llvm test.c


; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @test_func_64(ptr noundef %vec) #0 {
entry:
; CHECK-LABEL: test_func_64:
  %vec.addr = alloca ptr, align 8
  store ptr %vec, ptr %vec.addr, align 8
  %0 = load ptr, ptr %vec.addr, align 8
  %arrayidx = getelementptr inbounds i64, ptr %0, i64 0
  %1 = load i64, ptr %arrayidx, align 8
  %sub = sub nsw i64 50, %1
; CHECK: ldxdw r2, [r1 + 0]
; CHECK: sub64 r2, 50
; CHECK: stxdw [r1 + 0], r2
  %2 = load ptr, ptr %vec.addr, align 8
  %arrayidx1 = getelementptr inbounds i64, ptr %2, i64 0
  store i64 %sub, ptr %arrayidx1, align 8
  %3 = load ptr, ptr %vec.addr, align 8
  %arrayidx2 = getelementptr inbounds i64, ptr %3, i64 3
  %4 = load i64, ptr %arrayidx2, align 8
  %5 = load ptr, ptr %vec.addr, align 8
  %arrayidx3 = getelementptr inbounds i64, ptr %5, i64 2
  %6 = load i64, ptr %arrayidx3, align 8
  %sub4 = sub nsw i64 %4, %6
; CHECK: ldxdw r2, [r1 + 16]
; CHECK: ldxdw r3, [r1 + 24]
; CHECK: sub64 r3, r2
; CHECK: stxdw [r1 + 8], r3
  %7 = load ptr, ptr %vec.addr, align 8
  %arrayidx5 = getelementptr inbounds i64, ptr %7, i64 1
  store i64 %sub4, ptr %arrayidx5, align 8
  ret void
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define void @test_func_32(ptr noundef %vec) #0 {
entry:
; CHECK-LABEL: test_func_32:
  %vec.addr = alloca ptr, align 8
  store ptr %vec, ptr %vec.addr, align 8
  %0 = load ptr, ptr %vec.addr, align 8
  %arrayidx = getelementptr inbounds i32, ptr %0, i64 0
  %1 = load i32, ptr %arrayidx, align 4
  %sub = sub nsw i32 50, %1
; CHECK: ldxw w2, [r1 + 0]
; CHECK: sub32 w2, 50
; CHECK: stxw [r1 + 0], w2
  %2 = load ptr, ptr %vec.addr, align 8
  %arrayidx1 = getelementptr inbounds i32, ptr %2, i64 0
  store i32 %sub, ptr %arrayidx1, align 4
  %3 = load ptr, ptr %vec.addr, align 8
  %arrayidx2 = getelementptr inbounds i32, ptr %3, i64 3
  %4 = load i32, ptr %arrayidx2, align 4
  %5 = load ptr, ptr %vec.addr, align 8
  %arrayidx3 = getelementptr inbounds i32, ptr %5, i64 2
  %6 = load i32, ptr %arrayidx3, align 4
  %sub4 = sub nsw i32 %4, %6
; CHECK: ldxw w2, [r1 + 8]
; CHECK: ldxw w3, [r1 + 12]
; CHECK: sub32 w3, w2
; CHECK: stxw [r1 + 4], w3
  %7 = load ptr, ptr %vec.addr, align 8
  %arrayidx5 = getelementptr inbounds i32, ptr %7, i64 1
  store i32 %sub4, ptr %arrayidx5, align 4
  ret void
}