; RUN: llc -march=sbf -mcpu=sbfv2 -mattr=+alu32 < %s | FileCheck --check-prefix=CHECK-v2 %s
; RUN: llc -march=sbf -mattr=+alu32 < %s | FileCheck --check-prefix=CHECK-v1 %s

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i64 @test_pqr_unsigned(i64 noundef %a, i64 noundef %b) local_unnamed_addr #0 {
entry:
  %div1 = udiv i64 %a, %b
  %div2 = udiv i64 %b, 7
  %rem1 = urem i64 %a, %b
  %rem2 = urem i64 %b, 17

; CHECK-v2: urem64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v2: udiv64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v2: urem64 r{{[0-9]+}}, 17
; CHECK-v2: udiv64 r{{[0-9]+}}, 7
; CHECK-v2: lmul64 r{{[0-9]+}}, r2
; CHECK-V2: lmul64 r{{[0-9]+}}, 7

; CHECK-v1: div64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: mul64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: sub64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: add64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: div64 r{{[0-9]+}}, 17
; CHECK-v1: mul64 r{{[0-9]+}}, 17
; CHECK-v1: mov64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: sub64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: div64 r{{[0-9]+}}, 7
; CHECK-v1: mul64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v1: mul64 r{{[0-9]+}}, 7

  %add1 = add i64 %div1, %rem1
  %add2 = add i64 %div2, %rem2

  %mul1 = mul i64 %add1, %add2
  %mul2 = mul i64 %mul1, 7
  ret i64 %mul2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i64 @test_pqr_signed(i64 noundef %a, i64 noundef %b) local_unnamed_addr #0 {
entry:
  %div1 = sdiv i64 %a, %b
  %div2 = sdiv i64 %b, 7
  %rem1 = srem i64 %a, %b
  %rem2 = srem i64 %b, 17

; CHECK-v2: srem64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v2: sdiv64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v2: srem64 r{{[0-9]+}}, 17
; CHECK-v2: sdiv64 r{{[0-9]+}}, 7
; CHECK-v2: lmul64 r{{[0-9]+}}, r2
; CHECK-v2: lmul64 r{{[0-9]+}}, 7

; CHECK-v1: call __divdi3
; CHECK-v1: call __moddi3
; CHECK-v1: call __divdi3
; CHECK-v1: call __moddi3

  %add1 = add i64 %div1, %rem1
  %add2 = add i64 %div2, %rem2

  %mul1 = mul i64 %add1, %add2
  %mul2 = mul i64 %mul1, 7
  ret i64 %mul2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i32 @test_pqr_unsigned_32(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
  %div1 = udiv i32 %a, %b
  %div2 = udiv i32 %b, 7
  %rem1 = urem i32 %a, %b
  %rem2 = urem i32 %b, 17

; CHECK-v2: urem32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v2: udiv32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v2: urem32 w{{[0-9]+}}, 17
; CHECK-v2: udiv32 w{{[0-9]+}}, 7
; CHECK-v2: lmul32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v2: lmul32 w{{[0-9]+}}, 7

; CHECK-v1: div32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: mul32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: sub32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: add32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: div32 w{{[0-9]+}}, 17
; CHECK-v1: mul32 w{{[0-9]+}}, 17
; CHECK-v1: mov32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: sub32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: div32 w{{[0-9]+}}, 7
; CHECK-v1: add32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: mul32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v1: mul32 w{{[0-9]+}}, 7

  %add1 = add i32 %div1, %rem1
  %add2 = add i32 %div2, %rem2

  %mul1 = mul i32 %add1, %add2
  %mul2 = mul i32 %mul1, 7
  ret i32 %mul2
}

; Function Attrs: mustprogress nofree norecurse nosync nounwind willreturn memory(none)
define dso_local i32 @test_pqr_signed_32(i32 noundef %a, i32 noundef %b) local_unnamed_addr #0 {
entry:
  %div1 = sdiv i32 %a, %b
  %div2 = sdiv i32 %b, 7
  %rem1 = srem i32 %a, %b
  %rem2 = srem i32 %b, 17

; CHECK-v2: srem32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v2: sdiv32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v2: srem32 w{{[0-9]+}}, 17
; CHECK-v2: sdiv32 w{{[0-9]+}}, 7
; CHECK-v2: lmul32 w{{[0-9]+}}, w{{[0-9]+}}
; CHECK-v2: lmul32 w{{[0-9]+}}, 7

; CHECK-v1: call __divsi3
; CHECK-v1: call __modsi3
; CHECK-v1: call __divsi3
; CHECK-v1: call __modsi3

  %add1 = add i32 %div1, %rem1
  %add2 = add i32 %div2, %rem2

  %mul1 = mul i32 %add1, %add2
  %mul2 = mul i32 %mul1, 7
  ret i32 %mul2
}


; int64_t try_mul(int64_t a, int64_t b) {
;    int64_t c = (a * (unsigned __int128)b) >> 64;
;    int64_t d = (73 * (unsigned __int128)b) >> 64;
;    return c+d;
;  }

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define i64 @uhmul(i64 noundef %a, i64 noundef %b) local_unnamed_addr #0 {
entry:
  %conv = zext i64 %a to i128
  %conv1 = zext i64 %b to i128
  %mul = mul nuw i128 %conv1, %conv
  %shr = lshr i128 %mul, 64
  %conv2 = trunc i128 %shr to i64
  %mul4 = mul nuw nsw i128 %conv1, 73
  %shr5 = lshr i128 %mul4, 64
  %conv6 = trunc i128 %shr5 to i64
  %add = add i64 %conv2, %conv6
  ret i64 %add

; CHECK-v2: uhmul64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v2: uhmul64 r{{[0-9]+}}, 73

; CHECK-v1: call __multi3
; CHECK-v1: call __multi3

}

; uint64_t try_mul(int64_t a, int64_t b) {
;    uint64_t c = (a * (unsigned __int128)b) >> 64;
;    uint64_t d = (73 * (unsigned __int128)b) >> 64;
;    return c+d;
;  }

; Function Attrs: mustprogress nofree norecurse nosync nounwind ssp willreturn memory(none) uwtable(sync)
define i64 @shmul(i64 noundef %a, i64 noundef %b) local_unnamed_addr #0 {
entry:
  %conv = sext i64 %a to i128
  %conv1 = sext i64 %b to i128
  %mul = mul nsw i128 %conv1, %conv
  %shr = lshr i128 %mul, 64
  %conv2 = trunc i128 %shr to i64
  %mul4 = mul nsw i128 %conv1, 73
  %shr5 = lshr i128 %mul4, 64
  %conv6 = trunc i128 %shr5 to i64
  %add = add nsw i64 %conv2, %conv6
  ret i64 %add

; CHECK-v2: shmul64 r{{[0-9]+}}, r{{[0-9]+}}
; CHECK-v2: shmul64 r{{[0-9]+}}, 73

; CHECK-v1: call __multi3
; CHECK-v1: call __multi3

}


attributes #0 = { mustprogress nofree norecurse nosync nounwind willreturn memory(none) "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-features"="+solana" }

!llvm.module.flags = !{!0, !1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"frame-pointer", i32 2}
!2 = !{!"clang version 16.0.5 (https://github.com/solana-labs/llvm-project.git abdbb6e4ef63f7b5b4ee40d2770ed0fca909c2dc)"}
