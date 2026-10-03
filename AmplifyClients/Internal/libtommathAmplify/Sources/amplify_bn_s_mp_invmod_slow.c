#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_INVMOD_SLOW_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* hac 14.61, pp608 */
amplify_mp_err amplify_s_mp_invmod_slow(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_int  x, y, u, v, A, B, C, D;
   amplify_mp_err  err;

   /* b cannot be negative */
   if ((b->sign == AMPLIFY_MP_NEG) || AMPLIFY_MP_IS_ZERO(b)) {
      return AMPLIFY_MP_VAL;
   }

   /* init temps */
   if ((err = amplify_mp_init_multi(&x, &y, &u, &v,
                            &A, &B, &C, &D, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* x = a, y = b */
   if ((err = amplify_mp_mod(a, b, &x)) != AMPLIFY_MP_OKAY)                       goto LBL_ERR;
   if ((err = amplify_mp_copy(b, &y)) != AMPLIFY_MP_OKAY)                         goto LBL_ERR;

   /* 2. [modified] if x,y are both even then return an error! */
   if (AMPLIFY_MP_IS_EVEN(&x) && AMPLIFY_MP_IS_EVEN(&y)) {
      err = AMPLIFY_MP_VAL;
      goto LBL_ERR;
   }

   /* 3. u=x, v=y, A=1, B=0, C=0,D=1 */
   if ((err = amplify_mp_copy(&x, &u)) != AMPLIFY_MP_OKAY)                        goto LBL_ERR;
   if ((err = amplify_mp_copy(&y, &v)) != AMPLIFY_MP_OKAY)                        goto LBL_ERR;
   amplify_mp_set(&A, 1uL);
   amplify_mp_set(&D, 1uL);

top:
   /* 4.  while u is even do */
   while (AMPLIFY_MP_IS_EVEN(&u)) {
      /* 4.1 u = u/2 */
      if ((err = amplify_mp_div_2(&u, &u)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;

      /* 4.2 if A or B is odd then */
      if (AMPLIFY_MP_IS_ODD(&A) || AMPLIFY_MP_IS_ODD(&B)) {
         /* A = (A+y)/2, B = (B-x)/2 */
         if ((err = amplify_mp_add(&A, &y, &A)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
         if ((err = amplify_mp_sub(&B, &x, &B)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      }
      /* A = A/2, B = B/2 */
      if ((err = amplify_mp_div_2(&A, &A)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
      if ((err = amplify_mp_div_2(&B, &B)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
   }

   /* 5.  while v is even do */
   while (AMPLIFY_MP_IS_EVEN(&v)) {
      /* 5.1 v = v/2 */
      if ((err = amplify_mp_div_2(&v, &v)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;

      /* 5.2 if C or D is odd then */
      if (AMPLIFY_MP_IS_ODD(&C) || AMPLIFY_MP_IS_ODD(&D)) {
         /* C = (C+y)/2, D = (D-x)/2 */
         if ((err = amplify_mp_add(&C, &y, &C)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
         if ((err = amplify_mp_sub(&D, &x, &D)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      }
      /* C = C/2, D = D/2 */
      if ((err = amplify_mp_div_2(&C, &C)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
      if ((err = amplify_mp_div_2(&D, &D)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
   }

   /* 6.  if u >= v then */
   if (amplify_mp_cmp(&u, &v) != AMPLIFY_MP_LT) {
      /* u = u - v, A = A - C, B = B - D */
      if ((err = amplify_mp_sub(&u, &v, &u)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;

      if ((err = amplify_mp_sub(&A, &C, &A)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;

      if ((err = amplify_mp_sub(&B, &D, &B)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;
   } else {
      /* v - v - u, C = C - A, D = D - B */
      if ((err = amplify_mp_sub(&v, &u, &v)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;

      if ((err = amplify_mp_sub(&C, &A, &C)) != AMPLIFY_MP_OKAY)                  goto LBL_ERR;

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

   /* if its too low */
   while (amplify_mp_cmp_d(&C, 0uL) == AMPLIFY_MP_LT) {
      if ((err = amplify_mp_add(&C, b, &C)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
   }

   /* too big */
   while (amplify_mp_cmp_mag(&C, b) != AMPLIFY_MP_LT) {
      if ((err = amplify_mp_sub(&C, b, &C)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
   }

   /* C is now the inverse */
   amplify_mp_exch(&C, c);
   err = AMPLIFY_MP_OKAY;
LBL_ERR:
   amplify_mp_clear_multi(&x, &y, &u, &v, &A, &B, &C, &D, NULL);
   return err;
}
#endif
