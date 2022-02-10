#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_COMPLEMENT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* b = ~a */
amplify_mp_err amplify_mp_complement(const amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_err err = amplify_mp_neg(a, b);
   return (err == AMPLIFY_MP_OKAY) ? amplify_mp_sub_d(b, 1uL, b) : err;
}
#endif
