#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_CMP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* compare two ints (signed)*/
amplify_mp_ord amplify_mp_cmp(const amplify_mp_int *a, const amplify_mp_int *b)
{
   /* compare based on sign */
   if (a->sign != b->sign) {
      if (a->sign == AMPLIFY_MP_NEG) {
         return AMPLIFY_MP_LT;
      } else {
         return AMPLIFY_MP_GT;
      }
   }

   /* compare digits */
   if (a->sign == AMPLIFY_MP_NEG) {
      /* if negative compare opposite direction */
      return amplify_mp_cmp_mag(b, a);
   } else {
      return amplify_mp_cmp_mag(a, b);
   }
}
#endif
