#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_FROM_SBIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* read signed bin, big endian, first byte is 0==positive or 1==negative */
amplify_mp_err amplify_mp_from_sbin(amplify_mp_int *a, const unsigned char *buf, size_t size)
{
   amplify_mp_err err;

   /* read magnitude */
   if ((err = amplify_mp_from_ubin(a, buf + 1, size - 1u)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* first byte is 0 for positive, non-zero for negative */
   if (buf[0] == (unsigned char)0) {
      a->sign = AMPLIFY_MP_ZPOS;
   } else {
      a->sign = AMPLIFY_MP_NEG;
   }

   return AMPLIFY_MP_OKAY;
}
#endif
