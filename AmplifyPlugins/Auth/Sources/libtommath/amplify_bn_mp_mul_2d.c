#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MUL_2D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift left by a certain bit count */
amplify_mp_err amplify_mp_mul_2d(const amplify_mp_int *a, int b, amplify_mp_int *c)
{
   amplify_mp_digit d;
   amplify_mp_err   err;

   /* copy */
   if (a != c) {
      if ((err = amplify_mp_copy(a, c)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   if (c->alloc < (c->used + (b / AMPLIFY_MP_DIGIT_BIT) + 1)) {
      if ((err = amplify_mp_grow(c, c->used + (b / AMPLIFY_MP_DIGIT_BIT) + 1)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* shift by as many digits in the bit count */
   if (b >= AMPLIFY_MP_DIGIT_BIT) {
      if ((err = amplify_mp_lshd(c, b / AMPLIFY_MP_DIGIT_BIT)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* shift any bit count < AMPLIFY_MP_DIGIT_BIT */
   d = (amplify_mp_digit)(b % AMPLIFY_MP_DIGIT_BIT);
   if (d != 0u) {
      amplify_mp_digit *tmpc, shift, mask, r, rr;
      int x;

      /* bitmask for carries */
      mask = ((amplify_mp_digit)1 << d) - (amplify_mp_digit)1;

      /* shift for msbs */
      shift = (amplify_mp_digit)AMPLIFY_MP_DIGIT_BIT - d;

      /* alias */
      tmpc = c->dp;

      /* carry */
      r    = 0;
      for (x = 0; x < c->used; x++) {
         /* get the higher bits of the current word */
         rr = (*tmpc >> shift) & mask;

         /* shift the current word and OR in the carry */
         *tmpc = ((*tmpc << d) | r) & AMPLIFY_MP_MASK;
         ++tmpc;

         /* set the carry to the carry bits of the current word */
         r = rr;
      }

      /* set final carry */
      if (r != 0u) {
         c->dp[(c->used)++] = r;
      }
   }
   amplify_mp_clamp(c);
   return AMPLIFY_MP_OKAY;
}
#endif
