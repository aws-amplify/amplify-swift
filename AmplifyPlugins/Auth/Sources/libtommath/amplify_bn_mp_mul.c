#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MUL_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* high level multiplication (handles sign) */
amplify_mp_err amplify_mp_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_err err;
   int min_len = AMPLIFY_MP_MIN(a->used, b->used),
       max_len = AMPLIFY_MP_MAX(a->used, b->used),
       digs = a->used + b->used + 1;
   amplify_mp_sign neg = (a->sign == b->sign) ? AMPLIFY_MP_ZPOS : AMPLIFY_MP_NEG;

   if (AMPLIFY_MP_HAS(S_MP_BALANCE_MUL) &&
       /* Check sizes. The smaller one needs to be larger than the Karatsuba cut-off.
        * The bigger one needs to be at least about one AMPLIFY_MP_KARATSUBA_MUL_CUTOFF bigger
        * to make some sense, but it depends on architecture, OS, position of the
        * stars... so YMMV.
        * Using it to cut the input into slices small enough for amplify_fast_s_mp_mul_digs
        * was actually slower on the author's machine, but YMMV.
        */
       (min_len >= AMPLIFY_MP_KARATSUBA_MUL_CUTOFF) &&
       ((max_len / 2) >= AMPLIFY_MP_KARATSUBA_MUL_CUTOFF) &&
       /* Not much effect was observed below a ratio of 1:2, but again: YMMV. */
       (max_len >= (2 * min_len))) {
      err = s_amplify_mp_balance_mul(a,b,c);
   } else if (AMPLIFY_MP_HAS(S_MP_TOOM_MUL) &&
              (min_len >= AMPLIFY_MP_TOOM_MUL_CUTOFF)) {
      err = amplify_s_mp_toom_mul(a, b, c);
   } else if (AMPLIFY_MP_HAS(S_MP_KARATSUBA_MUL) &&
              (min_len >= AMPLIFY_MP_KARATSUBA_MUL_CUTOFF)) {
      err = amplify_s_mp_karatsuba_mul(a, b, c);
   } else if (AMPLIFY_MP_HAS(S_MP_MUL_DIGS_FAST) &&
              /* can we use the fast multiplier?
               *
               * The fast multiplier can be used if the output will
               * have less than AMPLIFY_MP_WARRAY digits and the number of
               * digits won't affect carry propagation
               */
              (digs < AMPLIFY_MP_WARRAY) &&
              (min_len <= AMPLIFY_MP_MAXFAST)) {
      err = amplify_s_mp_mul_digs_fast(a, b, c, digs);
   } else if (AMPLIFY_MP_HAS(S_MP_MUL_DIGS)) {
      err = amplify_s_mp_mul_digs(a, b, c, digs);
   } else {
      err = AMPLIFY_MP_VAL;
   }
   c->sign = (c->used > 0) ? neg : AMPLIFY_MP_ZPOS;
   return err;
}
#endif
