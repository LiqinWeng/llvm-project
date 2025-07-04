; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=riscv32 -mattr=+d -verify-machineinstrs < %s \
; RUN:   -target-abi=ilp32d | FileCheck %s
; RUN: llc -mtriple=riscv64 -mattr=+d -verify-machineinstrs < %s \
; RUN:   -target-abi=lp64d | FileCheck %s
; RUN: llc -mtriple=riscv32 -mattr=+zdinx -verify-machineinstrs < %s \
; RUN:   -target-abi=ilp32 | FileCheck --check-prefix=CHECKRV32ZDINX %s
; RUN: llc -mtriple=riscv64 -mattr=+zdinx -verify-machineinstrs < %s \
; RUN:   -target-abi=lp64 | FileCheck --check-prefix=CHECKRV64ZDINX %s

define double @select_fcmp_false(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_false:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_false:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_false:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp false double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_oeq(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_oeq:
; CHECK:       # %bb.0:
; CHECK-NEXT:    feq.d a0, fa0, fa1
; CHECK-NEXT:    bnez a0, .LBB1_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB1_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_oeq:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    feq.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB1_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB1_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_oeq:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    feq.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB1_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB1_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp oeq double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ogt(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ogt:
; CHECK:       # %bb.0:
; CHECK-NEXT:    flt.d a0, fa1, fa0
; CHECK-NEXT:    bnez a0, .LBB2_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB2_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ogt:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    flt.d a4, a2, a0
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB2_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB2_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ogt:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    flt.d a2, a1, a0
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB2_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB2_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ogt double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_oge(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_oge:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fle.d a0, fa1, fa0
; CHECK-NEXT:    bnez a0, .LBB3_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB3_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_oge:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    fle.d a4, a2, a0
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB3_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB3_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_oge:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    fle.d a2, a1, a0
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB3_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB3_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp oge double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_olt(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_olt:
; CHECK:       # %bb.0:
; CHECK-NEXT:    flt.d a0, fa0, fa1
; CHECK-NEXT:    bnez a0, .LBB4_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB4_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_olt:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    flt.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB4_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB4_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_olt:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    flt.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB4_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB4_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp olt double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ole(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ole:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fle.d a0, fa0, fa1
; CHECK-NEXT:    bnez a0, .LBB5_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB5_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ole:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    fle.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB5_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB5_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ole:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    fle.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB5_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB5_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ole double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_one(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_one:
; CHECK:       # %bb.0:
; CHECK-NEXT:    flt.d a0, fa0, fa1
; CHECK-NEXT:    flt.d a1, fa1, fa0
; CHECK-NEXT:    or a0, a1, a0
; CHECK-NEXT:    bnez a0, .LBB6_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB6_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_one:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    flt.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    flt.d a5, a2, a0
; CHECKRV32ZDINX-NEXT:    or a4, a5, a4
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB6_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB6_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_one:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    flt.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    flt.d a3, a1, a0
; CHECKRV64ZDINX-NEXT:    or a2, a3, a2
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB6_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB6_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp one double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ord(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ord:
; CHECK:       # %bb.0:
; CHECK-NEXT:    feq.d a0, fa1, fa1
; CHECK-NEXT:    feq.d a1, fa0, fa0
; CHECK-NEXT:    and a0, a1, a0
; CHECK-NEXT:    bnez a0, .LBB7_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB7_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ord:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    feq.d a4, a2, a2
; CHECKRV32ZDINX-NEXT:    feq.d a5, a0, a0
; CHECKRV32ZDINX-NEXT:    and a4, a5, a4
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB7_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB7_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ord:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    feq.d a2, a1, a1
; CHECKRV64ZDINX-NEXT:    feq.d a3, a0, a0
; CHECKRV64ZDINX-NEXT:    and a2, a3, a2
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB7_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB7_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ord double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ueq(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ueq:
; CHECK:       # %bb.0:
; CHECK-NEXT:    flt.d a0, fa0, fa1
; CHECK-NEXT:    flt.d a1, fa1, fa0
; CHECK-NEXT:    or a0, a1, a0
; CHECK-NEXT:    beqz a0, .LBB8_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB8_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ueq:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    flt.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    flt.d a5, a2, a0
; CHECKRV32ZDINX-NEXT:    or a4, a5, a4
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB8_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB8_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ueq:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    flt.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    flt.d a3, a1, a0
; CHECKRV64ZDINX-NEXT:    or a2, a3, a2
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB8_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB8_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ueq double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ugt(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ugt:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fle.d a0, fa0, fa1
; CHECK-NEXT:    beqz a0, .LBB9_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB9_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ugt:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    fle.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB9_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB9_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ugt:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    fle.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB9_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB9_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ugt double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_uge(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_uge:
; CHECK:       # %bb.0:
; CHECK-NEXT:    flt.d a0, fa0, fa1
; CHECK-NEXT:    beqz a0, .LBB10_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB10_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_uge:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    flt.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB10_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB10_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_uge:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    flt.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB10_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB10_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp uge double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ult(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ult:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fle.d a0, fa1, fa0
; CHECK-NEXT:    beqz a0, .LBB11_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB11_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ult:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    fle.d a4, a2, a0
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB11_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB11_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ult:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    fle.d a2, a1, a0
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB11_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB11_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ult double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_ule(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_ule:
; CHECK:       # %bb.0:
; CHECK-NEXT:    flt.d a0, fa1, fa0
; CHECK-NEXT:    beqz a0, .LBB12_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB12_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_ule:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    flt.d a4, a2, a0
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB12_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB12_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_ule:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    flt.d a2, a1, a0
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB12_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB12_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ule double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_une(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_une:
; CHECK:       # %bb.0:
; CHECK-NEXT:    feq.d a0, fa0, fa1
; CHECK-NEXT:    beqz a0, .LBB13_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB13_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_une:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    feq.d a4, a0, a2
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB13_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB13_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_une:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    feq.d a2, a0, a1
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB13_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB13_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp une double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_uno(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_uno:
; CHECK:       # %bb.0:
; CHECK-NEXT:    feq.d a0, fa1, fa1
; CHECK-NEXT:    feq.d a1, fa0, fa0
; CHECK-NEXT:    and a0, a1, a0
; CHECK-NEXT:    beqz a0, .LBB14_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    fmv.d fa0, fa1
; CHECK-NEXT:  .LBB14_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_uno:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    feq.d a4, a2, a2
; CHECKRV32ZDINX-NEXT:    feq.d a5, a0, a0
; CHECKRV32ZDINX-NEXT:    and a4, a5, a4
; CHECKRV32ZDINX-NEXT:    beqz a4, .LBB14_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:  .LBB14_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_uno:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    feq.d a2, a1, a1
; CHECKRV64ZDINX-NEXT:    feq.d a3, a0, a0
; CHECKRV64ZDINX-NEXT:    and a2, a3, a2
; CHECKRV64ZDINX-NEXT:    beqz a2, .LBB14_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:  .LBB14_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp uno double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

define double @select_fcmp_true(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_true:
; CHECK:       # %bb.0:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_true:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_true:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp true double %a, %b
  %2 = select i1 %1, double %a, double %b
  ret double %2
}

; Ensure that ISel succeeds for a select+fcmp that has an i32 result type.
define i32 @i32_select_fcmp_oeq(double %a, double %b, i32 %c, i32 %d) nounwind {
; CHECK-LABEL: i32_select_fcmp_oeq:
; CHECK:       # %bb.0:
; CHECK-NEXT:    feq.d a2, fa0, fa1
; CHECK-NEXT:    bnez a2, .LBB16_2
; CHECK-NEXT:  # %bb.1:
; CHECK-NEXT:    mv a0, a1
; CHECK-NEXT:  .LBB16_2:
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: i32_select_fcmp_oeq:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    feq.d a1, a0, a2
; CHECKRV32ZDINX-NEXT:    mv a0, a4
; CHECKRV32ZDINX-NEXT:    bnez a1, .LBB16_2
; CHECKRV32ZDINX-NEXT:  # %bb.1:
; CHECKRV32ZDINX-NEXT:    mv a0, a5
; CHECKRV32ZDINX-NEXT:  .LBB16_2:
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: i32_select_fcmp_oeq:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    feq.d a1, a0, a1
; CHECKRV64ZDINX-NEXT:    mv a0, a2
; CHECKRV64ZDINX-NEXT:    bnez a1, .LBB16_2
; CHECKRV64ZDINX-NEXT:  # %bb.1:
; CHECKRV64ZDINX-NEXT:    mv a0, a3
; CHECKRV64ZDINX-NEXT:  .LBB16_2:
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp oeq double %a, %b
  %2 = select i1 %1, i32 %c, i32 %d
  ret i32 %2
}

define i32 @select_fcmp_oeq_1_2(double %a, double %b) {
; CHECK-LABEL: select_fcmp_oeq_1_2:
; CHECK:       # %bb.0:
; CHECK-NEXT:    feq.d a0, fa0, fa1
; CHECK-NEXT:    li a1, 2
; CHECK-NEXT:    sub a0, a1, a0
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_oeq_1_2:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    li a4, 2
; CHECKRV32ZDINX-NEXT:    feq.d a0, a0, a2
; CHECKRV32ZDINX-NEXT:    sub a0, a4, a0
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_oeq_1_2:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    feq.d a0, a0, a1
; CHECKRV64ZDINX-NEXT:    li a1, 2
; CHECKRV64ZDINX-NEXT:    sub a0, a1, a0
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp fast oeq double %a, %b
  %2 = select i1 %1, i32 1, i32 2
  ret i32 %2
}

define signext i32 @select_fcmp_uge_negone_zero(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_uge_negone_zero:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fle.d a0, fa0, fa1
; CHECK-NEXT:    addi a0, a0, -1
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_uge_negone_zero:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    fle.d a0, a0, a2
; CHECKRV32ZDINX-NEXT:    addi a0, a0, -1
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_uge_negone_zero:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    fle.d a0, a0, a1
; CHECKRV64ZDINX-NEXT:    addi a0, a0, -1
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ugt double %a, %b
  %2 = select i1 %1, i32 -1, i32 0
  ret i32 %2
}

define signext i32 @select_fcmp_uge_1_2(double %a, double %b) nounwind {
; CHECK-LABEL: select_fcmp_uge_1_2:
; CHECK:       # %bb.0:
; CHECK-NEXT:    fle.d a0, fa0, fa1
; CHECK-NEXT:    addi a0, a0, 1
; CHECK-NEXT:    ret
;
; CHECKRV32ZDINX-LABEL: select_fcmp_uge_1_2:
; CHECKRV32ZDINX:       # %bb.0:
; CHECKRV32ZDINX-NEXT:    fle.d a0, a0, a2
; CHECKRV32ZDINX-NEXT:    addi a0, a0, 1
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: select_fcmp_uge_1_2:
; CHECKRV64ZDINX:       # %bb.0:
; CHECKRV64ZDINX-NEXT:    fle.d a0, a0, a1
; CHECKRV64ZDINX-NEXT:    addi a0, a0, 1
; CHECKRV64ZDINX-NEXT:    ret
  %1 = fcmp ugt double %a, %b
  %2 = select i1 %1, i32 1, i32 2
  ret i32 %2
}

define double @CascadedSelect(double noundef %a) {
; CHECKRV32ZDINX-LABEL: CascadedSelect:
; CHECKRV32ZDINX:       # %bb.0: # %entry
; CHECKRV32ZDINX-NEXT:    lui a3, %hi(.LCPI20_0)
; CHECKRV32ZDINX-NEXT:    lw a2, %lo(.LCPI20_0)(a3)
; CHECKRV32ZDINX-NEXT:    addi a3, a3, %lo(.LCPI20_0)
; CHECKRV32ZDINX-NEXT:    lw a3, 4(a3)
; CHECKRV32ZDINX-NEXT:    flt.d a4, a2, a0
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB20_3
; CHECKRV32ZDINX-NEXT:  # %bb.1: # %entry
; CHECKRV32ZDINX-NEXT:    flt.d a4, a0, zero
; CHECKRV32ZDINX-NEXT:    li a2, 0
; CHECKRV32ZDINX-NEXT:    li a3, 0
; CHECKRV32ZDINX-NEXT:    bnez a4, .LBB20_3
; CHECKRV32ZDINX-NEXT:  # %bb.2: # %entry
; CHECKRV32ZDINX-NEXT:    mv a2, a0
; CHECKRV32ZDINX-NEXT:    mv a3, a1
; CHECKRV32ZDINX-NEXT:  .LBB20_3: # %entry
; CHECKRV32ZDINX-NEXT:    mv a0, a2
; CHECKRV32ZDINX-NEXT:    mv a1, a3
; CHECKRV32ZDINX-NEXT:    ret
;
; CHECKRV64ZDINX-LABEL: CascadedSelect:
; CHECKRV64ZDINX:       # %bb.0: # %entry
; CHECKRV64ZDINX-NEXT:    li a1, 1023
; CHECKRV64ZDINX-NEXT:    slli a1, a1, 52
; CHECKRV64ZDINX-NEXT:    flt.d a2, a1, a0
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB20_3
; CHECKRV64ZDINX-NEXT:  # %bb.1: # %entry
; CHECKRV64ZDINX-NEXT:    flt.d a2, a0, zero
; CHECKRV64ZDINX-NEXT:    li a1, 0
; CHECKRV64ZDINX-NEXT:    bnez a2, .LBB20_3
; CHECKRV64ZDINX-NEXT:  # %bb.2: # %entry
; CHECKRV64ZDINX-NEXT:    mv a1, a0
; CHECKRV64ZDINX-NEXT:  .LBB20_3: # %entry
; CHECKRV64ZDINX-NEXT:    mv a0, a1
; CHECKRV64ZDINX-NEXT:    ret
entry:
  %cmp = fcmp ogt double %a, 1.000000e+00
  %cmp1 = fcmp olt double %a, 0.000000e+00
  %.a = select i1 %cmp1, double 0.000000e+00, double %a
  %retval.0 = select i1 %cmp, double 1.000000e+00, double %.a
  ret double %retval.0
}
