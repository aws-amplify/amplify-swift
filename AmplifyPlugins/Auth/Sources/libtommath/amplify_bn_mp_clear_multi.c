#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_CLEAR_MULTI_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#include <stdarg.h>

void amplify_mp_clear_multi(amplify_mp_int *mp, ...)
{
   amplify_mp_int *next_mp = mp;
   va_list args;
   va_start(args, mp);
   while (next_mp != NULL) {
      amplify_mp_clear(next_mp);
      next_mp = va_arg(args, amplify_mp_int *);
   }
   va_end(args);
}
#endif
