; RUN: llc < %s -march=sbf -mattr=+alu32 | FileCheck %s
;
; Source:
; int test_func_64(long * vec, long idx) {
;      vec[idx] = -idx;
;      return idx;
;  }
;
;  int test_func_32(int * vec, int idx) {
;      vec[idx] = -idx;
;      return idx;
;  }
;
; Compilation flag:
; clang -S -emit-llvm test.c

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @test_func_32(ptr noundef %vec, i32 noundef %idx) #0 {
; CHECK-LABEL: test_func_32:
; CHECK: stxw [r10 - 12], w2
; CHECK: sub32 w2, 0
; CHECK: stxw [r1 + 0], w2
entry:
  %vec.addr = alloca ptr, align 8
  %idx.addr = alloca i32, align 4
  store ptr %vec, ptr %vec.addr, align 8
  store i32 %idx, ptr %idx.addr, align 4
  %0 = load i32, ptr %idx.addr, align 4
  %sub = sub nsw i32 0, %0
  %1 = load ptr, ptr %vec.addr, align 8
  %2 = load i32, ptr %idx.addr, align 4
  %idxprom = sext i32 %2 to i64
  %arrayidx = getelementptr inbounds i32, ptr %1, i64 %idxprom
  store i32 %sub, ptr %arrayidx, align 4
  %3 = load i32, ptr %idx.addr, align 4
  ret i32 %3
}

; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @test_func_64(ptr noundef %vec, i64 noundef %idx) #0 {
entry:
; CHECK-LABEL: test_func_64:
; CHECK: stxdw [r10 - 16], r2
; CHECK: sub64 r2, 0
; CHECK: stxdw [r1 + 0], r2
  %vec.addr = alloca ptr, align 8
  %idx.addr = alloca i64, align 8
  store ptr %vec, ptr %vec.addr, align 8
  store i64 %idx, ptr %idx.addr, align 8
  %0 = load i64, ptr %idx.addr, align 8
  %sub = sub nsw i64 0, %0
  %1 = load ptr, ptr %vec.addr, align 8
  %2 = load i64, ptr %idx.addr, align 8
  %arrayidx = getelementptr inbounds i64, ptr %1, i64 %2
  store i64 %sub, ptr %arrayidx, align 8
  %3 = load i64, ptr %idx.addr, align 8
  %conv = trunc i64 %3 to i32
  ret i32 %conv
}