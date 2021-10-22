; RUN: llc -O2 -march=bpfel --mattr=+solana -filetype=asm < %s | FileCheck --check-prefix=CHECK %s

%Pool = type <{ [0 x i8], [32 x i8], [0 x i8], i8, [0 x i8], [10 x %Decimal], [0 x i8] }>
%Decimal = type { [0 x i32], i32, [0 x i32], i32, [0 x i32], i32, [0 x i32], i32, [0 x i32] }

@0 = private unnamed_addr constant <{ [16 x i8] }> <{ [16 x i8] c"\00\00\00\00\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF\FF" }>, align 4

declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #5

; optbug::Pool::initialize
; Function Attrs: nofree noinline nounwind willreturn
define internal fastcc void @_ZN6optbug4Pool10initialize17h656ab4e5f05591beE(%Pool* noalias nocapture align 1 dereferenceable(193) %self, [32 x i8]* noalias nocapture readonly align 1 dereferenceable(32) %seed, i8 %bump) unnamed_addr #2 {
start:
  %0 = getelementptr inbounds [32 x i8], [32 x i8]* %seed, i64 0, i64 0
  %self56 = getelementptr inbounds %Pool, %Pool* %self, i64 0, i32 0, i64 0
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 1 dereferenceable(32) %self56, i8* nonnull align 1 dereferenceable(32) %0, i64 32, i1 false)
  %1 = getelementptr inbounds %Pool, %Pool* %self, i64 0, i32 3
  store i8 %bump, i8* %1, align 1
  %2 = getelementptr inbounds %Pool, %Pool* %self, i64 0, i32 5, i64 1
  %3 = bitcast %Decimal* %2 to i8*
  tail call void @llvm.memcpy.p0i8.p0i8.i64(i8* nonnull align 1 dereferenceable(16) %3, i8* nonnull align 4 dereferenceable(16) getelementptr inbounds (<{ [16 x i8] }>, <{ [16 x i8] }>* @0, i64 0, i32 0, i64 0), i64 16, i1 false)
  ret void
}

; CHECK: *(u64 *)(r1 + 24) = r4
; CHECK: *(u64 *)(r1 + 16) = r4
; CHECK: *(u64 *)(r1 + 8) = r4
; CHECK: *(u64 *)(r1 + 0) = r2
; CHECK: *(u8 *)(r1 + 32) = r3

attributes #2 = { nofree noinline nounwind willreturn "target-cpu"="generic" }

!llvm.module.flags = !{!0}

!0 = !{i32 7, !"PIC Level", i32 2}
