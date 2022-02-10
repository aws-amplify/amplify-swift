#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* reduces x mod m, assumes 0 < x < m**2, mu is
 * precomputed via amplify_mp_reduce_setup.
 * From HAC pp.604 Algorithm 14.42
 */
amplify_mp_err amplify_mp_reduce(amplify_mp_int *x, const amplify_mp_int *m, const amplify_mp_int *mu)
{
   amplify_mp_int  q;
   amplify_mp_err  err;
   int     um = m->used;

   /* q = x */
   if ((err = amplify_mp_init_copy(&q, x)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* q1 = x / b**(k-1)  */
   amplify_mp_rshd(&q, um - 1);

   /* according to HAC this optimization is ok */
   if ((amplify_mp_digit)um > ((amplify_mp_digit)1 << (AMPLIFY_MP_DIGIT_BIT - 1))) {
      if ((err = amplify_mp_mul(&q, mu, &q)) != AMPLIFY_MP_OKAY) {
         goto CLEANUP;
      }
   } else if (AMPLIFY_MP_HAS(S_MP_MUL_HIGH_DIGS)) {
      if ((err = amplify_s_mp_mul_high_digs(&q, mu, &q, um)) != AMPLIFY_MP_OKAY) {
         goto CLEANUP;
      }
   } else if (AMPLIFY_MP_HAS(S_MP_MUL_HIGH_DIGS_FAST)) {
      if ((err = amplify_s_mp_mul_high_digs_fast(&q, mu, &q, um)) != AMPLIFY_MP_OKAY) {
         goto CLEANUP;
      }
   } else {
      err = AMPLIFY_MP_VAL;
      goto CLEANUP;
   }

   /* q3 = q2 / b**(k+1) */
   amplify_mp_rshd(&q, um + 1);

   /* x = x mod b**(k+1), quick (no division) */
   if ((err = amplify_mp_mod_2d(x, AMPLIFY_MP_DIGIT_BIT * (um + 1), x)) != AMPLIFY_MP_OKAY) {
      goto CLEANUP;
   }

   /* q = q * m mod b**(k+1), quick (no division) */
   if ((err = amplify_s_mp_mul_digs(&q, m, &q, um + 1)) != AMPLIFY_MP_OKAY) {
      goto CLEANUP;
   }

   /* x = x - q */
   if ((err = amplify_mp_sub(x, &q, x)) != AMPLIFY_MP_OKAY) {
      goto CLEANUP;
   }

   /* If x < 0, add b**(k+1) to it */
   if (amplify_mp_cmp_d(x, 0uL) == AMPLIFY_MP_LT) {
      amplify_mp_set(&q, 1uL);
      if ((err = amplify_mp_lshd(&q, um + 1)) != AMPLIFY_MP_OKAY) {
         goto CLEANUP;
      }
      if ((err = amplify_mp_add(x, &q, x)) != AMPLIFY_MP_OKAY) {
         goto CLEANUP;
      }
   }

   /* Back off if it's too big */
   while (amplify_mp_cmp(x, m) != AMPLIFY_MP_LT) {
      if ((err = amplify_s_mp_sub(x, m, x)) != AMPLIFY_MP_OKAY) {
         goto CLEANUP;
      }
   }

CLEANUP:
   amplify_mp_clear(&q);

   return err;
}
#endif
