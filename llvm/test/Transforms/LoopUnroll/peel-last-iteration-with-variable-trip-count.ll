; NOTE: Assertions have been autogenerated by utils/update_test_checks.py UTC_ARGS: --version 5
; RUN: opt -p loop-unroll -unroll-full-max-count=0 -S %s | FileCheck %s


declare void @foo(i32)

define i32 @peel_last_with_trip_count_check_lcssa_phi(i32 %n) {
; CHECK-LABEL: define i32 @peel_last_with_trip_count_check_lcssa_phi(
; CHECK-SAME: i32 [[N:%.*]]) {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[SUB:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, %[[ENTRY]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[IV]], [[SUB]]
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C]], i32 1, i32 2
; CHECK-NEXT:    call void @foo(i32 [[SEL]])
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[EC:%.*]] = icmp ne i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC]], label %[[LOOP]], label %[[EXIT:.*]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    [[SEL_LCSSA:%.*]] = phi i32 [ [[SEL]], %[[LOOP]] ]
; CHECK-NEXT:    ret i32 [[SEL_LCSSA]]
;
entry:
  %sub = add i32 %n, -1
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %c = icmp eq i32 %iv, %sub
  %sel = select i1 %c, i32 1, i32 2
  call void @foo(i32 %sel)
  %iv.next = add i32 %iv, 1
  %ec = icmp ne i32 %iv.next, %n
  br i1 %ec, label %loop, label %exit

exit:
  %sel.lcssa = phi i32 [ %sel, %loop ]
  ret i32 %sel.lcssa
}

define i32 @peel_last_with_trip_count_check_lcssa_phi_step_2(i32 %n) {
; CHECK-LABEL: define i32 @peel_last_with_trip_count_check_lcssa_phi_step_2(
; CHECK-SAME: i32 [[N:%.*]]) {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[SUB:%.*]] = add i32 [[N]], -2
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, %[[ENTRY]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[IV]], [[SUB]]
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C]], i32 1, i32 2
; CHECK-NEXT:    call void @foo(i32 [[SEL]])
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 2
; CHECK-NEXT:    [[EC:%.*]] = icmp ne i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC]], label %[[LOOP]], label %[[EXIT:.*]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    [[SEL_LCSSA:%.*]] = phi i32 [ [[SEL]], %[[LOOP]] ]
; CHECK-NEXT:    ret i32 [[SEL_LCSSA]]
;
entry:
  %sub = add i32 %n, -2
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %c = icmp eq i32 %iv, %sub
  %sel = select i1 %c, i32 1, i32 2
  call void @foo(i32 %sel)
  %iv.next = add i32 %iv, 2
  %ec = icmp ne i32 %iv.next, %n
  br i1 %ec, label %loop, label %exit

exit:
  %sel.lcssa = phi i32 [ %sel, %loop ]
  ret i32 %sel.lcssa
}

define i64 @peel_single_block_loop_iv_step_1_may_execute_only_once(i64 %n) {
; CHECK-LABEL: define i64 @peel_single_block_loop_iv_step_1_may_execute_only_once(
; CHECK-SAME: i64 [[N:%.*]]) {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[N_NOT_0:%.*]] = icmp ne i64 [[N]], 0
; CHECK-NEXT:    call void @llvm.assume(i1 [[N_NOT_0]])
; CHECK-NEXT:    [[SUB:%.*]] = add nsw i64 [[N]], 1
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i64 [ 0, %[[ENTRY]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[CMP18_NOT:%.*]] = icmp eq i64 [[IV]], [[N]]
; CHECK-NEXT:    [[COND:%.*]] = select i1 [[CMP18_NOT]], i32 10, i32 20
; CHECK-NEXT:    call void @foo(i32 [[COND]])
; CHECK-NEXT:    [[IV_NEXT]] = add i64 [[IV]], 1
; CHECK-NEXT:    [[EC:%.*]] = icmp ne i64 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC]], label %[[LOOP]], label %[[EXIT:.*]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    [[IV_LCSSA:%.*]] = phi i64 [ [[IV]], %[[LOOP]] ]
; CHECK-NEXT:    ret i64 [[IV_LCSSA]]
;
entry:
  %n.not.0 = icmp ne i64 %n, 0
  call void @llvm.assume(i1 %n.not.0)
  %sub = add nsw i64 %n, 1
  br label %loop

loop:
  %iv = phi i64 [ 0, %entry ], [ %iv.next, %loop ]
  %cmp = icmp eq i64 %iv, %n
  %cond = select i1 %cmp, i32 10, i32 20
  call void @foo(i32 %cond)
  %iv.next = add i64 %iv, 1
  %ec = icmp ne i64 %iv.next, %n
  br i1 %ec, label %loop, label %exit

exit:
  ret i64 %iv
}



