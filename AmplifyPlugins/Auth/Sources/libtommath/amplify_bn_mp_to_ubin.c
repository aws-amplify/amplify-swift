#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_TO_UBIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* store in unsigned [big endian] format */
amplify_mp_err amplify_mp_to_ubin(const amplify_mp_int *a, unsigned char *buf, size_t maxlen, size_t *written)
{
   size_t  x, count;
   amplify_mp_err  err;
   amplify_mp_int  t;

   count = amplify_mp_ubin_size(a);
   if (count > maxlen) {
      return AMPLIFY_MP_BUF;
   }

   if ((err = amplify_mp_init_copy(&t, a)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   for (x = count; x --> 0u;) {
#ifndef AMPLIFY_MP_8BIT
      buf[x] = (unsigned char)(t.dp[0] & 255u);
#else
      buf[x] = (unsigned char)(t.dp[0] | ((t.dp[1] & 1u) << 7));
#endif
      if ((err = amplify_mp_div_2d(&t, 8, &t, NULL)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
   }

   if (written != NULL) {
      *written = count;
   }

LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}
#endif
