#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_LCM_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes least common multiple as |a*b|/(a, b) */
amplify_mp_err amplify_mp_lcm(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_err  err;
   amplify_mp_int  t1, t2;


   if ((err = amplify_mp_init_multi(&t1, &t2, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* t1 = get the GCD of the two inputs */
   if ((err = amplify_mp_gcd(a, b, &t1)) != AMPLIFY_MP_OKAY) {
      goto LBL_T;
   }

   /* divide the smallest by the GCD */
   if (amplify_mp_cmp_mag(a, b) == AMPLIFY_MP_LT) {
      /* store quotient in t2 such that t2 * b is the LCM */
      if ((err = amplify_mp_div(a, &t1, &t2, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_T;
      }
      err = amplify_mp_mul(b, &t2, c);
   } else {
      /* store quotient in t2 such that t2 * a is the LCM */
      if ((err = amplify_mp_div(b, &t1, &t2, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_T;
      }
      err = amplify_mp_mul(a, &t2, c);
   }

   /* fix the sign to positive */
   c->sign = AMPLIFY_MP_ZPOS;

LBL_T:
   amplify_mp_clear_multi(&t1, &t2, NULL);
   return err;
}
#endif
