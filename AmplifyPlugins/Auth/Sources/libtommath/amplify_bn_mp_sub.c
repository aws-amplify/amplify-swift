#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SUB_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* high level subtraction (handles signs) */
amplify_mp_err amplify_mp_sub(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_sign sa = a->sign, sb = b->sign;
   amplify_mp_err err;

   if (sa != sb) {
      /* subtract a negative from a positive, OR */
      /* subtract a positive from a negative. */
      /* In either case, ADD their magnitudes, */
      /* and use the sign of the first number. */
      c->sign = sa;
      err = amplify_s_mp_add(a, b, c);
   } else {
      /* subtract a positive from a positive, OR */
      /* subtract a negative from a negative. */
      /* First, take the difference between their */
      /* magnitudes, then... */
      if (amplify_mp_cmp_mag(a, b) != AMPLIFY_MP_LT) {
         /* Copy the sign from the first */
         c->sign = sa;
         /* The first has a larger or equal magnitude */
         err = amplify_s_mp_sub(a, b, c);
      } else {
         /* The result has the *opposite* sign from */
         /* the first number. */
         c->sign = (sa == AMPLIFY_MP_ZPOS) ? AMPLIFY_MP_NEG : AMPLIFY_MP_ZPOS;
         /* The second has a larger magnitude */
         err = amplify_s_mp_sub(b, a, c);
      }
   }
   return err;
}

#endif
