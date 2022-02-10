#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_GCD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Greatest Common Divisor using the binary method */
amplify_mp_err amplify_mp_gcd(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_int  u, v;
   int     k, u_lsb, v_lsb;
   amplify_mp_err err;

   /* either zero than gcd is the largest */
   if (AMPLIFY_MP_IS_ZERO(a)) {
      return amplify_mp_abs(b, c);
   }
   if (AMPLIFY_MP_IS_ZERO(b)) {
      return amplify_mp_abs(a, c);
   }

   /* get copies of a and b we can modify */
   if ((err = amplify_mp_init_copy(&u, a)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_init_copy(&v, b)) != AMPLIFY_MP_OKAY) {
      goto LBL_U;
   }

   /* must be positive for the remainder of the algorithm */
   u.sign = v.sign = AMPLIFY_MP_ZPOS;

   /* B1.  Find the common power of two for u and v */
   u_lsb = amplify_mp_cnt_lsb(&u);
   v_lsb = amplify_mp_cnt_lsb(&v);
   k     = AMPLIFY_MP_MIN(u_lsb, v_lsb);

   if (k > 0) {
      /* divide the power of two out */
      if ((err = amplify_mp_div_2d(&u, k, &u, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_V;
      }

      if ((err = amplify_mp_div_2d(&v, k, &v, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_V;
      }
   }

   /* divide any remaining factors of two out */
   if (u_lsb != k) {
      if ((err = amplify_mp_div_2d(&u, u_lsb - k, &u, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_V;
      }
   }

   if (v_lsb != k) {
      if ((err = amplify_mp_div_2d(&v, v_lsb - k, &v, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_V;
      }
   }

   while (!AMPLIFY_MP_IS_ZERO(&v)) {
      /* make sure v is the largest */
      if (amplify_mp_cmp_mag(&u, &v) == AMPLIFY_MP_GT) {
         /* swap u and v to make sure v is >= u */
         amplify_mp_exch(&u, &v);
      }

      /* subtract smallest from largest */
      if ((err = amplify_s_mp_sub(&v, &u, &v)) != AMPLIFY_MP_OKAY) {
         goto LBL_V;
      }

      /* Divide out all factors of two */
      if ((err = amplify_mp_div_2d(&v, amplify_mp_cnt_lsb(&v), &v, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_V;
      }
   }

   /* multiply by 2**k which we divided out at the beginning */
   if ((err = amplify_mp_mul_2d(&u, k, c)) != AMPLIFY_MP_OKAY) {
      goto LBL_V;
   }
   c->sign = AMPLIFY_MP_ZPOS;
   err = AMPLIFY_MP_OKAY;
LBL_V:
   amplify_mp_clear(&u);
LBL_U:
   amplify_mp_clear(&v);
   return err;
}
#endif
