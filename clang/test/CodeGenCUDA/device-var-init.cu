// REQUIRES: nvptx-registered-target
// REQUIRES: amdgpu-registered-target

// Make sure we don't allow dynamic initialization for device
// variables, but accept empty constructors allowed by CUDA.

// RUN: %clang_cc1 -triple nvptx64-nvidia-cuda -fcuda-is-device -std=c++11 \
// RUN:     -fno-threadsafe-statics -emit-llvm -o - %s | FileCheck -check-prefixes=DEVICE,NVPTX %s
// RUN: %clang_cc1 -triple nvptx64-nvidia-cuda -std=c++11 \
// RUN:     -fno-threadsafe-statics -emit-llvm -o - %s | FileCheck -check-prefixes=HOST %s

// RUN: %clang_cc1 -triple amdgcn -fcuda-is-device -std=c++11 \
// RUN:     -fno-threadsafe-statics -emit-llvm -o - %s | FileCheck -check-prefixes=DEVICE,AMDGCN %s

#ifdef __clang__
#include "Inputs/cuda.h"
#endif

// Use the types we share with Sema tests.
#include "Inputs/cuda-initializers.h"

__device__ int d_v;
// DEVICE: @d_v ={{.*}} addrspace(1) externally_initialized global i32 0,
// HOST:   @d_v = internal global i32 undef,
__shared__ int s_v;
// DEVICE: @s_v ={{.*}} addrspace(3) global i32 undef,
// HOST:   @s_v = internal global i32 undef,
__constant__ int c_v;
// DEVICE: addrspace(4) externally_initialized constant i32 0,
// HOST:   @c_v = internal global i32 undef,

__device__ int d_v_i = 1;
// DEVICE: @d_v_i ={{.*}} addrspace(1) externally_initialized global i32 1,
// HOST:   @d_v_i = internal global i32 undef,

// For `static` device variables, assume they won't be addressed from the host
// side.
static __device__ int d_s_v_i = 1;
// DEVICE: @_ZL7d_s_v_i = internal addrspace(1) global i32 1,

// Dummy function to keep static variables referenced.
__device__ int foo() {
  return d_s_v_i;
}

// trivial constructor -- allowed
__device__ T d_t;
// DEVICE: @d_t ={{.*}} addrspace(1) externally_initialized global %struct.T zeroinitializer
// HOST:   @d_t = internal global %struct.T undef,
__shared__ T s_t;
// DEVICE: @s_t ={{.*}} addrspace(3) global %struct.T undef,
// HOST:   @s_t = internal global %struct.T undef,
__constant__ T c_t;
// DEVICE: @c_t ={{.*}} addrspace(4) externally_initialized constant %struct.T zeroinitializer,
// HOST:   @c_t = internal global %struct.T undef,

__device__ T d_t_i = {2};
// DEVICE: @d_t_i ={{.*}} addrspace(1) externally_initialized global %struct.T { i32 2 },
// HOST:   @d_t_i = internal global %struct.T undef,
__constant__ T c_t_i = {2};
// DEVICE: @c_t_i ={{.*}} addrspace(4) externally_initialized constant %struct.T { i32 2 },
// HOST:   @c_t_i = internal global %struct.T undef,

// empty constructor
__device__ EC d_ec;
// DEVICE: @d_ec ={{.*}} addrspace(1) externally_initialized global %struct.EC zeroinitializer,
// HOST:   @d_ec = internal global %struct.EC undef,
__shared__ EC s_ec;
// DEVICE: @s_ec ={{.*}} addrspace(3) global %struct.EC undef,
// HOST:   @s_ec = internal global %struct.EC undef,
__constant__ EC c_ec;
// DEVICE: @c_ec ={{.*}} addrspace(4) externally_initialized constant %struct.EC zeroinitializer,
// HOST:   @c_ec = internal global %struct.EC undef

