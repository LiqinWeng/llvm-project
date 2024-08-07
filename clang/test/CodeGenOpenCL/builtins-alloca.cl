// NOTE: Assertions have been autogenerated by utils/update_cc_test_checks.py UTC_ARGS: --version 5
// RUN: %clang_cc1 %s -O0 -triple amdgcn-amd-amdhsa -cl-std=CL1.2 \
// RUN:     -emit-llvm -o - | FileCheck --check-prefixes=OPENCL %s
// RUN: %clang_cc1 %s -O0 -triple amdgcn-amd-amdhsa -cl-std=CL2.0 \
// RUN:     -emit-llvm -o - | FileCheck --check-prefixes=OPENCL %s
// RUN: %clang_cc1 %s -O0 -triple amdgcn-amd-amdhsa -cl-std=CL3.0 \
// RUN:     -emit-llvm -o - | FileCheck --check-prefixes=OPENCL %s
// RUN: %clang_cc1 %s -O0 -triple amdgcn-amd-amdhsa -cl-std=CL3.0 -cl-ext=+__opencl_c_generic_address_space \
// RUN:     -emit-llvm -o - | FileCheck --check-prefixes=OPENCL %s

// OPENCL-LABEL: define dso_local void @test1_builtin_alloca(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0:[0-9]+]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[MUL:%.*]] = mul i64 [[CONV]], 4
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[MUL]], align 8, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR]], align 4
// OPENCL-NEXT:    ret void
//
void test1_builtin_alloca(unsigned n) {
    __private float* alloc_ptr = (__private float*)__builtin_alloca(n*sizeof(int));
}

// OPENCL-LABEL: define dso_local void @test1_builtin_alloca_uninitialized(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR_UNINITIALIZED:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[MUL:%.*]] = mul i64 [[CONV]], 4
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[MUL]], align 8, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR_UNINITIALIZED]], align 4
// OPENCL-NEXT:    ret void
//
void test1_builtin_alloca_uninitialized(unsigned n) {
    __private float* alloc_ptr_uninitialized = (__private float*)__builtin_alloca_uninitialized(n*sizeof(int));
}

// OPENCL-LABEL: define dso_local void @test1_builtin_alloca_with_align(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR_ALIGN:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[MUL:%.*]] = mul i64 [[CONV]], 4
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[MUL]], align 1, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR_ALIGN]], align 4
// OPENCL-NEXT:    ret void
//
void test1_builtin_alloca_with_align(unsigned n) {
    __private float* alloc_ptr_align = (__private float*)__builtin_alloca_with_align((n*sizeof(int)), 8);
}

// OPENCL-LABEL: define dso_local void @test1_builtin_alloca_with_align_uninitialized(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR_ALIGN_UNINITIALIZED:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[MUL:%.*]] = mul i64 [[CONV]], 4
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[MUL]], align 1, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR_ALIGN_UNINITIALIZED]], align 4
// OPENCL-NEXT:    ret void
//
void test1_builtin_alloca_with_align_uninitialized(unsigned n) {
    __private float* alloc_ptr_align_uninitialized = (__private float*)__builtin_alloca_with_align_uninitialized((n*sizeof(int)), 8);
}

// OPENCL-LABEL: define dso_local void @test2_builtin_alloca(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[CONV]], align 8, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR]], align 4
// OPENCL-NEXT:    ret void
//
void test2_builtin_alloca(unsigned n) {
    __private void *alloc_ptr = __builtin_alloca(n);
}

// OPENCL-LABEL: define dso_local void @test2_builtin_alloca_uninitialized(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR_UNINITIALIZED:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[CONV]], align 8, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR_UNINITIALIZED]], align 4
// OPENCL-NEXT:    ret void
//
void test2_builtin_alloca_uninitialized(unsigned n) {
    __private void *alloc_ptr_uninitialized = __builtin_alloca_uninitialized(n);
}

// OPENCL-LABEL: define dso_local void @test2_builtin_alloca_with_align(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR_ALIGN:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[CONV]], align 1, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR_ALIGN]], align 4
// OPENCL-NEXT:    ret void
//
void test2_builtin_alloca_with_align(unsigned n) {
    __private void *alloc_ptr_align = __builtin_alloca_with_align(n, 8);
}

// OPENCL-LABEL: define dso_local void @test2_builtin_alloca_with_align_uninitialized(
// OPENCL-SAME: i32 noundef [[N:%.*]]) #[[ATTR0]] {
// OPENCL-NEXT:  [[ENTRY:.*:]]
// OPENCL-NEXT:    [[N_ADDR:%.*]] = alloca i32, align 4, addrspace(5)
// OPENCL-NEXT:    [[ALLOC_PTR_ALIGN_UNINITIALIZED:%.*]] = alloca ptr addrspace(5), align 4, addrspace(5)
// OPENCL-NEXT:    store i32 [[N]], ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[TMP0:%.*]] = load i32, ptr addrspace(5) [[N_ADDR]], align 4
// OPENCL-NEXT:    [[CONV:%.*]] = zext i32 [[TMP0]] to i64
// OPENCL-NEXT:    [[TMP1:%.*]] = alloca i8, i64 [[CONV]], align 1, addrspace(5)
// OPENCL-NEXT:    store ptr addrspace(5) [[TMP1]], ptr addrspace(5) [[ALLOC_PTR_ALIGN_UNINITIALIZED]], align 4
// OPENCL-NEXT:    ret void
//
void test2_builtin_alloca_with_align_uninitialized(unsigned n) {
    __private void *alloc_ptr_align_uninitialized = __builtin_alloca_with_align_uninitialized(n, 8);
}
