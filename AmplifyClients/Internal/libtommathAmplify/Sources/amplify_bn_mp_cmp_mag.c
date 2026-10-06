#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_CMP_MAG_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* compare maginitude of two ints (unsigned) */
amplify_mp_ord amplify_mp_cmp_mag(const amplify_mp_int *a, const amplify_mp_int *b)
{
   int     n;
   const amplify_mp_digit *tmpa, *tmpb;

   /* compare based on # of non-zero digits */
   if (a->used > b->used) {
      return AMPLIFY_MP_GT;
   }

   if (a->used < b->used) {
      return AMPLIFY_MP_LT;
   }

   /* alias for a */
   tmpa = a->dp + (a->used - 1);

   /* alias for b */
   tmpb = b->dp + (a->used - 1);

   /* compare based on digits  */
   for (n = 0; n < a->used; ++n, --tmpa, --tmpb) {
      if (*tmpa > *tmpb) {
         return AMPLIFY_MP_GT;
      }

      if (*tmpa < *tmpb) {
         return AMPLIFY_MP_LT;
      }
   }
   return AMPLIFY_MP_EQ;
}
#endif
