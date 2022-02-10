#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DIV_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* single digit division (based on routine from MPI) */
amplify_mp_err amplify_mp_div_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c, amplify_mp_digit *d)
{
   amplify_mp_int  q;
   amplify_mp_word w;
   amplify_mp_digit t;
   amplify_mp_err err;
   int ix;

   /* cannot divide by zero */
   if (b == 0u) {
      return AMPLIFY_MP_VAL;
   }

   /* quick outs */
   if ((b == 1u) || AMPLIFY_MP_IS_ZERO(a)) {
      if (d != NULL) {
         *d = 0;
      }
      if (c != NULL) {
         return amplify_mp_copy(a, c);
      }
      return AMPLIFY_MP_OKAY;
   }

   /* power of two ? */
   if ((b & (b - 1u)) == 0u) {
      ix = 1;
      while ((ix < AMPLIFY_MP_DIGIT_BIT) && (b != (((amplify_mp_digit)1)<<ix))) {
         ix++;
      }
      if (d != NULL) {
         *d = a->dp[0] & (((amplify_mp_digit)1<<(amplify_mp_digit)ix) - 1uL);
      }
      if (c != NULL) {
         return amplify_mp_div_2d(a, ix, c, NULL);
      }
      return AMPLIFY_MP_OKAY;
   }

   /* three? */
   if (AMPLIFY_MP_HAS(MP_DIV_3) && (b == 3u)) {
      return amplify_mp_div_3(a, c, d);
   }

   /* no easy answer [c'est la vie].  Just division */
   if ((err = amplify_mp_init_size(&q, a->used)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   q.used = a->used;
   q.sign = a->sign;
   w = 0;
   for (ix = a->used - 1; ix >= 0; ix--) {
      w = (w << (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT) | (amplify_mp_word)a->dp[ix];

      if (w >= b) {
         t = (amplify_mp_digit)(w / b);
         w -= (amplify_mp_word)t * (amplify_mp_word)b;
      } else {
         t = 0;
      }
      q.dp[ix] = t;
   }

   if (d != NULL) {
      *d = (amplify_mp_digit)w;
   }

   if (c != NULL) {
      amplify_mp_clamp(&q);
      amplify_mp_exch(&q, c);
   }
   amplify_mp_clear(&q);

   return err;
}

#endif
