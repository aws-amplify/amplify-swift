#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_IS_2K_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* determines if amplify_mp_reduce_2k can be used */
amplify_mp_bool amplify_mp_reduce_is_2k(const amplify_mp_int *a)
{
   int ix, iy, iw;
   amplify_mp_digit iz;

   if (a->used == 0) {
      return AMPLIFY_MP_NO;
   } else if (a->used == 1) {
      return AMPLIFY_MP_YES;
   } else if (a->used > 1) {
      iy = amplify_mp_count_bits(a);
      iz = 1;
      iw = 1;

      /* Test every bit from the second digit up, must be 1 */
      for (ix = AMPLIFY_MP_DIGIT_BIT; ix < iy; ix++) {
         if ((a->dp[iw] & iz) == 0u) {
            return AMPLIFY_MP_NO;
         }
         iz <<= 1;
         if (iz > AMPLIFY_MP_DIGIT_MAX) {
            ++iw;
            iz = 1;
         }
      }
      return AMPLIFY_MP_YES;
   } else {
      return AMPLIFY_MP_YES;
   }
}

#endif
