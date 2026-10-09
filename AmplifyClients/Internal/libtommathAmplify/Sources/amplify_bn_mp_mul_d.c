#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MUL_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* multiply by a digit */
amplify_mp_err amplify_mp_mul_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c)
{
   amplify_mp_digit u, *tmpa, *tmpc;
   amplify_mp_word  r;
   amplify_mp_err   err;
   int      ix, olduse;

   /* make sure c is big enough to hold a*b */
   if (c->alloc < (a->used + 1)) {
      if ((err = amplify_mp_grow(c, a->used + 1)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* get the original destinations used count */
   olduse = c->used;

   /* set the sign */
   c->sign = a->sign;

   /* alias for a->dp [source] */
   tmpa = a->dp;

   /* alias for c->dp [dest] */
   tmpc = c->dp;

   /* zero carry */
   u = 0;

   /* compute columns */
   for (ix = 0; ix < a->used; ix++) {
      /* compute product and carry sum for this term */
      r       = (amplify_mp_word)u + ((amplify_mp_word)*tmpa++ * (amplify_mp_word)b);

      /* mask off higher bits to get a single digit */
      *tmpc++ = (amplify_mp_digit)(r & (amplify_mp_word)AMPLIFY_MP_MASK);

      /* send carry into next iteration */
      u       = (amplify_mp_digit)(r >> (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT);
   }

   /* store final carry [if any] and increment ix offset  */
   *tmpc++ = u;
   ++ix;

   /* now zero digits above the top */
   AMPLIFY_MP_ZERO_DIGITS(tmpc, olduse - ix);

   /* set used count */
   c->used = a->used + 1;
   amplify_mp_clamp(c);

   return AMPLIFY_MP_OKAY;
}
#endif
