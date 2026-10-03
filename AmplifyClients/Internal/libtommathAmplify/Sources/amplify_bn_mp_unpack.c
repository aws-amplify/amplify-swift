#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_UNPACK_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* based on gmp's mpz_import.
 * see http://gmplib.org/manual/Integer-Import-and-Export.html
 */
amplify_mp_err amplify_mp_unpack(amplify_mp_int *rop, size_t count, amplify_mp_order order, size_t size,
                 amplify_mp_endian endian, size_t nails, const void *op)
{
   amplify_mp_err err;
   size_t odd_nails, nail_bytes, i, j;
   unsigned char odd_nail_mask;

   amplify_mp_zero(rop);

   if (endian == AMPLIFY_MP_NATIVE_ENDIAN) {
      AMPLIFY_MP_GET_ENDIANNESS(endian);
   }

   odd_nails = (nails % 8u);
   odd_nail_mask = 0xff;
   for (i = 0; i < odd_nails; ++i) {
      odd_nail_mask ^= (unsigned char)(1u << (7u - i));
   }
   nail_bytes = nails / 8u;

   for (i = 0; i < count; ++i) {
      for (j = 0; j < (size - nail_bytes); ++j) {
         unsigned char byte = *((const unsigned char *)op +
                                (((order == AMPLIFY_MP_MSB_FIRST) ? i : ((count - 1u) - i)) * size) +
                                ((endian == AMPLIFY_MP_BIG_ENDIAN) ? (j + nail_bytes) : (((size - 1u) - j) - nail_bytes)));

         if ((err = amplify_mp_mul_2d(rop, (j == 0u) ? (int)(8u - odd_nails) : 8, rop)) != AMPLIFY_MP_OKAY) {
            return err;
         }

         rop->dp[0] |= (j == 0u) ? (amplify_mp_digit)(byte & odd_nail_mask) : (amplify_mp_digit)byte;
         rop->used  += 1;
      }
   }

   amplify_mp_clamp(rop);

   return AMPLIFY_MP_OKAY;
}

#endif
