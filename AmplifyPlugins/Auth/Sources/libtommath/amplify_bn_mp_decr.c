#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DECR_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* Decrement "a" by one like "a--". Changes input! */
amplify_mp_err amplify_mp_decr(amplify_mp_int *a)
{
   if (AMPLIFY_MP_IS_ZERO(a)) {
      amplify_mp_set(a,1uL);
      a->sign = AMPLIFY_MP_NEG;
      return AMPLIFY_MP_OKAY;
   } else if (a->sign == AMPLIFY_MP_NEG) {
      amplify_mp_err err;
      a->sign = AMPLIFY_MP_ZPOS;
      if ((err = amplify_mp_incr(a)) != AMPLIFY_MP_OKAY) {
         return err;
      }
      /* There is no -0 in LTM */
      if (!AMPLIFY_MP_IS_ZERO(a)) {
         a->sign = AMPLIFY_MP_NEG;
      }
      return AMPLIFY_MP_OKAY;
   } else if (a->dp[0] > 1uL) {
      a->dp[0]--;
      if (a->dp[0] == 0u) {
         amplify_mp_zero(a);
      }
      return AMPLIFY_MP_OKAY;
   } else {
      return amplify_mp_sub_d(a, 1uL,a);
   }
}
#endif
