#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_RAND_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

amplify_mp_err(*amplify_s_mp_rand_source)(void *out, size_t size) = amplify_s_mp_rand_platform;

void amplify_mp_rand_source(amplify_mp_err(*source)(void *out, size_t size))
{
   amplify_s_mp_rand_source = (source == NULL) ? amplify_s_mp_rand_platform : source;
}

amplify_mp_err amplify_mp_rand(amplify_mp_int *a, int digits)
{
   int i;
   amplify_mp_err err;

   amplify_mp_zero(a);

   if (digits <= 0) {
      return AMPLIFY_MP_OKAY;
   }

   if ((err = amplify_mp_grow(a, digits)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_s_mp_rand_source(a->dp, (size_t)digits * sizeof(amplify_mp_digit))) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* TODO: We ensure that the highest digit is nonzero. Should this be removed? */
   while ((a->dp[digits - 1] & AMPLIFY_MP_MASK) == 0u) {
      if ((err = amplify_s_mp_rand_source(a->dp + digits - 1, sizeof(amplify_mp_digit))) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   a->used = digits;
   for (i = 0; i < digits; ++i) {
      a->dp[i] &= AMPLIFY_MP_MASK;
   }

   return AMPLIFY_MP_OKAY;
}
#endif
