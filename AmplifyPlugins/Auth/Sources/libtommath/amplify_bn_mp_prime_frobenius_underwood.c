#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_PRIME_FROBENIUS_UNDERWOOD_C

/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/*
 *  See file amplify_bn_mp_prime_is_prime.c or the documentation in doc/bn.tex for the details
 */
#ifndef LTM_USE_ONLY_MR

#ifdef AMPLIFY_MP_8BIT
/*
 * floor of positive solution of
 * (2^16)-1 = (a+4)*(2*a+5)
 * TODO: Both values are smaller than N^(1/4), would have to use a bigint
 *       for a instead but any a biger than about 120 are already so rare that
 *       it is possible to ignore them and still get enough pseudoprimes.
 *       But it is still a restriction of the set of available pseudoprimes
 *       which makes this implementation less secure if used stand-alone.
 */
#define LTM_FROBENIUS_UNDERWOOD_A 177
#else
#define LTM_FROBENIUS_UNDERWOOD_A 32764
#endif
amplify_mp_err amplify_mp_prime_frobenius_underwood(const amplify_mp_int *N, amplify_mp_bool *result)
{
   amplify_mp_int T1z, T2z, Np1z, sz, tz;

   int a, ap2, length, i, j;
   amplify_mp_err err;

   *result = AMPLIFY_MP_NO;

   if ((err = amplify_mp_init_multi(&T1z, &T2z, &Np1z, &sz, &tz, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   for (a = 0; a < LTM_FROBENIUS_UNDERWOOD_A; a++) {
      /* TODO: That's ugly! No, really, it is! */
      if ((a==2) || (a==4) || (a==7) || (a==8) || (a==10) ||
          (a==14) || (a==18) || (a==23) || (a==26) || (a==28)) {
         continue;
      }
      /* (32764^2 - 4) < 2^31, no bigint for >AMPLIFY_MP_8BIT needed) */
      amplify_mp_set_u32(&T1z, (uint32_t)a);

      if ((err = amplify_mp_sqr(&T1z, &T1z)) != AMPLIFY_MP_OKAY)                  goto LBL_FU_ERR;

      if ((err = amplify_mp_sub_d(&T1z, 4uL, &T1z)) != AMPLIFY_MP_OKAY)           goto LBL_FU_ERR;

      if ((err = amplify_mp_kronecker(&T1z, N, &j)) != AMPLIFY_MP_OKAY)           goto LBL_FU_ERR;

      if (j == -1) {
         break;
      }

      if (j == 0) {
         /* composite */
         goto LBL_FU_ERR;
      }
   }
   /* Tell it a composite and set return value accordingly */
   if (a >= LTM_FROBENIUS_UNDERWOOD_A) {
      err = AMPLIFY_MP_ITER;
      goto LBL_FU_ERR;
   }
   /* Composite if N and (a+4)*(2*a+5) are not coprime */
   amplify_mp_set_u32(&T1z, (uint32_t)((a+4)*((2*a)+5)));

   if ((err = amplify_mp_gcd(N, &T1z, &T1z)) != AMPLIFY_MP_OKAY)                  goto LBL_FU_ERR;

   if (!((T1z.used == 1) && (T1z.dp[0] == 1u)))                   goto LBL_FU_ERR;

   ap2 = a + 2;
   if ((err = amplify_amplify_mp_add_d(N, 1uL, &Np1z)) != AMPLIFY_MP_OKAY)                goto LBL_FU_ERR;

   amplify_mp_set(&sz, 1uL);
   amplify_mp_set(&tz, 2uL);
   length = amplify_mp_count_bits(&Np1z);

   for (i = length - 2; i >= 0; i--) {
      /*
       * temp = (sz*(a*sz+2*tz))%N;
       * tz   = ((tz-sz)*(tz+sz))%N;
       * sz   = temp;
       */
      if ((err = amplify_mp_mul_2(&tz, &T2z)) != AMPLIFY_MP_OKAY)                 goto LBL_FU_ERR;

      /* a = 0 at about 50% of the cases (non-square and odd input) */
      if (a != 0) {
         if ((err = amplify_mp_mul_d(&sz, (amplify_mp_digit)a, &T1z)) != AMPLIFY_MP_OKAY) goto LBL_FU_ERR;
         if ((err = amplify_mp_add(&T1z, &T2z, &T2z)) != AMPLIFY_MP_OKAY)         goto LBL_FU_ERR;
      }

      if ((err = amplify_mp_mul(&T2z, &sz, &T1z)) != AMPLIFY_MP_OKAY)             goto LBL_FU_ERR;
      if ((err = amplify_mp_sub(&tz, &sz, &T2z)) != AMPLIFY_MP_OKAY)              goto LBL_FU_ERR;
      if ((err = amplify_mp_add(&sz, &tz, &sz)) != AMPLIFY_MP_OKAY)               goto LBL_FU_ERR;
      if ((err = amplify_mp_mul(&sz, &T2z, &tz)) != AMPLIFY_MP_OKAY)              goto LBL_FU_ERR;
      if ((err = amplify_mp_mod(&tz, N, &tz)) != AMPLIFY_MP_OKAY)                 goto LBL_FU_ERR;
      if ((err = amplify_mp_mod(&T1z, N, &sz)) != AMPLIFY_MP_OKAY)                goto LBL_FU_ERR;
      if (amplify_s_mp_get_bit(&Np1z, (unsigned int)i) == AMPLIFY_MP_YES) {
         /*
          *  temp = (a+2) * sz + tz
          *  tz   = 2 * tz - sz
          *  sz   = temp
          */
         if (a == 0) {
            if ((err = amplify_mp_mul_2(&sz, &T1z)) != AMPLIFY_MP_OKAY)           goto LBL_FU_ERR;
         } else {
            if ((err = amplify_mp_mul_d(&sz, (amplify_mp_digit)ap2, &T1z)) != AMPLIFY_MP_OKAY) goto LBL_FU_ERR;
         }
         if ((err = amplify_mp_add(&T1z, &tz, &T1z)) != AMPLIFY_MP_OKAY)          goto LBL_FU_ERR;
         if ((err = amplify_mp_mul_2(&tz, &T2z)) != AMPLIFY_MP_OKAY)              goto LBL_FU_ERR;
         if ((err = amplify_mp_sub(&T2z, &sz, &tz)) != AMPLIFY_MP_OKAY)           goto LBL_FU_ERR;
         amplify_mp_exch(&sz, &T1z);
      }
   }

   amplify_mp_set_u32(&T1z, (uint32_t)((2 * a) + 5));
   if ((err = amplify_mp_mod(&T1z, N, &T1z)) != AMPLIFY_MP_OKAY)                  goto LBL_FU_ERR;
   if (AMPLIFY_MP_IS_ZERO(&sz) && (amplify_mp_cmp(&tz, &T1z) == AMPLIFY_MP_EQ)) {
      *result = AMPLIFY_MP_YES;
   }

LBL_FU_ERR:
   amplify_mp_clear_multi(&tz, &sz, &Np1z, &T2z, &T1z, NULL);
   return err;
}

#endif
#endif
