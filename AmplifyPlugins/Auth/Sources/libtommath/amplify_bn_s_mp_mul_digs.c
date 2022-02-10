#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_MUL_DIGS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* multiplies |a| * |b| and only computes upto digs digits of result
 * HAC pp. 595, Algorithm 14.12  Modified so you can control how
 * many digits of output are created.
 */
amplify_mp_err amplify_s_mp_mul_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs)
{
   amplify_mp_int  t;
   amplify_mp_err  err;
   int     pa, pb, ix, iy;
   amplify_mp_digit u;
   amplify_mp_word r;
   amplify_mp_digit tmpx, *tmpt, *tmpy;

   /* can we use the fast multiplier? */
   if ((digs < AMPLIFY_MP_WARRAY) &&
       (AMPLIFY_MP_MIN(a->used, b->used) < AMPLIFY_MP_MAXFAST)) {
      return amplify_s_mp_mul_digs_fast(a, b, c, digs);
   }

   if ((err = amplify_mp_init_size(&t, digs)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   t.used = digs;

   /* compute the digits of the product directly */
   pa = a->used;
   for (ix = 0; ix < pa; ix++) {
      /* set the carry to zero */
      u = 0;

      /* limit ourselves to making digs digits of output */
      pb = AMPLIFY_MP_MIN(b->used, digs - ix);

      /* setup some aliases */
      /* copy of the digit from a used within the nested loop */
      tmpx = a->dp[ix];

      /* an alias for the destination shifted ix places */
      tmpt = t.dp + ix;

      /* an alias for the digits of b */
      tmpy = b->dp;

      /* compute the columns of the output and propagate the carry */
      for (iy = 0; iy < pb; iy++) {
         /* compute the column as a amplify_mp_word */
         r       = (amplify_mp_word)*tmpt +
                   ((amplify_mp_word)tmpx * (amplify_mp_word)*tmpy++) +
                   (amplify_mp_word)u;

         /* the new column is the lower part of the result */
         *tmpt++ = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);

         /* get the carry word from the result */
         u       = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);
      }
      /* set carry if it is placed below digs */
      if ((ix + iy) < digs) {
         *tmpt = u;
      }
   }

   amplify_mp_clamp(&t);
   amplify_mp_exch(&t, c);

   amplify_mp_clear(&t);
   return AMPLIFY_MP_OKAY;
}
#endif
