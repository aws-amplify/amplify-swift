#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_INVMOD_FAST_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes the modular inverse via binary extended euclidean algorithm,
 * that is c = 1/a mod b
 *
 * Based on slow invmod except this is optimized for the case where b is
 * odd as per HAC Note 14.64 on pp. 610
 */
amplify_mp_err amplify_s_mp_invmod_fast(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_int  x, y, u, v, B, D;
   amplify_mp_sign neg;
   amplify_mp_err  err;

   /* 2. [modified] b must be odd   */
   if (AMPLIFY_MP_IS_EVEN(b)) {
      return AMPLIFY_MP_VAL;
   }

   /* init all our temps */
   if ((err = amplify_mp_init_multi(&x, &y, &u, &v, &B, &D, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* x == modulus, y == value to invert */
   if ((err = amplify_mp_copy(b, &x)) != AMPLIFY_MP_OKAY)                         goto LBL_ERR;

   /* we need y = |a| */
   if ((err = amplify_mp_mod(a, b, &y)) != AMPLIFY_MP_OKAY)                       goto LBL_ERR;

   /* if one of x,y is zero return an error! */
   if (AMPLIFY_MP_IS_ZERO(&x) || AMPLIFY_MP_IS_ZERO(&y)) {
      err = AMPLIFY_MP_VAL;
      goto LBL_ERR;
   }

   /* 3. u=x, v=y, A=1, B=0, C=0,D=1 */
   if ((err = amplify_mp_copy(&x, &u)) != AMPLIFY_MP_OKAY)                        goto LBL_ERR;
   if ((err = amplify_mp_copy(&y, &v)) != AMPLIFY_MP_OKAY)                        goto LBL_ERR;
   amplify_mp_set(&D, 1uL);

top:
   /* 4.  while u is even do */
   while (AMPLIFY_MP_IS_EVEN(&u)) {
      /* 4.1 u = u/2 */
      if ((err = amplify_mp_div_2(&u, &u)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;

      /* 4.2 if B is odd then */
      if (AMPLIFY_MP_IS_ODD(&B)) {
         if ((err = amplify_mp_sub(&B, &x, &B)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      }
      /* B = B/2 */
      if ((err = amplify_mp_div_2(&B, &B)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
   }

   /* 5.  while v is even do */
   while (AMPLIFY_MP_IS_EVEN(&v)) {
      /* 5.1 v = v/2 */
      if ((err = amplify_mp_div_2(&v, &v)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;

      /* 5.2 if D is odd then */
      if (AMPLIFY_MP_IS_ODD(&D)) {
         /* D = (D-x)/2 */
         if ((err = amplify_mp_sub(&D, &x, &D)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      }
      /* D = D/2 */
      if ((err = amplify_mp_div_2(&D, &D)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
   }

   /* 6.  if u >= v then */
   if (amplify_mp_cmp(&u, &v) != AMPLIFY_MP_LT) {
      /* u = u - v, B = B - D */
      if ((err = amplify_mp_sub(&u, &v, &u)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;

      if ((err = amplify_mp_sub(&B, &D, &B)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;
   } else {
      /* v - v - u, D = D - B */
      if ((err = amplify_mp_sub(&v, &u, &v)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;

      if ((err = amplify_mp_sub(&D, &B, &D)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;
   }

   /* if not zero goto step 4 */
   if (!AMPLIFY_MP_IS_ZERO(&u)) {
      goto top;
   }

   /* now a = C, b = D, gcd == g*v */

   /* if v != 1 then there is no inverse */
   if (amplify_mp_cmp_d(&v, 1uL) != AMPLIFY_MP_EQ) {
      err = AMPLIFY_MP_VAL;
      goto LBL_ERR;
   }

   /* b is now the inverse */
   neg = a->sign;
   while (D.sign == AMPLIFY_MP_NEG) {
      if ((err = amplify_mp_add(&D, b, &D)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
   }

   /* too big */
   while (amplify_mp_cmp_mag(&D, b) != AMPLIFY_MP_LT) {
      if ((err = amplify_mp_sub(&D, b, &D)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
   }

   amplify_mp_exch(&D, c);
   c->sign = neg;
   err = AMPLIFY_MP_OKAY;

LBL_ERR:
   amplify_mp_clear_multi(&x, &y, &u, &v, &B, &D, NULL);
   return err;
}
#endif
