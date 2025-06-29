//===-- Linux implementation of tcsetattr ---------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "src/termios/tcsetattr.h"
#include "kernel_termios.h"

#include "src/__support/OSUtil/syscall.h"
#include "src/__support/common.h"
#include "src/__support/libc_errno.h"
#include "src/__support/macros/config.h"

#include <asm/ioctls.h> // Safe to include without the risk of name pollution.
#include <sys/syscall.h> // For syscall numbers
#include <termios.h>

namespace LIBC_NAMESPACE_DECL {

LLVM_LIBC_FUNCTION(int, tcsetattr,
                   (int fd, int actions, const struct termios *t)) {
  struct kernel_termios kt;
  long cmd;

  switch (actions) {
  case TCSANOW:
    cmd = TCSETS;
    break;
  case TCSADRAIN:
    cmd = TCSETSW;
    break;
  case TCSAFLUSH:
    cmd = TCSETSF;
    break;
  default:
    libc_errno = EINVAL;
    return -1;
  }

  kt.c_iflag = t->c_iflag;
  kt.c_oflag = t->c_oflag;
  kt.c_cflag = t->c_cflag;
  kt.c_lflag = t->c_lflag;
  size_t nccs = KERNEL_NCCS <= NCCS ? KERNEL_NCCS : NCCS;
  for (size_t i = 0; i < nccs; ++i)
    kt.c_cc[i] = t->c_cc[i];
  if (nccs < KERNEL_NCCS) {
    for (size_t i = nccs; i < KERNEL_NCCS; ++i)
      kt.c_cc[i] = 0;
  }

  int ret = LIBC_NAMESPACE::syscall_impl<int>(SYS_ioctl, fd, cmd, &kt);
  if (ret < 0) {
    libc_errno = -ret;
    return -1;
  }
  return 0;
}

} // namespace LIBC_NAMESPACE_DECL
