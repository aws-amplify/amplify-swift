#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_MUL_HIGH_DIGS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* multiplies |a| * |b| and does not compute the lower digs digits
 * [meant to get the higher part of the product]
 */
amplify_mp_err amplify_s_mp_mul_high_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs)
{
   amplify_mp_int   t;
   int      pa, pb, ix, iy;
   amplify_mp_err   err;
   amplify_mp_digit u;
   amplify_mp_word  r;
   amplify_mp_digit tmpx, *tmpt, *tmpy;

   /* can we use the fast multiplier? */
   if (AMPLIFY_MP_HAS(S_MP_MUL_HIGH_DIGS_FAST)
       && ((a->used + b->used + 1) < AMPLIFY_MP_WARRAY)
       && (AMPLIFY_MP_MIN(a->used, b->used) < AMPLIFY_MP_MAXFAST)) {
      return amplify_s_mp_mul_high_digs_fast(a, b, c, digs);
   }

   if ((err = amplify_mp_init_size(&t, a->used + b->used + 1)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   t.used = a->used + b->used + 1;

   pa = a->used;
   pb = b->used;
   for (ix = 0; ix < pa; ix++) {
      /* clear the carry */
      u = 0;

      /* left hand side of A[ix] * B[iy] */
      tmpx = a->dp[ix];

      /* alias to the address of where the digits will be stored */
      tmpt = &(t.dp[digs]);

      /* alias for where to read the right hand side from */
      tmpy = b->dp + (digs - ix);

      for (iy = digs - ix; iy < pb; iy++) {
         /* calculate the double precision result */
         r       = (amplify_mp_word)*tmpt +
                   ((amplify_mp_word)tmpx * (amplify_mp_word)*tmpy++) +
                   (amplify_mp_word)u;

         /* get the lower part */
         *tmpt++ = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);

         /* carry the carry */
         u       = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);
      }
      *tmpt = u;
   }
   amplify_mp_clamp(&t);
   amplify_mp_exch(&t, c);
   amplify_mp_clear(&t);
   return AMPLIFY_MP_OKAY;
}
#endif