// empty destructor
__device__ ED d_ed;
// DEVICE: @d_ed ={{.*}} addrspace(1) externally_initialized global %struct.ED zeroinitializer,
// HOST:   @d_ed = internal global %struct.ED undef,
__shared__ ED s_ed;
// DEVICE: @s_ed ={{.*}} addrspace(3) global %struct.ED undef,
// HOST:   @s_ed = internal global %struct.ED undef,
__constant__ ED c_ed;
// DEVICE: @c_ed ={{.*}} addrspace(4) externally_initialized constant %struct.ED zeroinitializer,
// HOST:   @c_ed = internal global %struct.ED undef,

__device__ ECD d_ecd;
// DEVICE: @d_ecd ={{.*}} addrspace(1) externally_initialized global %struct.ECD zeroinitializer,
// HOST:   @d_ecd = internal global %struct.ECD undef,
__shared__ ECD s_ecd;
// DEVICE: @s_ecd ={{.*}} addrspace(3) global %struct.ECD undef,
// HOST:   @s_ecd = internal global %struct.ECD undef,
__constant__ ECD c_ecd;
// DEVICE: @c_ecd ={{.*}} addrspace(4) externally_initialized constant %struct.ECD zeroinitializer,
// HOST:   @c_ecd = internal global %struct.ECD undef,

// empty templated constructor -- allowed with no arguments
__device__ ETC d_etc;
// DEVICE: @d_etc ={{.*}} addrspace(1) externally_initialized global %struct.ETC zeroinitializer,
// HOST:   @d_etc = internal global %struct.ETC undef,
__shared__ ETC s_etc;
// DEVICE: @s_etc ={{.*}} addrspace(3) global %struct.ETC undef,
// HOST:   @s_etc = internal global %struct.ETC undef,
__constant__ ETC c_etc;
// DEVICE: @c_etc ={{.*}} addrspace(4) externally_initialized constant %struct.ETC zeroinitializer,
// HOST:   @c_etc = internal global %struct.ETC undef,

__device__ NCFS d_ncfs;
// DEVICE: @d_ncfs ={{.*}} addrspace(1) externally_initialized global %struct.NCFS { i32 3 }
// HOST:   @d_ncfs = internal global %struct.NCFS undef,
__constant__ NCFS c_ncfs;
// DEVICE: @c_ncfs ={{.*}} addrspace(4) externally_initialized constant %struct.NCFS { i32 3 }
// HOST:   @c_ncfs = internal global %struct.NCFS undef,

// Regular base class -- allowed
__device__ T_B_T d_t_b_t;
// DEVICE: @d_t_b_t ={{.*}} addrspace(1) externally_initialized global %struct.T_B_T zeroinitializer,
// HOST:   @d_t_b_t = internal global %struct.T_B_T undef,
__shared__ T_B_T s_t_b_t;
// DEVICE: @s_t_b_t ={{.*}} addrspace(3) global %struct.T_B_T undef,
// HOST:   @s_t_b_t = internal global %struct.T_B_T undef,
__constant__ T_B_T c_t_b_t;
// DEVICE: @c_t_b_t ={{.*}} addrspace(4) externally_initialized constant %struct.T_B_T zeroinitializer,
// HOST:   @c_t_b_t = internal global %struct.T_B_T undef,

// Incapsulated object of allowed class -- allowed
__device__ T_F_T d_t_f_t;
// DEVICE: @d_t_f_t ={{.*}} addrspace(1) externally_initialized global %struct.T_F_T zeroinitializer,
// HOST:   @d_t_f_t = internal global %struct.T_F_T undef,
__shared__ T_F_T s_t_f_t;
// DEVICE: @s_t_f_t ={{.*}} addrspace(3) global %struct.T_F_T undef,
// HOST:   @s_t_f_t = internal global %struct.T_F_T undef,
__constant__ T_F_T c_t_f_t;
// DEVICE: @c_t_f_t ={{.*}} addrspace(4) externally_initialized constant %struct.T_F_T zeroinitializer,
// HOST:   @c_t_f_t = internal global %struct.T_F_T undef,

