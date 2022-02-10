#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_XOR_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* two complement xor */
amplify_mp_err amplify_mp_xor(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   int used = AMPLIFY_MP_MAX(a->used, b->used) + 1, i;
   amplify_mp_err err;
   amplify_mp_digit ac = 1, bc = 1, cc = 1;
   amplify_mp_sign csign = (a->sign != b->sign) ? AMPLIFY_MP_NEG : AMPLIFY_MP_ZPOS;

   if (c->alloc < used) {
      if ((err = amplify_mp_grow(c, used)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   for (i = 0; i < used; i++) {
      amplify_mp_digit x, y;

      /* convert to two complement if negative */
      if (a->sign == AMPLIFY_MP_NEG) {
         ac += (i >= a->used) ? AMPLIFY_MP_MASK : (~a->dp[i] & AMPLIFY_MP_MASK);
         x = ac & AMPLIFY_MP_MASK;
         ac >>= AMPLIFY_MP_DIGIT_BIT;
      } else {
         x = (i >= a->used) ? 0uL : a->dp[i];
      }

      /* convert to two complement if negative */
      if (b->sign == AMPLIFY_MP_NEG) {
         bc += (i >= b->used) ? AMPLIFY_MP_MASK : (~b->dp[i] & AMPLIFY_MP_MASK);
         y = bc & AMPLIFY_MP_MASK;
         bc >>= AMPLIFY_MP_DIGIT_BIT;
      } else {
         y = (i >= b->used) ? 0uL : b->dp[i];
      }

      c->dp[i] = x ^ y;

      /* convert to to sign-magnitude if negative */
      if (csign == AMPLIFY_MP_NEG) {
         cc += ~c->dp[i] & AMPLIFY_MP_MASK;
         c->dp[i] = cc & AMPLIFY_MP_MASK;
         cc >>= AMPLIFY_MP_DIGIT_BIT;
      }
   }

   c->used = used;
   c->sign = csign;
   amplify_mp_clamp(c);
   return AMPLIFY_MP_OKAY;
}
#endif
