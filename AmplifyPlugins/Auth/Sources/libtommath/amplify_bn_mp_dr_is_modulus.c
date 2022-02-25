#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DR_IS_MODULUS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* determines if a number is a valid DR modulus */
amplify_mp_bool amplify_mp_dr_is_modulus(const amplify_mp_int *a)
{
   int ix;

   /* must be at least two digits */
   if (a->used < 2) {
      return AMPLIFY_MP_NO;
   }

   /* must be of the form b**k - a [a <= b] so all
    * but the first digit must be equal to -1 (mod b).
    */
   for (ix = 1; ix < a->used; ix++) {
      if (a->dp[ix] != AMPLIFY_MP_MASK) {
         return AMPLIFY_MP_NO;
      }
   }
   return AMPLIFY_MP_YES;
}

#endif
