#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SET_DOUBLE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#if defined(__STDC_IEC_559__) || defined(__GCC_IEC_559)
amplify_mp_err amplify_mp_set_double(amplify_mp_int *a, double b)
{
   uint64_t frac;
   int exp;
   amplify_mp_err err;
   union {
      double   dbl;
      uint64_t bits;
   } cast;
   cast.dbl = b;

   exp = (int)((unsigned)(cast.bits >> 52) & 0x7FFu);
   frac = (cast.bits & ((1uLL << 52) - 1uLL)) | (1uLL << 52);

   if (exp == 0x7FF) { /* +-inf, NaN */
      return AMPLIFY_MP_VAL;
   }
   exp -= 1023 + 52;

   amplify_mp_set_u64(a, frac);

   err = (exp < 0) ? amplify_mp_div_2d(a, -exp, a, NULL) : amplify_mp_mul_2d(a, exp, a);
   if (err != AMPLIFY_MP_OKAY) {
      return err;
   }

   if (((cast.bits >> 63) != 0uLL) && !AMPLIFY_MP_IS_ZERO(a)) {
      a->sign = AMPLIFY_MP_NEG;
   }

   return AMPLIFY_MP_OKAY;
}
#endif
#endif
