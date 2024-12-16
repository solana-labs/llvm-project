; RUN: llc < %s -march=sbf -sbf-expand-memcpy-in-order | FileCheck %s
; RUN: llc < %s -march=sbf -sbf-expand-memcpy-in-order -mattr=+mem-encoding | FileCheck %s

; Function Attrs: mustprogress nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias nocapture writeonly, ptr noalias nocapture readonly, i64, i1 immarg) #1

define void @memcpy_test_1(ptr align 16 %a, ptr align 16 %b) local_unnamed_addr #0 {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %a, ptr align 16 %b, i64 32, i1 0)

;  4 pairs of loads and stores
; CHECK: memcpy_test_1
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 0]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 0], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 8]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 8], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 16]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 16], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 24]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 24], [[SCRATCH_REG:r[0-9]]]
  ret void
}

define void @memcpy_test_2(ptr align 16 %a, ptr align 16 %b) local_unnamed_addr #0 {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %a, ptr align 16 %b, i64 17, i1 0)

; 2 pairs of loads and stores + 1 pair for the byte
; CHECK: memcpy_test_2
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 0]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 0], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 8]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 8], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxb [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 16]
; CHECK: stxb [[[DST_REG:r[0-9]]] + 16], [[SCRATCH_REG:r[0-9]]]
  ret void
}

define void @memcpy_test_3(ptr align 16 %a, ptr align 16 %b) local_unnamed_addr #0 {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %a, ptr align 16 %b, i64 18, i1 0)

; 2 pairs of loads and stores + 1 pair for the 2 bytes
; CHECK: memcpy_test_3
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 0]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 0], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 8]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 8], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxh [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 16]
; CHECK: stxh [[[DST_REG:r[0-9]]] + 16], [[SCRATCH_REG:r[0-9]]]
  ret void
}

define void @memcpy_test_4(ptr align 16 %a, ptr align 16 %b) local_unnamed_addr #0 {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %a, ptr align 16 %b, i64 19, i1 0)

; 2 pairs of loads and stores + 1 pair for the 3 bytes
; CHECK: memcpy_test_4
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 0]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 0], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 8]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 8], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 15]
; CHECK: stxw [[[DST_REG:r[0-9]]] + 15], [[SCRATCH_REG:r[0-9]]]
  ret void
}

define void @memcpy_test_5(ptr align 16 %a, ptr align 16 %b) local_unnamed_addr #0 {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %a, ptr align 16 %b, i64 21, i1 0)

; 2 pairs of loads and stores + 1 pair for the 5 bytes
; CHECK: memcpy_test_5
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 0]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 0], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 8]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 8], [[SCRATCH_REG:r[0-9]]]
; CHECK: ldxdw [[SCRATCH_REG:r[0-9]]], [[[SRC_REG:r[0-9]]] + 13]
; CHECK: stxdw [[[DST_REG:r[0-9]]] + 13], [[SCRATCH_REG:r[0-9]]]
  ret void
}

define void @memcpy_test_6(ptr align 16 %a, ptr align 16 %b) local_unnamed_addr #0 {
entry:
  call void @llvm.memcpy.p0.p0.i64(ptr align 16 %a, ptr align 16 %b, i64 33, i1 0)

; More than 32 bytes, call memcpy
; CHECK: memcpy_test_6
; CHECK: mov64 r3, 33
; CHECK: call memcpy
  ret void
}