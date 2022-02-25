#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_PACK_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* based on gmp's mpz_export.
 * see http://gmplib.org/manual/Integer-Import-and-Export.html
 */
amplify_mp_err amplify_mp_pack(void *rop, size_t maxcount, size_t *written, amplify_mp_order order, size_t size,
               amplify_mp_endian endian, size_t nails, const amplify_mp_int *op)
{
   amplify_mp_err err;
   size_t odd_nails, nail_bytes, i, j, count;
   unsigned char odd_nail_mask;

   amplify_mp_int t;

   count = amplify_mp_pack_count(op, nails, size);

   if (count > maxcount) {
      return AMPLIFY_MP_BUF;
   }

   if ((err = amplify_mp_init_copy(&t, op)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if (endian == AMPLIFY_MP_NATIVE_ENDIAN) {
      AMPLIFY_MP_GET_ENDIANNESS(endian);
   }

   odd_nails = (nails % 8u);
   odd_nail_mask = 0xff;
   for (i = 0u; i < odd_nails; ++i) {
      odd_nail_mask ^= (unsigned char)(1u << (7u - i));
   }
   nail_bytes = nails / 8u;

   for (i = 0u; i < count; ++i) {
      for (j = 0u; j < size; ++j) {
         unsigned char *byte = (unsigned char *)rop +
                               (((order == AMPLIFY_MP_LSB_FIRST) ? i : ((count - 1u) - i)) * size) +
                               ((endian == AMPLIFY_MP_LITTLE_ENDIAN) ? j : ((size - 1u) - j));

         if (j >= (size - nail_bytes)) {
            *byte = 0;
            continue;
         }

         *byte = (unsigned char)((j == ((size - nail_bytes) - 1u)) ? (t.dp[0] & odd_nail_mask) : (t.dp[0] & 0xFFuL));

         if ((err = amplify_mp_div_2d(&t, (j == ((size - nail_bytes) - 1u)) ? (int)(8u - odd_nails) : 8, &t, NULL)) != AMPLIFY_MP_OKAY) {
            goto LBL_ERR;
         }

      }
   }

   if (written != NULL) {
      *written = count;
   }
   err = AMPLIFY_MP_OKAY;

LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}

#endif
