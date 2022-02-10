#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ZERO_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* set to zero */
void amplify_mp_zero(amplify_mp_int *a)
{
   a->sign = AMPLIFY_MP_ZPOS;
   a->used = 0;
   AMPLIFY_MP_ZERO_DIGITS(a->dp, a->alloc);
}
#endif
