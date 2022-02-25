#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ADD_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* single digit addition */
amplify_mp_err amplify_amplify_mp_add_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c)
{
   amplify_mp_err     err;
   int ix, oldused;
   amplify_mp_digit *tmpa, *tmpc;

   /* grow c as required */
   if (c->alloc < (a->used + 1)) {
      if ((err = amplify_mp_grow(c, a->used + 1)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* if a is negative and |a| >= b, call c = |a| - b */
   if ((a->sign == AMPLIFY_MP_NEG) && ((a->used > 1) || (a->dp[0] >= b))) {
      amplify_mp_int a_ = *a;
      /* temporarily fix sign of a */
      a_.sign = AMPLIFY_MP_ZPOS;

      /* c = |a| - b */
      err = amplify_mp_sub_d(&a_, b, c);

      /* fix sign  */
      c->sign = AMPLIFY_MP_NEG;

      /* clamp */
      amplify_mp_clamp(c);

      return err;
   }

   /* old number of used digits in c */
   oldused = c->used;

   /* source alias */
   tmpa    = a->dp;

   /* destination alias */
   tmpc    = c->dp;

   /* if a is positive */
   if (a->sign == AMPLIFY_MP_ZPOS) {
      /* add digits, mu is carry */
      amplify_mp_digit mu = b;
      for (ix = 0; ix < a->used; ix++) {
         *tmpc   = *tmpa++ + mu;
         mu      = *tmpc >> AMPLIFY_MP_DIGIT_BIT;
         *tmpc++ &= AMPLIFY_MP_MASK;
      }
      /* set final carry */
      ix++;
      *tmpc++  = mu;

      /* setup size */
      c->used = a->used + 1;
   } else {
      /* a was negative and |a| < b */
      c->used  = 1;

      /* the result is a single digit */
      if (a->used == 1) {
         *tmpc++  =  b - a->dp[0];
      } else {
         *tmpc++  =  b;
      }

      /* setup count so the clearing of oldused
       * can fall through correctly
       */
      ix       = 1;
   }

   /* sign always positive */
   c->sign = AMPLIFY_MP_ZPOS;

   /* now zero to oldused */
   AMPLIFY_MP_ZERO_DIGITS(tmpc, oldused - ix);
   amplify_mp_clamp(c);

   return AMPLIFY_MP_OKAY;
}

#endif
