#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_CMP_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* compare a digit */
amplify_mp_ord amplify_mp_cmp_d(const amplify_mp_int *a, amplify_mp_digit b)
{
   /* compare based on sign */
   if (a->sign == AMPLIFY_MP_NEG) {
      return AMPLIFY_MP_LT;
   }

   /* compare based on magnitude */
   if (a->used > 1) {
      return AMPLIFY_MP_GT;
   }

   /* compare the only digit of a to b */
   if (a->dp[0] > b) {
      return AMPLIFY_MP_GT;
   } else if (a->dp[0] < b) {
      return AMPLIFY_MP_LT;
   } else {
      return AMPLIFY_MP_EQ;
   }
}
#endif
