#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_SQR_FAST_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* the jist of squaring...
 * you do like mult except the offset of the tmpx [one that
 * starts closer to zero] can't equal the offset of tmpy.
 * So basically you set up iy like before then you min it with
 * (ty-tx) so that it never happens.  You double all those
 * you add in the inner loop

After that loop you do the squares and add them in.
*/

amplify_mp_err amplify_s_mp_sqr_fast(const amplify_mp_int *a, amplify_mp_int *b)
{
   int       olduse, pa, ix, iz;
   amplify_mp_digit  W[AMPLIFY_MP_WARRAY], *tmpx;
   amplify_mp_word   W1;
   amplify_mp_err    err;

   /* grow the destination as required */
   pa = a->used + a->used;
   if (b->alloc < pa) {
      if ((err = amplify_mp_grow(b, pa)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* number of output digits to produce */
   W1 = 0;
   for (ix = 0; ix < pa; ix++) {
      int      tx, ty, iy;
      amplify_mp_word  _W;
      amplify_mp_digit *tmpy;

      /* clear counter */
      _W = 0;

      /* get offsets into the two bignums */
      ty = AMPLIFY_MP_MIN(a->used-1, ix);
      tx = ix - ty;

      /* setup temp aliases */
      tmpx = a->dp + tx;
      tmpy = a->dp + ty;

      /* this is the number of times the loop will iterrate, essentially
         while (tx++ < a->used && ty-- >= 0) { ... }
       */
      iy = AMPLIFY_MP_MIN(a->used-tx, ty+1);

      /* now for squaring tx can never equal ty
       * we halve the distance since they approach at a rate of 2x
       * and we have to round because odd cases need to be executed
       */
      iy = AMPLIFY_MP_MIN(iy, ((ty-tx)+1)>>1);

      /* execute loop */
      for (iz = 0; iz < iy; iz++) {
         _W += (amplify_mp_word)*tmpx++ * (amplify_mp_word)*tmpy--;
      }

      /* double the inner product and add carry */
      _W = _W + _W + W1;

      /* even columns have the square term in them */
      if (((unsigned)ix & 1u) == 0u) {
         _W += (amplify_mp_word)a->dp[ix>>1] * (amplify_mp_word)a->dp[ix>>1];
      }

      /* store it */
      W[ix] = (amplify_mp_digit)_W & AMPLIFY_MP_MASK;

      /* make next carry */
      W1 = _W >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT;
   }

   /* setup dest */
   olduse  = b->used;
   b->used = a->used+a->used;

   {
      amplify_mp_digit *tmpb;
      tmpb = b->dp;
      for (ix = 0; ix < pa; ix++) {
         *tmpb++ = W[ix] & AMPLIFY_MP_MASK;
      }

      /* clear unused digits [that existed in the old copy of c] */
      AMPLIFY_MP_ZERO_DIGITS(tmpb, olduse - ix);
   }
   amplify_mp_clamp(b);
   return AMPLIFY_MP_OKAY;
}
#endif
