; RUN: llc < %s -march=sbf --show-mc-encoding | FileCheck --check-prefix=CHECK-ASM %s
; RUN: llc -march=sbf --filetype=obj -o - %s | llvm-objdump -d - | FileCheck --check-prefix=CHECK-OBJ %s
; RUN: llc < %s -march=sbf -mcpu=sbfv2 --show-mc-encoding | FileCheck --check-prefix=CHECK-ASM %s
; RUN: llc -march=sbf -mcpu=sbfv2 --filetype=obj -o - %s | llvm-objdump -d -
;                                       | FileCheck --check-prefix=CHECK-OBJ %s

@.str = private unnamed_addr constant [5 x i8] c"foo\0A\00", align 1

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define dso_local i64 @sum(i64 noundef %a, i64 noundef %b) local_unnamed_addr #0 {
entry:
  %add = add i64 %b, %a
  ret i64 %add
}

; Function Attrs: nounwind
define dso_local i64 @entrypoint(ptr noundef %input) local_unnamed_addr #1 {
entry:
; CHECK-ASM: call 1811268606      # encoding: [0x85,0x00,0x00,0x00,0xfe,0xc3,0xf5,0x6b]
; CHECK-OBJ: 85 00 00 00 fe c3 f5 6b	call 0x6bf5c3fe

  tail call void inttoptr (i64 1811268606 to ptr)(ptr noundef nonnull @.str, i64 noundef 4) #3
  %add.ptr = getelementptr inbounds i8, ptr %input, i64 4

; CHECK-ASM: call invoke_c        # encoding: [0x85'A',A,A,A,0x00,0x00,0x00,0x00]
; CHECK-ASM: fixup A - offset: 0, value: invoke_c, kind: FK_PCRel_4
; CHECK-OBJ: 85 10 00 00 ff ff ff ff	call -0x1

  tail call void @invoke_c(ptr noundef %input) #3
  %0 = load i64, ptr %input, align 8, !tbaa !3
  %1 = load i64, ptr %add.ptr, align 8, !tbaa !3

; CHECK-ASM: call sum             # encoding: [0x85'A',A,A,A,0x00,0x00,0x00,0x00]
; CHECK-ASM: fixup A - offset: 0, value: sum, kind: FK_PCRel_4
; CHECK-OBJ: 85 10 00 00 ff ff ff ff	call -0x1

  %call = tail call i64 @sum(i64 noundef %0, i64 noundef %1)
  ret i64 %call
}

declare dso_local void @invoke_c(ptr noundef) local_unnamed_addr #2


!3 = !{!4, !4, i64 0}
!4 = !{!"long", !5, i64 0}
!5 = !{!"omnipotent char"}