#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_2K_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* reduces a modulo n where n is of the form 2**p - d */
amplify_mp_err amplify_mp_reduce_2k(amplify_mp_int *a, const amplify_mp_int *n, amplify_mp_digit d)
{
   amplify_mp_int q;
   amplify_mp_err err;
   int    p;

   if ((err = amplify_mp_init(&q)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   p = amplify_mp_count_bits(n);
top:
   /* q = a/2**p, a = a mod 2**p */
   if ((err = amplify_mp_div_2d(a, p, &q, a)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

   if (d != 1u) {
      /* q = q * d */
      if ((err = amplify_mp_mul_d(&q, d, &q)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
   }

   /* a = a + q */
   if ((err = amplify_s_mp_add(a, &q, a)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

   if (amplify_mp_cmp_mag(a, n) != AMPLIFY_MP_LT) {
      if ((err = amplify_s_mp_sub(a, n, a)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      goto top;
   }

LBL_ERR:
   amplify_mp_clear(&q);
   return err;
}

#endif
