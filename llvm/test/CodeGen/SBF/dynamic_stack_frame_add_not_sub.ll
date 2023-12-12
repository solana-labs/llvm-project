; RUN: llc < %s -march=sbf --mattr=+dynamic-frames | FileCheck %s
;
; Source:
; int test_func(int * vec, int idx) {
;      vec[idx] = idx-1;
;      return idx;
;  }
; Compilation flag:
; clang -S -emit-llvm test.c


; Function Attrs: noinline nounwind optnone ssp uwtable(sync)
define i32 @test_func(ptr noundef %vec, i32 noundef %idx) #0 {
; CHECK-LABEL: test_func:
; CHECK: add64 r11, -16
; CHECK: add64 r11, 16
entry:
  %vec.addr = alloca ptr, align 8
  %idx.addr = alloca i32, align 4
  store ptr %vec, ptr %vec.addr, align 8
  store i32 %idx, ptr %idx.addr, align 4
  %0 = load i32, ptr %idx.addr, align 4
  %sub = sub nsw i32 %0, 1
  %1 = load ptr, ptr %vec.addr, align 8
  %2 = load i32, ptr %idx.addr, align 4
  %idxprom = sext i32 %2 to i64
  %arrayidx = getelementptr inbounds i32, ptr %1, i64 %idxprom
  store i32 %sub, ptr %arrayidx, align 4
  %3 = load i32, ptr %idx.addr, align 4
  ret i32 %3
}