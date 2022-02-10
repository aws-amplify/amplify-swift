#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_COPY_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* copy, b = a */
amplify_mp_err amplify_mp_copy(const amplify_mp_int *a, amplify_mp_int *b)
{
   int n;
   amplify_mp_digit *tmpa, *tmpb;
   amplify_mp_err err;

   /* if dst == src do nothing */
   if (a == b) {
      return AMPLIFY_MP_OKAY;
   }

   /* grow dest */
   if (b->alloc < a->used) {
      if ((err = amplify_mp_grow(b, a->used)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* zero b and copy the parameters over */
   /* pointer aliases */

   /* source */
   tmpa = a->dp;

   /* destination */
   tmpb = b->dp;

   /* copy all the digits */
   for (n = 0; n < a->used; n++) {
      *tmpb++ = *tmpa++;
   }

   /* clear high digits */
   AMPLIFY_MP_ZERO_DIGITS(tmpb, b->used - n);

   /* copy used count and sign */
   b->used = a->used;
   b->sign = a->sign;
   return AMPLIFY_MP_OKAY;
}
#endif
