#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MONTGOMERY_REDUCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes xR**-1 == x (mod N) via Montgomery Reduction */
amplify_mp_err amplify_mp_montgomery_reduce(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit rho)
{
   int      ix, digs;
   amplify_mp_err   err;
   amplify_mp_digit mu;

   /* can the fast reduction [comba] method be used?
    *
    * Note that unlike in mul you're safely allowed *less*
    * than the available columns [255 per default] since carries
    * are fixed up in the inner loop.
    */
   digs = (n->used * 2) + 1;
   if ((digs < AMPLIFY_MP_WARRAY) &&
       (x->used <= AMPLIFY_MP_WARRAY) &&
       (n->used < AMPLIFY_MP_MAXFAST)) {
      return amplify_s_mp_montgomery_reduce_fast(x, n, rho);
   }

   /* grow the input as required */
   if (x->alloc < digs) {
      if ((err = amplify_mp_grow(x, digs)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }
   x->used = digs;

   for (ix = 0; ix < n->used; ix++) {
      /* mu = ai * rho mod b
       *
       * The value of rho must be precalculated via
       * montgomery_setup() such that
       * it equals -1/n0 mod b this allows the
       * following inner loop to reduce the
       * input one digit at a time
       */
      mu = (amplify_mp_digit)(((amplify_mp_word)x->dp[ix] * (amplify_mp_word)rho) & AMPLIFY_MP_MASK);

      /* a = a + mu * m * b**i */
      {
         int iy;
         amplify_mp_digit *tmpn, *tmpx, u;
         amplify_mp_word r;

         /* alias for digits of the modulus */
         tmpn = n->dp;

         /* alias for the digits of x [the input] */
         tmpx = x->dp + ix;

         /* set the carry to zero */
         u = 0;

         /* Multiply and add in place */
         for (iy = 0; iy < n->used; iy++) {
            /* compute product and sum */
            r       = ((amplify_mp_word)mu * (amplify_mp_word)*tmpn++) +
                      (amplify_mp_word)u + (amplify_mp_word)*tmpx;

            /* get carry */
            u       = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);

            /* fix digit */
            *tmpx++ = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);
         }
         /* At this point the ix'th digit of x should be zero */


         /* propagate carries upwards as required*/
         while (u != 0u) {
            *tmpx   += u;
            u        = *tmpx >> AMPLIFY_MP_DIGIT_BIT;
            *tmpx++ &= AMPLIFY_MP_MASK;
         }
      }
   }

   /* at this point the n.used'th least
    * significant digits of x are all zero
    * which means we can shift x to the
    * right by n.used digits and the
    * residue is unchanged.
    */

   /* x = x/b**n.used */
   amplify_mp_clamp(x);
   amplify_mp_rshd(x, n->used);

   /* if x >= n then x = x - n */
   if (amplify_mp_cmp_mag(x, n) != AMPLIFY_MP_LT) {
      return amplify_s_mp_sub(x, n, x);
   }

   return AMPLIFY_MP_OKAY;
}
#endif
