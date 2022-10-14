; RUN: llc < %s -march=sbf -mcpu=v2 -verify-machineinstrs | FileCheck %s
;
; Source file:
; int b, c;
; int test() {
;   int a = b;
;   if (a)
;     a = c;
;   return a;
; }
@b = common local_unnamed_addr global i32 0, align 4
@c = common local_unnamed_addr global i32 0, align 4

; Function Attrs: norecurse nounwind readonly
define i32 @test() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @b, align 4
  %tobool = icmp eq i32 %0, 0
  %1 = load i32, i32* @c, align 4
  %. = select i1 %tobool, i32 0, i32 %1
; CHECK:  r1 = b
; CHECK:  r1 = *(u32 *)(r1 + 0)
; CHECK:  if r1 == 0 goto
  ret i32 %.
}

attributes #0 = { norecurse nounwind readonly }

; Function Attrs: nounwind readonly
define i32 @foo(i64*) local_unnamed_addr #0 {
  %2 = load i64, i64* %0, align 8
  %3 = load i64, i64* %0, align 8
  %4 = add i64 %3, %2
  %5 = icmp ne i64 %4, 8589934591
; CHECK:  r{{[0-9]+}} = 8589934591 ll
  %6 = sext i1 %5 to i32
  ret i32 %6
}

; Function Attrs: nounwind readonly
declare i64 @llvm.bpf.load.word(i8*, i64) #1

; Source file:
; int m, n;
; int test2() {
;   int a = m;
;   if (a < 6)
;     a = n;
;   return a;
; }

@m = common local_unnamed_addr global i32 0, align 4
@n = common local_unnamed_addr global i32 0, align 4

; Function Attrs: norecurse nounwind readonly
define i32 @test2() local_unnamed_addr #0 {
entry:
  %0 = load i32, i32* @m, align 4
  %cmp = icmp slt i32 %0, 6
; CHECK:  if r{{[0-9]+}} s{{<|>}} 6 goto
  %1 = load i32, i32* @n, align 4
  %spec.select = select i1 %cmp, i32 %1, i32 %0
  ret i32 %spec.select
}

attributes #0 = { norecurse nounwind readonly }
