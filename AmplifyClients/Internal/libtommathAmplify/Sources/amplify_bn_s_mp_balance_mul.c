#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_BALANCE_MUL_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* single-digit multiplication with the smaller number as the single-digit */
amplify_mp_err s_amplify_mp_balance_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   int count, len_a, len_b, nblocks, i, j, bsize;
   amplify_mp_int a0, tmp, A, B, r;
   amplify_mp_err err;

   len_a = a->used;
   len_b = b->used;

   nblocks = AMPLIFY_MP_MAX(a->used, b->used) / AMPLIFY_MP_MIN(a->used, b->used);
   bsize = AMPLIFY_MP_MIN(a->used, b->used) ;

   if ((err = amplify_mp_init_size(&a0, bsize + 2)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   if ((err = amplify_mp_init_multi(&tmp, &r, NULL)) != AMPLIFY_MP_OKAY) {
      amplify_mp_clear(&a0);
      return err;
   }

   /* Make sure that A is the larger one*/
   if (len_a < len_b) {
      B = *a;
      A = *b;
   } else {
      A = *a;
      B = *b;
   }

   for (i = 0, j=0; i < nblocks; i++) {
      /* Cut a slice off of a */
      a0.used = 0;
      for (count = 0; count < bsize; count++) {
         a0.dp[count] = A.dp[ j++ ];
         a0.used++;
      }
      amplify_mp_clamp(&a0);
      /* Multiply with b */
      if ((err = amplify_mp_mul(&a0, &B, &tmp)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      /* Shift tmp to the correct position */
      if ((err = amplify_mp_lshd(&tmp, bsize * i)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      /* Add to output. No carry needed */
      if ((err = amplify_mp_add(&r, &tmp, &r)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
   }
   /* The left-overs; there are always left-overs */
   if (j < A.used) {
      a0.used = 0;
      for (count = 0; j < A.used; count++) {
         a0.dp[count] = A.dp[ j++ ];
         a0.used++;
      }
      amplify_mp_clamp(&a0);
      if ((err = amplify_mp_mul(&a0, &B, &tmp)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      if ((err = amplify_mp_lshd(&tmp, bsize * i)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      if ((err = amplify_mp_add(&r, &tmp, &r)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
   }

   amplify_mp_exch(&r,c);
LBL_ERR:
   amplify_mp_clear_multi(&a0, &tmp, &r,NULL);
   return err;
}
#endif
