#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DIV_3_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* divide by three (based on routine from MPI and the GMP manual) */
amplify_mp_err amplify_mp_div_3(const amplify_mp_int *a, amplify_mp_int *c, amplify_mp_digit *d)
{
   amplify_mp_int   q;
   amplify_mp_word  w, t;
   amplify_mp_digit b;
   amplify_mp_err   err;
   int      ix;

   /* b = 2**AMPLIFY_MP_DIGIT_BIT / 3 */
   b = ((amplify_mp_word)1 << (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT) / (amplify_mp_word)3;

   if ((err = amplify_mp_init_size(&q, a->used)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   q.used = a->used;
   q.sign = a->sign;
   w = 0;
   for (ix = a->used - 1; ix >= 0; ix--) {
      w = (w << (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT) | (amplify_mp_word)a->dp[ix];

      if (w >= 3u) {
         /* multiply w by [1/3] */
         t = (w * (amplify_mp_word)b) >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT;

         /* now subtract 3 * [w/3] from w, to get the remainder */
         w -= t+t+t;

         /* fixup the remainder as required since
          * the optimization is not exact.
          */
         while (w >= 3u) {
            t += 1u;
            w -= 3u;
         }
      } else {
         t = 0;
      }
      q.dp[ix] = (amplify_mp_digit)t;
   }

   /* [optional] store the remainder */
   if (d != NULL) {
      *d = (amplify_mp_digit)w;
   }

   /* [optional] store the quotient */
   if (c != NULL) {
      amplify_mp_clamp(&q);
      amplify_mp_exch(&q, c);
   }
   amplify_mp_clear(&q);

   return err;
}

#endif
