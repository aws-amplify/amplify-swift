#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_REVERSE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* reverse an array, used for radix code */
void amplify_s_mp_reverse(unsigned char *s, size_t len)
{
   size_t   ix, iy;
   unsigned char t;

   ix = 0u;
   iy = len - 1u;
   while (ix < iy) {
      t     = s[ix];
      s[ix] = s[iy];
      s[iy] = t;
      ++ix;
      --iy;
   }
}
#endif
