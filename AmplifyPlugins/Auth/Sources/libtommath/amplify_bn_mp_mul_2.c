#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MUL_2_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* b = a*2 */
amplify_mp_err amplify_mp_mul_2(const amplify_mp_int *a, amplify_mp_int *b)
{
   int     x, oldused;
   amplify_mp_err err;

   /* grow to accomodate result */
   if (b->alloc < (a->used + 1)) {
      if ((err = amplify_mp_grow(b, a->used + 1)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   oldused = b->used;
   b->used = a->used;

   {
      amplify_mp_digit r, rr, *tmpa, *tmpb;

      /* alias for source */
      tmpa = a->dp;

      /* alias for dest */
      tmpb = b->dp;

      /* carry */
      r = 0;
      for (x = 0; x < a->used; x++) {

         /* get what will be the *next* carry bit from the
          * MSB of the current digit
          */
         rr = *tmpa >> (amplify_mp_digit)(AMPLIFY_MP_DIGIT_BIT - 1);

         /* now shift up this digit, add in the carry [from the previous] */
         *tmpb++ = ((*tmpa++ << 1uL) | r) & AMPLIFY_MP_MASK;

         /* copy the carry that would be from the source
          * digit into the next iteration
          */
         r = rr;
      }

      /* new leading digit? */
      if (r != 0u) {
         /* add a MSB which is always 1 at this point */
         *tmpb = 1;
         ++(b->used);
      }

      /* now zero any excess digits on the destination
       * that we didn't write to
       */
      AMPLIFY_MP_ZERO_DIGITS(b->dp + b->used, oldused - b->used);
   }
   b->sign = a->sign;
   return AMPLIFY_MP_OKAY;
}
#endif
