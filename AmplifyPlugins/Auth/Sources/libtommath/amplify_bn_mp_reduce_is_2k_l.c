#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_IS_2K_L_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* determines if reduce_2k_l can be used */
amplify_mp_bool amplify_mp_reduce_is_2k_l(const amplify_mp_int *a)
{
   int ix, iy;

   if (a->used == 0) {
      return AMPLIFY_MP_NO;
   } else if (a->used == 1) {
      return AMPLIFY_MP_YES;
   } else if (a->used > 1) {
      /* if more than half of the digits are -1 we're sold */
      for (iy = ix = 0; ix < a->used; ix++) {
         if (a->dp[ix] == AMPLIFY_MP_DIGIT_MAX) {
            ++iy;
         }
      }
      return (iy >= (a->used/2)) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
   } else {
      return AMPLIFY_MP_NO;
   }
}

#endif
