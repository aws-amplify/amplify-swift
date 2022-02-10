#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_LOG_U32_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Compute log_{base}(a) */
static amplify_mp_word s_pow(amplify_mp_word base, amplify_mp_word exponent)
{
   amplify_mp_word result = 1uLL;
   while (exponent != 0u) {
      if ((exponent & 1u) == 1u) {
         result *= base;
      }
      exponent >>= 1;
      base *= base;
   }

   return result;
}

static amplify_mp_digit s_digit_ilogb(amplify_mp_digit base, amplify_mp_digit n)
{
   amplify_mp_word bracket_low = 1uLL, bracket_mid, bracket_high, N;
   amplify_mp_digit ret, high = 1uL, low = 0uL, mid;

   if (n < base) {
      return 0uL;
   }
   if (n == base) {
      return 1uL;
   }

   bracket_high = (amplify_mp_word) base ;
   N = (amplify_mp_word) n;

   while (bracket_high < N) {
      low = high;
      bracket_low = bracket_high;
      high <<= 1;
      bracket_high *= bracket_high;
   }

   while (((amplify_mp_digit)(high - low)) > 1uL) {
      mid = (low + high) >> 1;
      bracket_mid = bracket_low * s_pow(base, (amplify_mp_word)(mid - low));

      if (N < bracket_mid) {
         high = mid ;
         bracket_high = bracket_mid ;
      }
      if (N > bracket_mid) {
         low = mid ;
         bracket_low = bracket_mid ;
      }
      if (N == bracket_mid) {
         return (amplify_mp_digit) mid;
      }
   }

   if (bracket_high == N) {
      ret = high;
   } else {
      ret = low;
   }

   return ret;
}

/* TODO: output could be "int" because the output of amplify_mp_radix_size is int, too,
         as is the output of amplify_mp_bitcount.
         With the same problem: max size is INT_MAX * AMPLIFY_MP_DIGIT not INT_MAX only!
*/
amplify_mp_err amplify_mp_log_u32(const amplify_mp_int *a, uint32_t base, uint32_t *c)
{
   amplify_mp_err err;
   amplify_mp_ord cmp;
   uint32_t high, low, mid;
   amplify_mp_int bracket_low, bracket_high, bracket_mid, t, bi_base;

   err = AMPLIFY_MP_OKAY;

   if (a->sign == AMPLIFY_MP_NEG) {
      return AMPLIFY_MP_VAL;
   }

   if (AMPLIFY_MP_IS_ZERO(a)) {
      return AMPLIFY_MP_VAL;
   }

   if (base < 2u) {
      return AMPLIFY_MP_VAL;
   }

   /* A small shortcut for bases that are powers of two. */
   if ((base & (base - 1u)) == 0u) {
      int y, bit_count;
      for (y=0; (y < 7) && ((base & 1u) == 0u); y++) {
         base >>= 1;
      }
      bit_count = amplify_mp_count_bits(a) - 1;
      *c = (uint32_t)(bit_count/y);
      return AMPLIFY_MP_OKAY;
   }

   if (a->used == 1) {
      *c = (uint32_t)s_digit_ilogb(base, a->dp[0]);
      return err;
   }

   cmp = amplify_mp_cmp_d(a, base);
   if ((cmp == AMPLIFY_MP_LT) || (cmp == AMPLIFY_MP_EQ)) {
      *c = cmp == AMPLIFY_MP_EQ;
      return err;
   }

   if ((err =
           amplify_mp_init_multi(&bracket_low, &bracket_high,
                         &bracket_mid, &t, &bi_base, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   low = 0u;
   amplify_mp_set(&bracket_low, 1uL);
   high = 1u;

   amplify_mp_set(&bracket_high, base);

   /*
       A kind of Giant-step/baby-step algorithm.
       Idea shamelessly stolen from https://programmingpraxis.com/2010/05/07/integer-logarithms/2/
       The effect is asymptotic, hence needs benchmarks to test if the Giant-step should be skipped
       for small n.
    */
   while (amplify_mp_cmp(&bracket_high, a) == AMPLIFY_MP_LT) {
      low = high;
      if ((err = amplify_mp_copy(&bracket_high, &bracket_low)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      high <<= 1;
      if ((err = amplify_mp_sqr(&bracket_high, &bracket_high)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
   }
   amplify_mp_set(&bi_base, base);

   while ((high - low) > 1u) {
      mid = (high + low) >> 1;

      if ((err = amplify_mp_expt_u32(&bi_base, (uint32_t)(mid - low), &t)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      if ((err = amplify_mp_mul(&bracket_low, &t, &bracket_mid)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      cmp = amplify_mp_cmp(a, &bracket_mid);
      if (cmp == AMPLIFY_MP_LT) {
         high = mid;
         amplify_mp_exch(&bracket_mid, &bracket_high);
      }
      if (cmp == AMPLIFY_MP_GT) {
         low = mid;
         amplify_mp_exch(&bracket_mid, &bracket_low);
      }
      if (cmp == AMPLIFY_MP_EQ) {
         *c = mid;
         goto LBL_END;
      }
   }

   *c = (amplify_mp_cmp(&bracket_high, a) == AMPLIFY_MP_EQ) ? high : low;

LBL_END:
LBL_ERR:
   amplify_mp_clear_multi(&bracket_low, &bracket_high, &bracket_mid,
                  &t, &bi_base, NULL);
   return err;
}


#endif
