#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DR_REDUCE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* reduce "x" in place modulo "n" using the Diminished Radix algorithm.
 *
 * Based on algorithm from the paper
 *
 * "Generating Efficient Primes for Discrete Log Cryptosystems"
 *                 Chae Hoon Lim, Pil Joong Lee,
 *          POSTECH Information Research Laboratories
 *
 * The modulus must be of a special format [see manual]
 *
 * Has been modified to use algorithm 7.10 from the LTM book instead
 *
 * Input x must be in the range 0 <= x <= (n-1)**2
 */
amplify_mp_err amplify_mp_dr_reduce(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit k)
{
   amplify_mp_err      err;
   int i, m;
   amplify_mp_word  r;
   amplify_mp_digit mu, *tmpx1, *tmpx2;

   /* m = digits in modulus */
   m = n->used;

   /* ensure that "x" has at least 2m digits */
   if (x->alloc < (m + m)) {
      if ((err = amplify_mp_grow(x, m + m)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* top of loop, this is where the code resumes if
    * another reduction pass is required.
    */
top:
   /* aliases for digits */
   /* alias for lower half of x */
   tmpx1 = x->dp;

   /* alias for upper half of x, or x/B**m */
   tmpx2 = x->dp + m;

   /* set carry to zero */
   mu = 0;

   /* compute (x mod B**m) + k * [x/B**m] inline and inplace */
   for (i = 0; i < m; i++) {
      r         = ((amplify_mp_word)*tmpx2++ * (amplify_mp_word)k) + *tmpx1 + mu;
      *tmpx1++  = (amplify_mp_digit)(r & AMPLIFY_MP_MASK);
      mu        = (amplify_mp_digit)(r >> ((amplify_mp_word)AMPLIFY_MP_DIGIT_BIT));
   }

   /* set final carry */
   *tmpx1++ = mu;

   /* zero words above m */
   AMPLIFY_MP_ZERO_DIGITS(tmpx1, (x->used - m) - 1);

   /* clamp, sub and return */
   amplify_mp_clamp(x);

   /* if x >= n then subtract and reduce again
    * Each successive "recursion" makes the input smaller and smaller.
    */
   if (amplify_mp_cmp_mag(x, n) != AMPLIFY_MP_LT) {
      if ((err = amplify_s_mp_sub(x, n, x)) != AMPLIFY_MP_OKAY) {
         return err;
      }
      goto top;
   }
   return AMPLIFY_MP_OKAY;
}
#endif
