; RUN: llc -march=sbf -filetype=obj < %s | llvm-objdump -r - | tee -i /tmp/foo | FileCheck --check-prefix=CHECK-RELOC-BPF %s
; RUN: llc -march=sbf -mcpu=sbfv2 -filetype=obj < %s | llvm-objdump -r - | tee -i /tmp/foo | FileCheck --check-prefix=CHECK-RELOC-SBFv2 %s

@.str = private unnamed_addr constant [25 x i8] c"reloc_64_relative_data.c\00", align 1
@FILE = dso_local constant i64 ptrtoint ([25 x i8]* @.str to i64), align 8

; Function Attrs: noinline nounwind optnone
define dso_local i64 @entrypoint(i8* %input) #0 {
entry:
  %input.addr = alloca i8*, align 8
  store i8* %input, i8** %input.addr, align 8
  %0 = load volatile i64, i64* @FILE, align 8
  ret i64 %0
}

; CHECK-RELOC-BPF:   RELOCATION RECORDS FOR [.data.rel.ro]:
; CHECK-RELOC-BPF:   0000000000000000 R_BPF_64_64 .L.str

; CHECK-RELOC-SBFv2: RELOCATION RECORDS FOR [.data.rel.ro]:
; CHECK-RELOC-SBFv2: 0000000000000000 R_SBF_64_ABS64 .L.str
