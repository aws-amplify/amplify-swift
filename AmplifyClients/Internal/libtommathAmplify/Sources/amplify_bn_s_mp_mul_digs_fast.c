#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_MUL_DIGS_FAST_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* Fast (comba) multiplier
 *
 * This is the fast column-array [comba] multiplier.  It is
 * designed to compute the columns of the product first
 * then handle the carries afterwards.  This has the effect
 * of making the nested loops that compute the columns very
 * simple and schedulable on super-scalar processors.
 *
 * This has been modified to produce a variable number of
 * digits of output so if say only a half-product is required
 * you don't have to compute the upper half (a feature
 * required for fast Barrett reduction).
 *
 * Based on Algorithm 14.12 on pp.595 of HAC.
 *
 */
amplify_mp_err amplify_s_mp_mul_digs_fast(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs)
{
   int      olduse, pa, ix, iz;
   amplify_mp_err   err;
   amplify_mp_digit W[AMPLIFY_MP_WARRAY];
   amplify_mp_word  _W;

   /* grow the destination as required */
   if (c->alloc < digs) {
      if ((err = amplify_mp_grow(c, digs)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* number of output digits to produce */
   pa = AMPLIFY_MP_MIN(digs, a->used + b->used);

   /* clear the carry */
   _W = 0;
   for (ix = 0; ix < pa; ix++) {
      int      tx, ty;
      int      iy;
      amplify_mp_digit *tmpx, *tmpy;

      /* get offsets into the two bignums */
      ty = AMPLIFY_MP_MIN(b->used-1, ix);
      tx = ix - ty;

      /* setup temp aliases */
      tmpx = a->dp + tx;
      tmpy = b->dp + ty;

      /* this is the number of times the loop will iterrate, essentially
         while (tx++ < a->used && ty-- >= 0) { ... }
       */
      iy = AMPLIFY_MP_MIN(a->used-tx, ty+1);

      /* execute loop */
      for (iz = 0; iz < iy; ++iz) {
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
      tmpc = c->dp;
      for (ix = 0; ix < pa; ix++) {
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
