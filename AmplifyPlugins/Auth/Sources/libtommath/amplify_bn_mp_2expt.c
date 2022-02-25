#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_2EXPT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* computes a = 2**b
 *
 * Simple algorithm which zeroes the int, grows it then just sets one bit
 * as required.
 */
amplify_mp_err amplify_mp_2expt(amplify_mp_int *a, int b)
{
   amplify_mp_err    err;

   /* zero a as per default */
   amplify_mp_zero(a);

   /* grow a to accomodate the single bit */
   if ((err = amplify_mp_grow(a, (b / AMPLIFY_MP_DIGIT_BIT) + 1)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* set the used count of where the bit will go */
   a->used = (b / AMPLIFY_MP_DIGIT_BIT) + 1;

   /* put the single bit in its place */
   a->dp[b / AMPLIFY_MP_DIGIT_BIT] = (amplify_mp_digit)1 << (amplify_mp_digit)(b % AMPLIFY_MP_DIGIT_BIT);

   return AMPLIFY_MP_OKAY;
}
#endif
