#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_GET_BIT_C

/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Get bit at position b and return AMPLIFY_MP_YES if the bit is 1, AMPLIFY_MP_NO if it is 0 */
amplify_mp_bool amplify_s_mp_get_bit(const amplify_mp_int *a, unsigned int b)
{
   amplify_mp_digit bit;
   int limb = (int)(b / AMPLIFY_MP_DIGIT_BIT);

   if (limb >= a->used) {
      return AMPLIFY_MP_NO;
   }

   bit = (amplify_mp_digit)1 << (b % AMPLIFY_MP_DIGIT_BIT);
   return ((a->dp[limb] & bit) != 0u) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
}

#endif
