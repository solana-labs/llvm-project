; RUN: llc < %s -march=sbf -mcpu=v3 -verify-machineinstrs | tee -i /tmp/log | FileCheck %s
;
; CHECK-LABEL: test_load_add_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: w3 += w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_load_add_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw add i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_load_add_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: r3 += r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i32 @test_load_add_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw add i64* %p, i64 %v seq_cst
  %conv = trunc i64 %0 to i32
  ret i32 %conv
}

; CHECK-LABEL: test_load_sub_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: w3 -= w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_load_sub_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw sub i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_load_sub_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: r3 -= r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i32 @test_load_sub_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw sub i64* %p, i64 %v seq_cst
  %conv = trunc i64 %0 to i32
  ret i32 %conv
}

; CHECK-LABEL: test_xchg_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: *(u32 *)(r1 + 0) = w2
define dso_local i32 @test_xchg_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw xchg i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_xchg_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: *(u64 *)(r1 + 0) = r2
define dso_local i32 @test_xchg_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw xchg i64* %p, i64 %v seq_cst
  %conv = trunc i64 %0 to i32
  ret i32 %conv
}

; CHECK-LABEL: test_cas_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: if w0 == w2 goto
; CHECK: w3 = w0
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_cas_32(i32* nocapture %p, i32 %old, i32 %new) local_unnamed_addr {
entry:
  %0 = cmpxchg i32* %p, i32 %old, i32 %new seq_cst seq_cst
  %1 = extractvalue { i32, i1 } %0, 0
  ret i32 %1
}

; CHECK-LABEL: test_cas_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: if r0 == r2 goto
; CHECK: r3 = r0
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i64 @test_cas_64(i64* nocapture %p, i64 %old, i64 %new) local_unnamed_addr {
entry:
  %0 = cmpxchg i64* %p, i64 %old, i64 %new seq_cst seq_cst
  %1 = extractvalue { i64, i1 } %0, 0
  ret i64 %1
}

; CHECK-LABEL: test_load_and_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: w3 &= w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_load_and_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw and i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_load_and_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: r3 &= r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i64 @test_load_and_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw and i64* %p, i64 %v seq_cst
  ret i64 %0
}

; CHECK-LABEL: test_load_nand_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: w3 &= w2
; CHECK: w3 ^= -1
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_load_nand_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw nand i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_load_nand_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: r3 &= r2
; CHECK: r3 ^= -1
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i64 @test_load_nand_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw nand i64* %p, i64 %v seq_cst
  ret i64 %0
}

; CHECK-LABEL: test_load_or_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: w3 |= w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_load_or_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw or i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_load_or_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: r3 |= r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i64 @test_load_or_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw or i64* %p, i64 %v seq_cst
  ret i64 %0
}

; CHECK-LABEL: test_load_xor_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: w3 ^= w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_load_xor_32(i32* nocapture %p, i32 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw xor i32* %p, i32 %v seq_cst
  ret i32 %0
}

; CHECK-LABEL: test_load_xor_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: r3 ^= r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local i64 @test_load_xor_64(i64* nocapture %p, i64 %v) local_unnamed_addr {
entry:
  %0 = atomicrmw xor i64* %p, i64 %v seq_cst
  ret i64 %0
}

; CHECK-LABEL: test_min_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: if w0 s< w2 goto
; CHECK: w3 = w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local i32 @test_min_32(i32* nocapture %ptr, i32 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw min i32* %ptr, i32 %v release, align 1
  ret i32 %0
}

; CHECK-LABEL: test_min_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: if r0 s< r2 goto
; CHECK: r3 = r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local  i64 @test_min_64(i64* nocapture %ptr, i64 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw min i64* %ptr, i64 %v release, align 1
  ret i64 %0
}

; CHECK-LABEL: test_max_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: if w0 s> w2 goto
; CHECK: w3 = w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local  i32 @test_max_32(i32* nocapture %ptr, i32 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw max i32* %ptr, i32 %v release, align 1
  ret i32 %0
}

; CHECK-LABEL: test_max_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: if r0 s> r2 goto
; CHECK: r3 = r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local  i64 @test_max_64(i64* nocapture %ptr, i64 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw max i64* %ptr, i64 %v release, align 1
  ret i64 %0
}

; CHECK-LABEL: test_umin_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: if w0 < w2 goto
; CHECK: w3 = w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local  i32 @test_umin_32(i32* nocapture %ptr, i32 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw umin i32* %ptr, i32 %v release, align 1
  ret i32 %0
}

; CHECK-LABEL: test_umin_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: if r0 < r2 goto
; CHECK: r3 = r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local  i64 @test_umin_64(i64* nocapture %ptr, i64 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw umin i64* %ptr, i64 %v release, align 1
  ret i64 %0
}

; CHECK-LABEL: test_umax_32
; CHECK: w0 = *(u32 *)(r1 + 0)
; CHECK: w3 = w0
; CHECK: if w0 > w2 goto
; CHECK: w3 = w2
; CHECK: *(u32 *)(r1 + 0) = w3
define dso_local  i32 @test_umax_32(i32* nocapture %ptr, i32 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw umax i32* %ptr, i32 %v release, align 1
  ret i32 %0
}

; CHECK-LABEL: test_umax_64
; CHECK: r0 = *(u64 *)(r1 + 0)
; CHECK: r3 = r0
; CHECK: if r0 > r2 goto
; CHECK: r3 = r2
; CHECK: *(u64 *)(r1 + 0) = r3
define dso_local  i64 @test_umax_64(i64* nocapture %ptr, i64 %v) local_unnamed_addr #0 {
entry:
  %0 = atomicrmw umax i64* %ptr, i64 %v release, align 1
  ret i64 %0
}
