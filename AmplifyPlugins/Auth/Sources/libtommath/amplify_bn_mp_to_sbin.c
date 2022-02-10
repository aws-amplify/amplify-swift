#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_TO_SBIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* store in signed [big endian] format */
amplify_mp_err amplify_mp_to_sbin(const amplify_mp_int *a, unsigned char *buf, size_t maxlen, size_t *written)
{
   amplify_mp_err err;
   if (maxlen == 0u) {
      return AMPLIFY_MP_BUF;
   }
   if ((err = amplify_mp_to_ubin(a, buf + 1, maxlen - 1u, written)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   if (written != NULL) {
      (*written)++;
   }
   buf[0] = (a->sign == AMPLIFY_MP_ZPOS) ? (unsigned char)0 : (unsigned char)1;
   return AMPLIFY_MP_OKAY;
}
#endif
