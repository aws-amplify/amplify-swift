#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_INVMOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* hac 14.61, pp608 */
amplify_mp_err amplify_mp_invmod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   /* b cannot be negative and has to be >1 */
   if ((b->sign == AMPLIFY_MP_NEG) || (amplify_mp_cmp_d(b, 1uL) != AMPLIFY_MP_GT)) {
      return AMPLIFY_MP_VAL;
   }

   /* if the modulus is odd we can use a faster routine instead */
   if (AMPLIFY_MP_HAS(S_MP_INVMOD_FAST) && AMPLIFY_MP_IS_ODD(b)) {
      return amplify_s_mp_invmod_fast(a, b, c);
   }

   return AMPLIFY_MP_HAS(S_MP_INVMOD_SLOW)
          ? amplify_s_mp_invmod_slow(a, b, c)
          : AMPLIFY_MP_VAL;
}
#endif
