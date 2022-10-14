; RUN: llc -march=sbf -filetype=obj -o - %s | llvm-objdump -d - | FileCheck %s

; CHECK-LABEL: test_load_add_32
; CHECK: r3 = *(u32 *)(r1 + 0)
; CHECK: r3 += r2
; CHECK: *(u32 *)(r1 + 0) = r3
define void @test_load_add_32(i32* %p, i32 zeroext %v) {
entry:
  atomicrmw add i32* %p, i32 %v seq_cst
  ret void
}

; CHECK-LABEL: test_load_add_64
; CHECK: r3 = *(u64 *)(r1 + 0)
; CHECK: r3 += r2
; CHECK: *(u64 *)(r1 + 0) = r3
define void @test_load_add_64(i64* %p, i64 zeroext %v) {
entry:
  atomicrmw add i64* %p, i64 %v seq_cst
  ret void
}