// array of allowed objects -- allowed
__device__ T_FA_T d_t_fa_t;
// DEVICE: @d_t_fa_t ={{.*}} addrspace(1) externally_initialized global %struct.T_FA_T zeroinitializer,
// HOST:   @d_t_fa_t = internal global %struct.T_FA_T undef,
__shared__ T_FA_T s_t_fa_t;
// DEVICE: @s_t_fa_t ={{.*}} addrspace(3) global %struct.T_FA_T undef,
// HOST:   @s_t_fa_t = internal global %struct.T_FA_T undef,
__constant__ T_FA_T c_t_fa_t;
// DEVICE: @c_t_fa_t ={{.*}} addrspace(4) externally_initialized constant %struct.T_FA_T zeroinitializer,
// HOST:   @c_t_fa_t = internal global %struct.T_FA_T undef,


// Calling empty base class initializer is OK
__device__ EC_I_EC d_ec_i_ec;
// DEVICE: @d_ec_i_ec ={{.*}} addrspace(1) externally_initialized global %struct.EC_I_EC zeroinitializer,
// HOST:   @d_ec_i_ec = internal global %struct.EC_I_EC undef,
__shared__ EC_I_EC s_ec_i_ec;
// DEVICE: @s_ec_i_ec ={{.*}} addrspace(3) global %struct.EC_I_EC undef,
// HOST:   @s_ec_i_ec = internal global %struct.EC_I_EC undef,
__constant__ EC_I_EC c_ec_i_ec;
// DEVICE: @c_ec_i_ec ={{.*}} addrspace(4) externally_initialized constant %struct.EC_I_EC zeroinitializer,
// HOST:   @c_ec_i_ec = internal global %struct.EC_I_EC undef,

// DEVICE: @_ZZ2dfvE4s_ec = internal addrspace(3) global %struct.EC undef
// DEVICE: @_ZZ2dfvE5s_etc = internal addrspace(3) global %struct.ETC undef

// DEVICE: @_ZZ2dfvE11const_array = internal addrspace(4) constant [5 x i32] [i32 1, i32 2, i32 3, i32 4, i32 5]
// DEVICE: @_ZZ2dfvE9const_int = internal addrspace(4) constant i32 123

// We should not emit global initializers for device-side variables.
// DEVICE-NOT: @__cxx_global_var_init

