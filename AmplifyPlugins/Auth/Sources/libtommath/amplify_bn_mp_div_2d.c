#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DIV_2D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift right by a certain bit count (store quotient in c, optional remainder in d) */
amplify_mp_err amplify_mp_div_2d(const amplify_mp_int *a, int b, amplify_mp_int *c, amplify_mp_int *d)
{
   amplify_mp_digit D, r, rr;
   int     x;
   amplify_mp_err err;

   /* if the shift count is <= 0 then we do no work */
   if (b <= 0) {
      err = amplify_mp_copy(a, c);
      if (d != NULL) {
         amplify_mp_zero(d);
      }
      return err;
   }

   /* copy */
   if ((err = amplify_mp_copy(a, c)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   /* 'a' should not be used after here - it might be the same as d */

   /* get the remainder */
   if (d != NULL) {
      if ((err = amplify_mp_mod_2d(a, b, d)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* shift by as many digits in the bit count */
   if (b >= AMPLIFY_MP_DIGIT_BIT) {
      amplify_mp_rshd(c, b / AMPLIFY_MP_DIGIT_BIT);
   }

   /* shift any bit count < AMPLIFY_MP_DIGIT_BIT */
   D = (amplify_mp_digit)(b % AMPLIFY_MP_DIGIT_BIT);
   if (D != 0u) {
      amplify_mp_digit *tmpc, mask, shift;

      /* mask */
      mask = ((amplify_mp_digit)1 << D) - 1uL;

      /* shift for lsb */
      shift = (amplify_mp_digit)AMPLIFY_MP_DIGIT_BIT - D;

      /* alias */
      tmpc = c->dp + (c->used - 1);

      /* carry */
      r = 0;
      for (x = c->used - 1; x >= 0; x--) {
         /* get the lower  bits of this word in a temp */
         rr = *tmpc & mask;

         /* shift the current word and mix in the carry bits from the previous word */
         *tmpc = (*tmpc >> D) | (r << shift);
         --tmpc;

         /* set the carry to the carry bits of the current word found above */
         r = rr;
      }
   }
   amplify_mp_clamp(c);
   return AMPLIFY_MP_OKAY;
}
#endif
