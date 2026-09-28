#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_COUNT_BITS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* returns the number of bits in an int */
int amplify_mp_count_bits(const amplify_mp_int *a)
{
   int     r;
   amplify_mp_digit q;

   /* shortcut */
   if (AMPLIFY_MP_IS_ZERO(a)) {
      return 0;
   }

   /* get number of digits and add that */
   r = (a->used - 1) * AMPLIFY_MP_DIGIT_BIT;

   /* take the last digit and count the bits in it */
   q = a->dp[a->used - 1];
   while (q > 0u) {
      ++r;
      q >>= 1u;
   }
   return r;
}
#endif
