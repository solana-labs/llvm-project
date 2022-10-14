; RUN: llc < %s -march=sbf | FileCheck %s

%struct.S = type { i32, i32, i32 }

@s = common global %struct.S zeroinitializer, align 4

; Function Attrs: nounwind readonly uwtable
define { i64, i32 } @bar(i32 %a, i32 %b, i32 %c, i32 %d, i32 %e) #0 {
; CHECK-LABEL: bar:
; CHECK: r2 = s ll
; CHECK: r3 = *(u32 *)(r2 + 8)
; CHECK: *(u32 *)(r1 + 8) = r3
; CHECK: r2 = *(u64 *)(r2 + 0)
; CHECK: *(u64 *)(r1 + 0) = r2
entry:
  %retval.sroa.0.0.copyload = load i64, i64* bitcast (%struct.S* @s to i64*), align 4
  %retval.sroa.2.0.copyload = load i32, i32* getelementptr inbounds (%struct.S, %struct.S* @s, i64 0, i32 2), align 4
  %.fca.0.insert = insertvalue { i64, i32 } undef, i64 %retval.sroa.0.0.copyload, 0
  %.fca.1.insert = insertvalue { i64, i32 } %.fca.0.insert, i32 %retval.sroa.2.0.copyload, 1
  ret { i64, i32 } %.fca.1.insert
}