define i32 @peel_last_with_trip_count_check_lcssa_phi_cmp_not_invar(i32 %n) {
; CHECK-LABEL: define i32 @peel_last_with_trip_count_check_lcssa_phi_cmp_not_invar(
; CHECK-SAME: i32 [[N:%.*]]) {
; CHECK-NEXT:  [[ENTRY:.*]]:
; CHECK-NEXT:    [[SUB:%.*]] = add i32 [[N]], -2
; CHECK-NEXT:    br label %[[LOOP:.*]]
; CHECK:       [[LOOP]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, %[[ENTRY]] ], [ [[IV_NEXT:%.*]], %[[LOOP]] ]
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[IV]], [[SUB]]
; CHECK-NEXT:    [[SEL:%.*]] = select i1 [[C]], i32 1, i32 2
; CHECK-NEXT:    call void @foo(i32 [[SEL]])
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[EC:%.*]] = icmp ne i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EC]], label %[[LOOP]], label %[[EXIT:.*]]
; CHECK:       [[EXIT]]:
; CHECK-NEXT:    [[SEL_LCSSA:%.*]] = phi i32 [ [[SEL]], %[[LOOP]] ]
; CHECK-NEXT:    ret i32 [[SEL_LCSSA]]
;
entry:
  %sub = add i32 %n, -2
  br label %loop

loop:
  %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
  %c = icmp eq i32 %iv, %sub
  %sel = select i1 %c, i32 1, i32 2
  call void @foo(i32 %sel)
  %iv.next = add i32 %iv, 1
  %ec = icmp ne i32 %iv.next, %n
  br i1 %ec, label %loop, label %exit

exit:
  %sel.lcssa = phi i32 [ %sel, %loop ]
  ret i32 %sel.lcssa
}


define void @peel_last_with_trip_count_check_nested_loop(i32 %n) {
; CHECK-LABEL: define void @peel_last_with_trip_count_check_nested_loop(
; CHECK-SAME: i32 [[N:%.*]]) {
; CHECK-NEXT:  [[ENTRY:.*:]]
; CHECK-NEXT:    [[SUB:%.*]] = add i32 [[N]], -1
; CHECK-NEXT:    br label %[[OUTER_HEADER:.*]]
; CHECK:       [[OUTER_HEADER_LOOPEXIT:.*]]:
; CHECK-NEXT:    br label %[[OUTER_HEADER]]
; CHECK:       [[OUTER_HEADER]]:
; CHECK-NEXT:    br label %[[INNER_HEADER:.*]]
; CHECK:       [[INNER_HEADER]]:
; CHECK-NEXT:    [[IV:%.*]] = phi i32 [ 0, %[[OUTER_HEADER]] ], [ [[IV_NEXT:%.*]], %[[INNER_LATCH:.*]] ]
; CHECK-NEXT:    [[C:%.*]] = icmp eq i32 [[IV]], [[SUB]]
; CHECK-NEXT:    br i1 [[C]], label %[[INNER_LATCH]], label %[[THEN:.*]]
; CHECK:       [[THEN]]:
; CHECK-NEXT:    call void @foo(i32 1)
; CHECK-NEXT:    br label %[[INNER_LATCH]]
; CHECK:       [[INNER_LATCH]]:
; CHECK-NEXT:    [[IV_NEXT]] = add i32 [[IV]], 1
; CHECK-NEXT:    [[EXITCOND_NOT:%.*]] = icmp eq i32 [[IV_NEXT]], [[N]]
; CHECK-NEXT:    br i1 [[EXITCOND_NOT]], label %[[OUTER_HEADER_LOOPEXIT]], label %[[INNER_HEADER]]
;
entry:
  %sub = add i32 %n, -1
  br label %outer.header

outer.header:
  br label %inner.header

inner.header:
  %iv = phi i32 [ 0, %outer.header ], [ %iv.next, %inner.latch ]
  %c = icmp eq i32 %iv, %sub
  br i1 %c, label %inner.latch, label %then

then:
  call void @foo(i32 1)
  br label %inner.latch

inner.latch:
  %iv.next = add i32 %iv, 1
  %exitcond.not = icmp eq i32 %iv.next, %n
  br i1 %exitcond.not, label %outer.header, label %inner.header
}
