#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MONTGOMERY_CALC_NORMALIZATION_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/*
 * shifts with subtractions when the result is greater than b.
 *
 * The method is slightly modified to shift B unconditionally upto just under
 * the leading bit of b.  This saves alot of multiple precision shifting.
 */
amplify_mp_err amplify_mp_montgomery_calc_normalization(amplify_mp_int *a, const amplify_mp_int *b)
{
   int    x, bits;
   amplify_mp_err err;

   /* how many bits of last digit does b use */
   bits = amplify_mp_count_bits(b) % AMPLIFY_MP_DIGIT_BIT;

   if (b->used > 1) {
      if ((err = amplify_mp_2expt(a, ((b->used - 1) * AMPLIFY_MP_DIGIT_BIT) + bits - 1)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   } else {
      amplify_mp_set(a, 1uL);
      bits = 1;
   }


   /* now compute C = A * B mod b */
   for (x = bits - 1; x < (int)AMPLIFY_MP_DIGIT_BIT; x++) {
      if ((err = amplify_mp_mul_2(a, a)) != AMPLIFY_MP_OKAY) {
         return err;
      }
      if (amplify_mp_cmp_mag(a, b) != AMPLIFY_MP_LT) {
         if ((err = amplify_s_mp_sub(a, b, a)) != AMPLIFY_MP_OKAY) {
            return err;
         }
      }
   }

   return AMPLIFY_MP_OKAY;
}
#endif
