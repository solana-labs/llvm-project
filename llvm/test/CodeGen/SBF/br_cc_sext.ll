; RUN: llc -march=sbf -mattr=+alu32,+explicit-sext -verify-machineinstrs < %s | FileCheck %s

; ModuleID = 'test.c'
source_filename = "test.c"
target datalayout = "e-m:e-p:64:64-i64:64-n32:64-S128"
target triple = "sbf"

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local noundef i32 @doThis(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
  %rem = srem i32 %a, %b
  ret i32 %rem
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i32 @test_one(i32 noundef %a, i32 noundef %b, ptr %c) local_unnamed_addr #0 {
entry:
; Sign extension before comparison with immediate value
; CHECK-LABEL: test_one
; CHECK: mov32 r1, w1
; CHECK: jeq r1, -1, LBB1_2
  %ld = load i32, ptr %c, align 4
  %cmp = icmp ult i32 %ld, -1
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %add = add nsw i32 %a, 9
  br label %if.end

if.else:                                          ; preds = %entry
  %rem.i = srem i32 %b, %a
  %sub = sub nsw i32 9, %rem.i
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %f.0 = phi i32 [ %add, %if.then ], [ %sub, %if.else ]
  %add1 = add nsw i32 %f.0, 90
  ret i32 %add1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i32 @test_two(i32 noundef %a, i32 noundef %b, ptr %c) local_unnamed_addr #0 {
entry:
; Sign extension before comparison with immediate value
; CHECK-LABEL: test_two
; CHECK: mov32 r1, w1
; CHECK: jsgt r1, -2, LBB2_2
  %ld = load i32, ptr %c, align 4
  %cmp = icmp slt i32 %ld, -1
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %add = add nsw i32 %a, 9
  br label %if.end

if.else:                                          ; preds = %entry
  %rem.i = srem i32 %b, %a
  %sub = sub nsw i32 9, %rem.i
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %f.0 = phi i32 [ %add, %if.then ], [ %sub, %if.else ]
  %add1 = add nsw i32 %f.0, 90
  ret i32 %add1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i32 @test_three(i32 noundef %a, i32 noundef %b, ptr %c) local_unnamed_addr #0 {
entry:
; Sign extension for signed comparison
; CHECK-LABEL: test_three
; CHECK: mov32 r1, w2
; CHECK: ldxw w3, [r3 + 0]
; CHECK: mov32 r3, w3
; CHECK: jsge r3, r1, LBB3_2
  %ld = load i32, ptr %c, align 4
  %cmp = icmp slt i32 %ld, %b
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %add = add nsw i32 %a, 9
  br label %if.end

if.else:                                          ; preds = %entry
  %rem.i = srem i32 %b, %a
  %sub = sub nsw i32 9, %rem.i
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %f.0 = phi i32 [ %add, %if.then ], [ %sub, %if.else ]
  %add1 = add nsw i32 %f.0, 90
  ret i32 %add1
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i32 @test_four(i32 noundef %a, i32 noundef %b, ptr %c) local_unnamed_addr #0 {
entry:
; Zero extension for unsigned comparison
; CHECK-LABEL: test_four
; CHECK: mov64 w0, w1
; CHECK: ldxw w1, [r3 + 0]
; CHECK: jge r1, r2, LBB4_2
  %ld = load i32, ptr %c, align 4
  %cmp = icmp ult i32 %ld, %b
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %add = add nsw i32 %a, 9
  br label %if.end

if.else:                                          ; preds = %entry
  %rem.i = srem i32 %b, %a
  %sub = sub nsw i32 9, %rem.i
  br label %if.end

if.end:                                           ; preds = %if.else, %if.then
  %f.0 = phi i32 [ %add, %if.then ], [ %sub, %if.else ]
  %add1 = add nsw i32 %f.0, 90
  ret i32 %add1
}

attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+solana" }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{!"clang version 18.1.7 (https://github.com/solana-labs/llvm-project.git 9fd466387b898c6e320f31dbb8b7766507d1e6ae)"}
