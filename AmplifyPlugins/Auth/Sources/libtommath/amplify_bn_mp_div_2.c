#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DIV_2_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* b = a/2 */
amplify_mp_err amplify_mp_div_2(const amplify_mp_int *a, amplify_mp_int *b)
{
   int     x, oldused;
   amplify_mp_digit r, rr, *tmpa, *tmpb;
   amplify_mp_err err;

   /* copy */
   if (b->alloc < a->used) {
      if ((err = amplify_mp_grow(b, a->used)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   oldused = b->used;
   b->used = a->used;

   /* source alias */
   tmpa = a->dp + b->used - 1;

   /* dest alias */
   tmpb = b->dp + b->used - 1;

   /* carry */
   r = 0;
   for (x = b->used - 1; x >= 0; x--) {
      /* get the carry for the next iteration */
      rr = *tmpa & 1u;

      /* shift the current digit, add in carry and store */
      *tmpb-- = (*tmpa-- >> 1) | (r << (AMPLIFY_MP_DIGIT_BIT - 1));

      /* forward carry to next iteration */
      r = rr;
   }

   /* zero excess digits */
   AMPLIFY_MP_ZERO_DIGITS(b->dp + b->used, oldused - b->used);

   b->sign = a->sign;
   amplify_mp_clamp(b);
   return AMPLIFY_MP_OKAY;
}
#endif
