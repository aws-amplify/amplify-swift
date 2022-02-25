#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_GET_DOUBLE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

double amplify_mp_get_double(const amplify_mp_int *a)
{
   int i;
   double d = 0.0, fac = 1.0;
   for (i = 0; i < AMPLIFY_MP_DIGIT_BIT; ++i) {
      fac *= 2.0;
   }
   for (i = a->used; i --> 0;) {
      d = (d * fac) + (double)a->dp[i];
   }
   return (a->sign == AMPLIFY_MP_NEG) ? -d : d;
}
#endif
