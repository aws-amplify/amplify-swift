#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SUB_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* single digit subtraction */
amplify_mp_err amplify_mp_sub_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c)
{
   amplify_mp_digit *tmpa, *tmpc;
   amplify_mp_err    err;
   int       ix, oldused;

   /* grow c as required */
   if (c->alloc < (a->used + 1)) {
      if ((err = amplify_mp_grow(c, a->used + 1)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* if a is negative just do an unsigned
    * addition [with fudged signs]
    */
   if (a->sign == AMPLIFY_MP_NEG) {
      amplify_mp_int a_ = *a;
      a_.sign = AMPLIFY_MP_ZPOS;
      err     = amplify_amplify_mp_add_d(&a_, b, c);
      c->sign = AMPLIFY_MP_NEG;

      /* clamp */
      amplify_mp_clamp(c);

      return err;
   }

   /* setup regs */
   oldused = c->used;
   tmpa    = a->dp;
   tmpc    = c->dp;

   /* if a <= b simply fix the single digit */
   if (((a->used == 1) && (a->dp[0] <= b)) || (a->used == 0)) {
      if (a->used == 1) {
         *tmpc++ = b - *tmpa;
      } else {
         *tmpc++ = b;
      }
      ix      = 1;

      /* negative/1digit */
      c->sign = AMPLIFY_MP_NEG;
      c->used = 1;
   } else {
      amplify_mp_digit mu = b;

      /* positive/size */
      c->sign = AMPLIFY_MP_ZPOS;
      c->used = a->used;

      /* subtract digits, mu is carry */
      for (ix = 0; ix < a->used; ix++) {
         *tmpc    = *tmpa++ - mu;
         mu       = *tmpc >> (AMPLIFY_MP_SIZEOF_BITS(amplify_mp_digit) - 1u);
         *tmpc++ &= AMPLIFY_MP_MASK;
      }
   }

   /* zero excess digits */
   AMPLIFY_MP_ZERO_DIGITS(tmpc, oldused - ix);

   amplify_mp_clamp(c);
   return AMPLIFY_MP_OKAY;
}

#endif
