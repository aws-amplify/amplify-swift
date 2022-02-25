#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ROOT_U32_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* find the n'th root of an integer
 *
 * Result found such that (c)**b <= a and (c+1)**b > a
 *
 * This algorithm uses Newton's approximation
 * x[i+1] = x[i] - f(x[i])/f'(x[i])
 * which will find the root in log(N) time where
 * each step involves a fair bit.
 */
amplify_mp_err amplify_mp_root_u32(const amplify_mp_int *a, uint32_t b, amplify_mp_int *c)
{
   amplify_mp_int t1, t2, t3, a_;
   amplify_mp_ord cmp;
   int    ilog2;
   amplify_mp_err err;

   /* input must be positive if b is even */
   if (((b & 1u) == 0u) && (a->sign == AMPLIFY_MP_NEG)) {
      return AMPLIFY_MP_VAL;
   }

   if ((err = amplify_mp_init_multi(&t1, &t2, &t3, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* if a is negative fudge the sign but keep track */
   a_ = *a;
   a_.sign = AMPLIFY_MP_ZPOS;

   /* Compute seed: 2^(log_2(n)/b + 2)*/
   ilog2 = amplify_mp_count_bits(a);

   /*
     If "b" is larger than INT_MAX it is also larger than
     log_2(n) because the bit-length of the "n" is measured
     with an int and hence the root is always < 2 (two).
   */
   if (b > (uint32_t)(INT_MAX/2)) {
      amplify_mp_set(c, 1uL);
      c->sign = a->sign;
      err = AMPLIFY_MP_OKAY;
      goto LBL_ERR;
   }

   /* "b" is smaller than INT_MAX, we can cast safely */
   if (ilog2 < (int)b) {
      amplify_mp_set(c, 1uL);
      c->sign = a->sign;
      err = AMPLIFY_MP_OKAY;
      goto LBL_ERR;
   }
   ilog2 =  ilog2 / ((int)b);
   if (ilog2 == 0) {
      amplify_mp_set(c, 1uL);
      c->sign = a->sign;
      err = AMPLIFY_MP_OKAY;
      goto LBL_ERR;
   }
   /* Start value must be larger than root */
   ilog2 += 2;
   if ((err = amplify_mp_2expt(&t2,ilog2)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
   do {
      /* t1 = t2 */
      if ((err = amplify_mp_copy(&t2, &t1)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;

      /* t2 = t1 - ((t1**b - a) / (b * t1**(b-1))) */

      /* t3 = t1**(b-1) */
      if ((err = amplify_mp_expt_u32(&t1, b - 1u, &t3)) != AMPLIFY_MP_OKAY)       goto LBL_ERR;

      /* numerator */
      /* t2 = t1**b */
      if ((err = amplify_mp_mul(&t3, &t1, &t2)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;

      /* t2 = t1**b - a */
      if ((err = amplify_mp_sub(&t2, &a_, &t2)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;

      /* denominator */
      /* t3 = t1**(b-1) * b  */
      if ((err = amplify_mp_mul_d(&t3, b, &t3)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;

      /* t3 = (t1**b - a)/(b * t1**(b-1)) */
      if ((err = amplify_mp_div(&t2, &t3, &t3, NULL)) != AMPLIFY_MP_OKAY)         goto LBL_ERR;

      if ((err = amplify_mp_sub(&t1, &t3, &t2)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;

      /*
          Number of rounds is at most log_2(root). If it is more it
          got stuck, so break out of the loop and do the rest manually.
       */
      if (ilog2-- == 0) {
         break;
      }
   }  while (amplify_mp_cmp(&t1, &t2) != AMPLIFY_MP_EQ);

   /* result can be off by a few so check */
   /* Loop beneath can overshoot by one if found root is smaller than actual root */
   for (;;) {
      if ((err = amplify_mp_expt_u32(&t1, b, &t2)) != AMPLIFY_MP_OKAY)            goto LBL_ERR;
      cmp = amplify_mp_cmp(&t2, &a_);
      if (cmp == AMPLIFY_MP_EQ) {
         err = AMPLIFY_MP_OKAY;
         goto LBL_ERR;
      }
      if (cmp == AMPLIFY_MP_LT) {
         if ((err = amplify_amplify_mp_add_d(&t1, 1uL, &t1)) != AMPLIFY_MP_OKAY)          goto LBL_ERR;
      } else {
         break;
      }
   }
   /* correct overshoot from above or from recurrence */
   for (;;) {
      if ((err = amplify_mp_expt_u32(&t1, b, &t2)) != AMPLIFY_MP_OKAY)            goto LBL_ERR;
      if (amplify_mp_cmp(&t2, &a_) == AMPLIFY_MP_GT) {
         if ((err = amplify_mp_sub_d(&t1, 1uL, &t1)) != AMPLIFY_MP_OKAY)          goto LBL_ERR;
      } else {
         break;
      }
   }

   /* set the result */
   amplify_mp_exch(&t1, c);

   /* set the sign of the result */
   c->sign = a->sign;

   err = AMPLIFY_MP_OKAY;

LBL_ERR:
   amplify_mp_clear_multi(&t1, &t2, &t3, NULL);
   return err;
}

#endif
