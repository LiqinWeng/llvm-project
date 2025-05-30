//===----------------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include <vector>

_LIBCPP_BEGIN_NAMESPACE_STD
_LIBCPP_BEGIN_EXPLICIT_ABI_ANNOTATIONS

#ifndef _LIBCPP_ABI_DO_NOT_EXPORT_VECTOR_BASE_COMMON

template <bool>
struct __vector_base_common;

template <>
struct __vector_base_common<true> {
  [[noreturn]] _LIBCPP_EXPORTED_FROM_ABI void __throw_length_error() const;
  [[noreturn]] _LIBCPP_EXPORTED_FROM_ABI void __throw_out_of_range() const;
};

void __vector_base_common<true>::__throw_length_error() const { std::__throw_length_error("vector"); }

void __vector_base_common<true>::__throw_out_of_range() const { std::__throw_out_of_range("vector"); }

#endif // _LIBCPP_ABI_DO_NOT_EXPORT_VECTOR_BASE_COMMON

_LIBCPP_END_EXPLICIT_ABI_ANNOTATIONS
_LIBCPP_END_NAMESPACE_STD
