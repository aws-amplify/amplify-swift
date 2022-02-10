#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_MUL_HIGH_DIGS_FAST_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* this is a modified version of fast_s_mul_digs that only produces
 * output digits *above* digs.  See the comments for fast_s_mul_digs
 * to see how it works.
 *
 * This is used in the Barrett reduction since for one of the multiplications
 * only the higher digits were needed.  This essentially halves the work.
 *
 * Based on Algorithm 14.12 on pp.595 of HAC.
 */
amplify_mp_err amplify_s_mp_mul_high_digs_fast(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs)
{
   int     olduse, pa, ix, iz;
   amplify_mp_err   err;
   amplify_mp_digit W[AMPLIFY_MP_WARRAY];
   amplify_mp_word  _W;

   /* grow the destination as required */
   pa = a->used + b->used;
   if (c->alloc < pa) {
      if ((err = amplify_mp_grow(c, pa)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* number of output digits to produce */
   pa = a->used + b->used;
   _W = 0;
   for (ix = digs; ix < pa; ix++) {
      int      tx, ty, iy;
      amplify_mp_digit *tmpx, *tmpy;

      /* get offsets into the two bignums */
      ty = AMPLIFY_MP_MIN(b->used-1, ix);
      tx = ix - ty;

      /* setup temp aliases */
      tmpx = a->dp + tx;
      tmpy = b->dp + ty;

      /* this is the number of times the loop will iterrate, essentially its
         while (tx++ < a->used && ty-- >= 0) { ... }
       */
      iy = AMPLIFY_MP_MIN(a->used-tx, ty+1);

      /* execute loop */
      for (iz = 0; iz < iy; iz++) {
         _W += (amplify_mp_word)*tmpx++ * (amplify_mp_word)*tmpy--;
      }

      /* store term */
      W[ix] = (amplify_mp_digit)_W & AMPLIFY_MP_MASK;

      /* make next carry */
      _W = _W >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT;
   }

   /* setup dest */
   olduse  = c->used;
   c->used = pa;

   {
      amplify_mp_digit *tmpc;

      tmpc = c->dp + digs;
      for (ix = digs; ix < pa; ix++) {
         /* now extract the previous digit [below the carry] */
         *tmpc++ = W[ix];
      }

      /* clear unused digits [that existed in the old copy of c] */
      AMPLIFY_MP_ZERO_DIGITS(tmpc, olduse - ix);
   }
   amplify_mp_clamp(c);
   return AMPLIFY_MP_OKAY;
}
#endif
