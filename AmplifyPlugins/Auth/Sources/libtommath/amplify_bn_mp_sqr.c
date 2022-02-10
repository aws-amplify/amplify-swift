#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SQR_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes b = a*a */
amplify_mp_err amplify_mp_sqr(const amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_err err;
   if (AMPLIFY_MP_HAS(S_MP_TOOM_SQR) && /* use Toom-Cook? */
       (a->used >= AMPLIFY_MP_TOOM_SQR_CUTOFF)) {
      err = amplify_s_mp_toom_sqr(a, b);
   } else if (AMPLIFY_MP_HAS(S_MP_KARATSUBA_SQR) &&  /* Karatsuba? */
              (a->used >= AMPLIFY_MP_KARATSUBA_SQR_CUTOFF)) {
      err = amplify_s_mp_karatsuba_sqr(a, b);
   } else if (AMPLIFY_MP_HAS(S_MP_SQR_FAST) && /* can we use the fast comba multiplier? */
              (((a->used * 2) + 1) < AMPLIFY_MP_WARRAY) &&
              (a->used < (AMPLIFY_MP_MAXFAST / 2))) {
      err = amplify_s_mp_sqr_fast(a, b);
   } else if (AMPLIFY_MP_HAS(S_MP_SQR)) {
      err = amplify_s_mp_sqr(a, b);
   } else {
      err = AMPLIFY_MP_VAL;
   }
   b->sign = AMPLIFY_MP_ZPOS;
   return err;
}
#endif
