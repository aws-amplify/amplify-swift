#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MOD_2D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* calc a value mod 2**b */
amplify_mp_err amplify_mp_mod_2d(const amplify_mp_int *a, int b, amplify_mp_int *c)
{
   int x;
   amplify_mp_err err;

   /* if b is <= 0 then zero the int */
   if (b <= 0) {
      amplify_mp_zero(c);
      return AMPLIFY_MP_OKAY;
   }

   /* if the modulus is larger than the value than return */
   if (b >= (a->used * AMPLIFY_MP_DIGIT_BIT)) {
      return amplify_mp_copy(a, c);
   }

   /* copy */
   if ((err = amplify_mp_copy(a, c)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* zero digits above the last digit of the modulus */
   x = (b / AMPLIFY_MP_DIGIT_BIT) + (((b % AMPLIFY_MP_DIGIT_BIT) == 0) ? 0 : 1);
   AMPLIFY_MP_ZERO_DIGITS(c->dp + x, c->used - x);

   /* clear the digit that is not completely outside/inside the modulus */
   c->dp[b / AMPLIFY_MP_DIGIT_BIT] &=
      ((amplify_mp_digit)1 << (amplify_mp_digit)(b % AMPLIFY_MP_DIGIT_BIT)) - (amplify_mp_digit)1;
   amplify_mp_clamp(c);
   return AMPLIFY_MP_OKAY;
}
#endif
