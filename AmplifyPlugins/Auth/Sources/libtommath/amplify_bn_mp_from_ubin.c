#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_FROM_UBIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* reads a unsigned char array, assumes the msb is stored first [big endian] */
amplify_mp_err amplify_mp_from_ubin(amplify_mp_int *a, const unsigned char *buf, size_t size)
{
   amplify_mp_err err;

   /* make sure there are at least two digits */
   if (a->alloc < 2) {
      if ((err = amplify_mp_grow(a, 2)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* zero the int */
   amplify_mp_zero(a);

   /* read the bytes in */
   while (size-- > 0u) {
      if ((err = amplify_mp_mul_2d(a, 8, a)) != AMPLIFY_MP_OKAY) {
         return err;
      }

#ifndef AMPLIFY_MP_8BIT
      a->dp[0] |= *buf++;
      a->used += 1;
#else
      a->dp[0] = (*buf & AMPLIFY_MP_MASK);
      a->dp[1] |= ((*buf++ >> 7) & 1u);
      a->used += 2;
#endif
   }
   amplify_mp_clamp(a);
   return AMPLIFY_MP_OKAY;
}
#endif
