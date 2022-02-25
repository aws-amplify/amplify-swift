#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_KRONECKER_C

/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/*
   Kronecker symbol (a|p)
   Straightforward implementation of algorithm 1.4.10 in
   Henri Cohen: "A Course in Computational Algebraic Number Theory"

   @book{cohen2013course,
     title={A course in computational algebraic number theory},
     author={Cohen, Henri},
     volume={138},
     year={2013},
     publisher={Springer Science \& Business Media}
    }
 */
amplify_mp_err amplify_mp_kronecker(const amplify_mp_int *a, const amplify_mp_int *p, int *c)
{
   amplify_mp_int a1, p1, r;
   amplify_mp_err err;
   int v, k;

   static const int table[8] = {0, 1, 0, -1, 0, -1, 0, 1};

   if (AMPLIFY_MP_IS_ZERO(p)) {
      if ((a->used == 1) && (a->dp[0] == 1u)) {
         *c = 1;
      } else {
         *c = 0;
      }
      return AMPLIFY_MP_OKAY;
   }

   if (AMPLIFY_MP_IS_EVEN(a) && AMPLIFY_MP_IS_EVEN(p)) {
      *c = 0;
      return AMPLIFY_MP_OKAY;
   }

   if ((err = amplify_mp_init_copy(&a1, a)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   if ((err = amplify_mp_init_copy(&p1, p)) != AMPLIFY_MP_OKAY) {
      goto LBL_KRON_0;
   }

   v = amplify_mp_cnt_lsb(&p1);
   if ((err = amplify_mp_div_2d(&p1, v, &p1, NULL)) != AMPLIFY_MP_OKAY) {
      goto LBL_KRON_1;
   }

   if ((v & 1) == 0) {
      k = 1;
   } else {
      k = table[a->dp[0] & 7u];
   }

   if (p1.sign == AMPLIFY_MP_NEG) {
      p1.sign = AMPLIFY_MP_ZPOS;
      if (a1.sign == AMPLIFY_MP_NEG) {
         k = -k;
      }
   }

   if ((err = amplify_mp_init(&r)) != AMPLIFY_MP_OKAY) {
      goto LBL_KRON_1;
   }

   for (;;) {
      if (AMPLIFY_MP_IS_ZERO(&a1)) {
         if (amplify_mp_cmp_d(&p1, 1uL) == AMPLIFY_MP_EQ) {
            *c = k;
            goto LBL_KRON;
         } else {
            *c = 0;
            goto LBL_KRON;
         }
      }

      v = amplify_mp_cnt_lsb(&a1);
      if ((err = amplify_mp_div_2d(&a1, v, &a1, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_KRON;
      }

      if ((v & 1) == 1) {
         k = k * table[p1.dp[0] & 7u];
      }

      if (a1.sign == AMPLIFY_MP_NEG) {
         /*
          * Compute k = (-1)^((a1)*(p1-1)/4) * k
          * a1.dp[0] + 1 cannot overflow because the MSB
          * of the type amplify_mp_digit is not set by definition
          */
         if (((a1.dp[0] + 1u) & p1.dp[0] & 2u) != 0u) {
            k = -k;
         }
      } else {
         /* compute k = (-1)^((a1-1)*(p1-1)/4) * k */
         if ((a1.dp[0] & p1.dp[0] & 2u) != 0u) {
            k = -k;
         }
      }

      if ((err = amplify_mp_copy(&a1, &r)) != AMPLIFY_MP_OKAY) {
         goto LBL_KRON;
      }
      r.sign = AMPLIFY_MP_ZPOS;
      if ((err = amplify_mp_mod(&p1, &r, &a1)) != AMPLIFY_MP_OKAY) {
         goto LBL_KRON;
      }
      if ((err = amplify_mp_copy(&r, &p1)) != AMPLIFY_MP_OKAY) {
         goto LBL_KRON;
      }
   }

LBL_KRON:
   amplify_mp_clear(&r);
LBL_KRON_1:
   amplify_mp_clear(&p1);
LBL_KRON_0:
   amplify_mp_clear(&a1);

   return err;
}

#endif
