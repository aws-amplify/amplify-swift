#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SET_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* set to a digit */
void amplify_mp_set(amplify_mp_int *a, amplify_mp_digit b)
{
   a->dp[0] = b & AMPLIFY_MP_MASK;
   a->sign  = AMPLIFY_MP_ZPOS;
   a->used  = (a->dp[0] != 0u) ? 1 : 0;
   AMPLIFY_MP_ZERO_DIGITS(a->dp + a->used, a->alloc - a->used);
}
#endif
