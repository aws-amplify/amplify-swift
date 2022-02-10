#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_SQR_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* low level squaring, b = a*a, HAC pp.596-597, Algorithm 14.16 */
amplify_mp_err amplify_s_mp_sqr(const amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_int   t;
   int      ix, iy, pa;
   amplify_mp_err   err;
   amplify_mp_word  r;
   amplify_mp_digit u, tmpx, *tmpt;

   pa = a->used;
   if ((err = amplify_mp_init_size(&t, (2 * pa) + 1)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* default used is maximum possible size */
   t.used = (2 * pa) + 1;

   for (ix = 0; ix < pa; ix++) {
      /* first calculate the digit at 2*ix */
      /* calculate double precision result */
      r = (amplify_mp_word)t.dp[2*ix] +
          ((amplify_mp_word)a->dp[ix] * (amplify_mp_word)a->dp[ix]);

      /* store lower part in result */
      t.dp[ix+ix] = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);

      /* get the carry */
      u           = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);

      /* left hand side of A[ix] * A[iy] */
      tmpx        = a->dp[ix];

      /* alias for where to store the results */
      tmpt        = t.dp + ((2 * ix) + 1);

      for (iy = ix + 1; iy < pa; iy++) {
         /* first calculate the product */
         r       = (amplify_mp_word)tmpx * (amplify_mp_word)a->dp[iy];

         /* now calculate the double precision result, note we use
          * addition instead of *2 since it's easier to optimize
          */
         r       = (amplify_mp_word)*tmpt + r + r + (amplify_mp_word)u;

         /* store lower part */
         *tmpt++ = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);

         /* get carry */
         u       = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);
      }
      /* propagate upwards */
      while (u != 0uL) {
         r       = (amplify_mp_word)*tmpt + (amplify_mp_word)u;
         *tmpt++ = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);
         u       = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);
      }
   }

   amplify_mp_clamp(&t);
   amplify_mp_exch(&t, b);
   amplify_mp_clear(&t);
   return AMPLIFY_MP_OKAY;
}
#endif
