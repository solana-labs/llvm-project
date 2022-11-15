; RUN: llc < %s -march=sbf -verify-machineinstrs | FileCheck %s

@g = common global [2 x i32] zeroinitializer, align 4

; Function Attrs: nounwind
define i32 @test(i8* nocapture readnone %ctx) local_unnamed_addr #0 {
entry:
  %a = alloca i32, align 4
  %0 = bitcast i32* %a to i8*
  call void @llvm.lifetime.start.p0i8(i64 4, i8* nonnull %0) #2
  store i32 4, i32* %a, align 4
  tail call void asm sideeffect "ldabsh $0", "i"(i32 2) #2
; CHECK: ldabsh 2 
  tail call void asm sideeffect "ldindh $0", "r"(i32 4) #2
; CHECK: ldindh r1
  %1 = tail call i32 asm sideeffect "mov64 $0, $1", "=r,i"(i32 4) #2
; CHECK: mov64 r1, 4
  %2 = tail call i32 asm sideeffect "lddw $0, $1", "=r,i"(i64 333333333333) #2
; CHECK: lddw r1, 333333333333
  %3 = call i32 asm sideeffect "ldxh $0, [$1]", "=r,*m"(i32* elementtype(i32) nonnull %a) #2
; CHECK: ldxh r1, [r10 - 4]
  %4 = call i32 asm sideeffect "ldxw $0, [$1]", "=r,*m"(i32* elementtype(i32) getelementptr inbounds ([2 x i32], [2 x i32]* @g, i64 0, i64 1)) #2
; CHECK: lddw r1, g
; CHECK: ldxw r0, [r1 + 4]
  call void @llvm.lifetime.end.p0i8(i64 4, i8* nonnull %0) #2
  ret i32 %4
}

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture) #1

; Function Attrs: argmemonly nounwind
declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture) #1

attributes #0 = { nounwind }
attributes #1 = { argmemonly nounwind }
attributes #2 = { nounwind }
