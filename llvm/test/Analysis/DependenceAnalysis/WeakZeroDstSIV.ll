; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py UTC_ARGS: --version 5
; RUN: opt < %s -disable-output "-passes=print<da>" -aa-pipeline=basic-aa 2>&1 \
; RUN: | FileCheck %s

; ModuleID = 'WeakZeroDstSIV.bc'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"
target triple = "x86_64-apple-macosx10.6.0"


;;  for (int i = 0; i < N; i++) {
;;    A[i] = 1;
;;    A[0] = 2;

define void @dstzero(ptr nocapture %A, i32 %N) {
; CHECK-LABEL: 'dstzero'
; CHECK-NEXT:  Src: store i32 0, ptr %arrayidx, align 4 --> Dst: store i32 0, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 0, ptr %arrayidx, align 4 --> Dst: store i32 1, ptr %A, align 4
; CHECK-NEXT:    da analyze - output [p<=|<]!
; CHECK-NEXT:  Src: store i32 1, ptr %A, align 4 --> Dst: store i32 1, ptr %A, align 4
; CHECK-NEXT:    da analyze - consistent output [S]!
;
entry:
  %cmp6 = icmp sgt i32 %N, 0
  br i1 %cmp6, label %for.body, label %for.cond.cleanup

for.body:                                         ; preds = %entry, %for.body
  %i.07 = phi i32 [ %add, %for.body ], [ 0, %entry ]
  %arrayidx = getelementptr inbounds i32, ptr %A, i32 %i.07
  store i32 0, ptr %arrayidx, align 4
  store i32 1, ptr %A, align 4
  %add = add nuw nsw i32 %i.07, 1
  %exitcond = icmp eq i32 %add, %N
  br i1 %exitcond, label %for.cond.cleanup, label %for.body

for.cond.cleanup:                                 ; preds = %for.body, %entry
  ret void
}




;;  for (long unsigned i = 0; i < 30; i++) {
;;    A[2*i + 10] = i;
;;    *B++ = A[10];

define void @weakzerodst0(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst0'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - flow [p<=|<]!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.01, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.02 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %B.addr.01 = phi ptr [ %B, %entry ], [ %incdec.ptr, %for.body ]
  %conv = trunc i64 %i.02 to i32
  %mul = shl i64 %i.02, 1
  %add = add i64 %mul, 10
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %add
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.01, i64 1
  store i32 %0, ptr %B.addr.01, align 4
  %inc = add i64 %i.02, 1
  %exitcond = icmp ne i64 %inc, 30
  br i1 %exitcond, label %for.body, label %for.end

for.end:                                          ; preds = %for.body
  ret void
}


;;  for (long unsigned i = 0; i < n; i++) {
;;    A[n*i + 10] = i;
;;    *B++ = A[10];

define void @weakzerodst1(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst1'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - flow [p<=|<]!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.02, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.02, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.02, align 4 --> Dst: store i32 %0, ptr %B.addr.02, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  %cmp1 = icmp eq i64 %n, 0
  br i1 %cmp1, label %for.end, label %for.body.preheader

for.body.preheader:                               ; preds = %entry
  br label %for.body

for.body:                                         ; preds = %for.body.preheader, %for.body
  %i.03 = phi i64 [ %inc, %for.body ], [ 0, %for.body.preheader ]
  %B.addr.02 = phi ptr [ %incdec.ptr, %for.body ], [ %B, %for.body.preheader ]
  %conv = trunc i64 %i.03 to i32
  %mul = mul i64 %i.03, %n
  %add = add i64 %mul, 10
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %add
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.02, i64 1
  store i32 %0, ptr %B.addr.02, align 4
  %inc = add i64 %i.03, 1
  %exitcond = icmp ne i64 %inc, %n
  br i1 %exitcond, label %for.body, label %for.end.loopexit

for.end.loopexit:                                 ; preds = %for.body
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %entry
  ret void
}


;;  for (long unsigned i = 0; i < 5; i++) {
;;    A[2*i] = i;
;;    *B++ = A[10];

define void @weakzerodst2(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst2'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.01, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.02 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %B.addr.01 = phi ptr [ %B, %entry ], [ %incdec.ptr, %for.body ]
  %conv = trunc i64 %i.02 to i32
  %mul = shl i64 %i.02, 1
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %mul
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.01, i64 1
  store i32 %0, ptr %B.addr.01, align 4
  %inc = add i64 %i.02, 1
  %exitcond = icmp ne i64 %inc, 5
  br i1 %exitcond, label %for.body, label %for.end

for.end:                                          ; preds = %for.body
  ret void
}


;;  for (long unsigned i = 0; i < 6; i++) {
;;    A[2*i] = i;
;;    *B++ = A[10];

define void @weakzerodst3(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst3'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - flow [=>p|<]!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.01, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.02 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %B.addr.01 = phi ptr [ %B, %entry ], [ %incdec.ptr, %for.body ]
  %conv = trunc i64 %i.02 to i32
  %mul = shl i64 %i.02, 1
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %mul
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.01, i64 1
  store i32 %0, ptr %B.addr.01, align 4
  %inc = add i64 %i.02, 1
  %exitcond = icmp ne i64 %inc, 6
  br i1 %exitcond, label %for.body, label %for.end

for.end:                                          ; preds = %for.body
  ret void
}


;;  for (long unsigned i = 0; i < 7; i++) {
;;    A[2*i] = i;
;;    *B++ = A[10];

define void @weakzerodst4(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst4'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - flow [*|<]!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.01, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.02 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %B.addr.01 = phi ptr [ %B, %entry ], [ %incdec.ptr, %for.body ]
  %conv = trunc i64 %i.02 to i32
  %mul = shl i64 %i.02, 1
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %mul
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.01, i64 1
  store i32 %0, ptr %B.addr.01, align 4
  %inc = add i64 %i.02, 1
  %exitcond = icmp ne i64 %inc, 7
  br i1 %exitcond, label %for.body, label %for.end

for.end:                                          ; preds = %for.body
  ret void
}


;;  for (long unsigned i = 0; i < 7; i++) {
;;    A[2*i] = i;
;;    *B++ = A[-10];

define void @weakzerodst5(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst5'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.01, align 4 --> Dst: store i32 %0, ptr %B.addr.01, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  br label %for.body

for.body:                                         ; preds = %entry, %for.body
  %i.02 = phi i64 [ 0, %entry ], [ %inc, %for.body ]
  %B.addr.01 = phi ptr [ %B, %entry ], [ %incdec.ptr, %for.body ]
  %conv = trunc i64 %i.02 to i32
  %mul = shl i64 %i.02, 1
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %mul
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 -10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.01, i64 1
  store i32 %0, ptr %B.addr.01, align 4
  %inc = add i64 %i.02, 1
  %exitcond = icmp ne i64 %inc, 7
  br i1 %exitcond, label %for.body, label %for.end

for.end:                                          ; preds = %for.body
  ret void
}


;;  for (long unsigned i = 0; i < n; i++) {
;;    A[3*i] = i;
;;    *B++ = A[10];

define void @weakzerodst6(ptr %A, ptr %B, i64 %n) nounwind uwtable ssp {
; CHECK-LABEL: 'weakzerodst6'
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %conv, ptr %arrayidx, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - none!
; CHECK-NEXT:  Src: store i32 %conv, ptr %arrayidx, align 4 --> Dst: store i32 %0, ptr %B.addr.02, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: %0 = load i32, ptr %arrayidx1, align 4
; CHECK-NEXT:    da analyze - consistent input [S]!
; CHECK-NEXT:  Src: %0 = load i32, ptr %arrayidx1, align 4 --> Dst: store i32 %0, ptr %B.addr.02, align 4
; CHECK-NEXT:    da analyze - confused!
; CHECK-NEXT:  Src: store i32 %0, ptr %B.addr.02, align 4 --> Dst: store i32 %0, ptr %B.addr.02, align 4
; CHECK-NEXT:    da analyze - none!
;
entry:
  %cmp1 = icmp eq i64 %n, 0
  br i1 %cmp1, label %for.end, label %for.body.preheader

for.body.preheader:                               ; preds = %entry
  br label %for.body

for.body:                                         ; preds = %for.body.preheader, %for.body
  %i.03 = phi i64 [ %inc, %for.body ], [ 0, %for.body.preheader ]
  %B.addr.02 = phi ptr [ %incdec.ptr, %for.body ], [ %B, %for.body.preheader ]
  %conv = trunc i64 %i.03 to i32
  %mul = mul i64 %i.03, 3
  %arrayidx = getelementptr inbounds i32, ptr %A, i64 %mul
  store i32 %conv, ptr %arrayidx, align 4
  %arrayidx1 = getelementptr inbounds i32, ptr %A, i64 10
  %0 = load i32, ptr %arrayidx1, align 4
  %incdec.ptr = getelementptr inbounds i32, ptr %B.addr.02, i64 1
  store i32 %0, ptr %B.addr.02, align 4
  %inc = add i64 %i.03, 1
  %exitcond = icmp ne i64 %inc, %n
  br i1 %exitcond, label %for.body, label %for.end.loopexit

for.end.loopexit:                                 ; preds = %for.body
  br label %for.end

for.end:                                          ; preds = %for.end.loopexit, %entry
  ret void
}