// Make sure that initialization restrictions do not apply to local
// variables.
__device__ void df() {
  // NVPTX:  %[[ec:.*]] = alloca %struct.EC
  // NVPTX:  %[[ed:.*]] = alloca %struct.ED
  // NVPTX:  %[[ecd:.*]] = alloca %struct.ECD
  // NVPTX:  %[[etc:.*]] = alloca %struct.ETC
  // NVPTX:  %[[uc:.*]] = alloca %struct.UC
  // NVPTX:  %[[ud:.*]] = alloca %struct.UD
  // NVPTX:  %[[eci:.*]] = alloca %struct.ECI
  // NVPTX:  %[[nec:.*]] = alloca %struct.NEC
  // NVPTX:  %[[ned:.*]] = alloca %struct.NED
  // NVPTX:  %[[ncv:.*]] = alloca %struct.NCV
  // NVPTX:  %[[vd:.*]] = alloca %struct.VD
  // NVPTX:  %[[ncf:.*]] = alloca %struct.NCF
  // NVPTX:  %[[ncfs:.*]] = alloca %struct.NCFS
  // NVPTX:  %[[utc:.*]] = alloca %struct.UTC
  // NVPTX:  %[[netc:.*]] = alloca %struct.NETC
  // NVPTX:  %[[ec_i_ec:.*]] = alloca %struct.EC_I_EC
  // NVPTX:  %[[ec_i_ec1:.*]] = alloca %struct.EC_I_EC1
  // NVPTX:  %[[t_v_t:.*]] = alloca %struct.T_V_T
  // NVPTX:  %[[t_b_nec:.*]] = alloca %struct.T_B_NEC
  // NVPTX:  %[[t_f_nec:.*]] = alloca %struct.T_F_NEC
  // NVPTX:  %[[t_fa_nec:.*]] = alloca %struct.T_FA_NEC
  // NVPTX:  %[[t_b_ned:.*]] = alloca %struct.T_B_NED
  // NVPTX:  %[[t_f_ned:.*]] = alloca %struct.T_F_NED
  // NVPTX:  %[[t_fa_ned:.*]] = alloca %struct.T_FA_NED
  // AMDGCN:  %[[ec:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ec to ptr
  // AMDGCN:  %[[ed:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ed to ptr
  // AMDGCN:  %[[ecd:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ecd to ptr
  // AMDGCN:  %[[etc:.*]] ={{.*}} addrspacecast ptr addrspace(5) %etc to ptr
  // AMDGCN:  %[[uc:.*]] ={{.*}} addrspacecast ptr addrspace(5) %uc to ptr
  // AMDGCN:  %[[ud:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ud to ptr
  // AMDGCN:  %[[eci:.*]] ={{.*}} addrspacecast ptr addrspace(5) %eci to ptr
  // AMDGCN:  %[[nec:.*]] ={{.*}} addrspacecast ptr addrspace(5) %nec to ptr
  // AMDGCN:  %[[ned:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ned to ptr
  // AMDGCN:  %[[ncv:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ncv to ptr
  // AMDGCN:  %[[vd:.*]] ={{.*}} addrspacecast ptr addrspace(5) %vd to ptr
  // AMDGCN:  %[[ncf:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ncf to ptr
  // AMDGCN:  %[[ncfs:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ncfs to ptr
  // AMDGCN:  %[[utc:.*]] ={{.*}} addrspacecast ptr addrspace(5) %utc to ptr
  // AMDGCN:  %[[netc:.*]] ={{.*}} addrspacecast ptr addrspace(5) %netc to ptr
  // AMDGCN:  %[[ec_i_ec:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ec_i_ec to ptr
  // AMDGCN:  %[[ec_i_ec1:.*]] ={{.*}} addrspacecast ptr addrspace(5) %ec_i_ec1 to ptr
  // AMDGCN:  %[[t_v_t:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_v_t to ptr
  // AMDGCN:  %[[t_b_nec:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_b_nec to ptr
  // AMDGCN:  %[[t_f_nec:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_f_nec to ptr
  // AMDGCN:  %[[t_fa_nec:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_fa_nec to ptr
  // AMDGCN:  %[[t_b_ned:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_b_ned to ptr
  // AMDGCN:  %[[t_f_ned:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_f_ned to ptr
  // AMDGCN:  %[[t_fa_ned:.*]] ={{.*}} addrspacecast ptr addrspace(5) %t_fa_ned to ptr

  T t;
  // DEVICE-NOT: call
  EC ec;
  // DEVICE:  call void @_ZN2ECC1Ev(ptr {{[^,]*}} %[[ec]])
  ED ed;
  // DEVICE-NOT: call
  ECD ecd;
  // DEVICE:  call void @_ZN3ECDC1Ev(ptr {{[^,]*}} %[[ecd]])
  ETC etc;
  // DEVICE:  call void @_ZN3ETCC1IJEEEDpT_(ptr {{[^,]*}} %[[etc]])
  UC uc;
  // undefined constructor -- not allowed
  // DEVICE:  call void @_ZN2UCC1Ev(ptr {{[^,]*}} %[[uc]])
  UD ud;
  // undefined destructor -- not allowed
  // DEVICE-NOT: call
  ECI eci;
  // empty constructor w/ initializer list -- not allowed
  // DEVICE:  call void @_ZN3ECIC1Ev(ptr {{[^,]*}} %[[eci]])
  NEC nec;
  // non-empty constructor -- not allowed
  // DEVICE:  call void @_ZN3NECC1Ev(ptr {{[^,]*}} %[[nec]])
  // non-empty destructor -- not allowed
  NED ned;
  // no-constructor,  virtual method -- not allowed
  // DEVICE:  call void @_ZN3NCVC1Ev(ptr {{[^,]*}} %[[ncv]])
  NCV ncv;
  // DEVICE-NOT: call
  VD vd;
  // DEVICE:  call void @_ZN2VDC1Ev(ptr {{[^,]*}} %[[vd]])
  NCF ncf;
  // DEVICE:   call void @_ZN3NCFC1Ev(ptr {{[^,]*}} %[[ncf]])
  NCFS ncfs;
  // DEVICE:  call void @_ZN4NCFSC1Ev(ptr {{[^,]*}} %[[ncfs]])
  UTC utc;
  // DEVICE:  call void @_ZN3UTCC1IJEEEDpT_(ptr {{[^,]*}} %[[utc]])
  NETC netc;
  // DEVICE:  call void @_ZN4NETCC1IJEEEDpT_(ptr {{[^,]*}} %[[netc]])
  T_B_T t_b_t;
  // DEVICE-NOT: call
  T_F_T t_f_t;
  // DEVICE-NOT: call
  T_FA_T t_fa_t;
  // DEVICE-NOT: call
  EC_I_EC ec_i_ec;
  // DEVICE:  call void @_ZN7EC_I_ECC1Ev(ptr {{[^,]*}} %[[ec_i_ec]])
  EC_I_EC1 ec_i_ec1;
  // DEVICE:  call void @_ZN8EC_I_EC1C1Ev(ptr {{[^,]*}} %[[ec_i_ec1]])
  T_V_T t_v_t;
  // DEVICE:  call void @_ZN5T_V_TC1Ev(ptr {{[^,]*}} %[[t_v_t]])
  T_B_NEC t_b_nec;
  // DEVICE:  call void @_ZN7T_B_NECC1Ev(ptr {{[^,]*}} %[[t_b_nec]])
  T_F_NEC t_f_nec;
  // DEVICE:  call void @_ZN7T_F_NECC1Ev(ptr {{[^,]*}} %[[t_f_nec]])
  T_FA_NEC t_fa_nec;
  // DEVICE:  call void @_ZN8T_FA_NECC1Ev(ptr {{[^,]*}} %[[t_fa_nec]])
  T_B_NED t_b_ned;
  // DEVICE-NOT: call
  T_F_NED t_f_ned;
  // DEVICE-NOT: call
  T_FA_NED t_fa_ned;
  // DEVICE-NOT: call
  static __shared__ EC s_ec;
  // DEVICE-NOT: call void @_ZN2ECC1Ev(ptr addrspacecast (ptr addrspace(3) @_ZZ2dfvE4s_ec to ptr))
  static __shared__ ETC s_etc;
  // DEVICE-NOT: call void @_ZN3ETCC1IJEEEDpT_(ptr addrspacecast (ptr addrspace(3) @_ZZ2dfvE5s_etc to ptr))

  static const int const_array[] = {1, 2, 3, 4, 5};
  static const int const_int = 123;

  // anchor point separating constructors and destructors
  df(); // DEVICE: call void @_Z2dfv()

  // Verify that we only call non-empty destructors
  // DEVICE-NEXT: call void @_ZN8T_FA_NEDD1Ev(ptr {{[^,]*}} %[[t_fa_ned]])
  // DEVICE-NEXT: call void @_ZN7T_F_NEDD1Ev(ptr {{[^,]*}} %[[t_f_ned]])
  // DEVICE-NEXT: call void @_ZN7T_B_NEDD1Ev(ptr {{[^,]*}} %[[t_b_ned]])
  // DEVICE-NEXT: call void @_ZN2VDD1Ev(ptr {{[^,]*}} %[[vd]])
  // DEVICE-NEXT: call void @_ZN3NEDD1Ev(ptr {{[^,]*}} %[[ned]])
  // DEVICE-NEXT: call void @_ZN2UDD1Ev(ptr {{[^,]*}} %[[ud]])
  // DEVICE-NEXT: call void @_ZN3ECDD1Ev(ptr {{[^,]*}} %[[ecd]])
  // DEVICE-NEXT: call void @_ZN2EDD1Ev(ptr {{[^,]*}} %[[ed]])

  // DEVICE-NEXT: ret void
}

// We should not emit global init function.
// DEVICE-NOT: @_GLOBAL__sub_I
