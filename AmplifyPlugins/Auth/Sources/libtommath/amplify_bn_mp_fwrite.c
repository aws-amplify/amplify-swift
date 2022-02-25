#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_FWRITE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#ifndef AMPLIFY_MP_NO_FILE
amplify_mp_err amplify_mp_fwrite(const amplify_mp_int *a, int radix, FILE *stream)
{
   char *buf;
   amplify_mp_err err;
   int len;
   size_t written;

   /* TODO: this function is not in this PR */
   if (AMPLIFY_MP_HAS(MP_RADIX_SIZE_OVERESTIMATE)) {
      /* if ((err = amplify_mp_radix_size_overestimate(&t, base, &len)) != AMPLIFY_MP_OKAY)      goto LBL_ERR; */
   } else {
      if ((err = amplify_mp_radix_size(a, radix, &len)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   buf = (char *) AMPLIFY_MP_MALLOC((size_t)len);
   if (buf == NULL) {
      return AMPLIFY_MP_MEM;
   }

   if ((err = amplify_mp_to_radix(a, buf, (size_t)len, &written, radix)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

   if (fwrite(buf, written, 1uL, stream) != 1uL) {
      err = AMPLIFY_MP_ERR;
      goto LBL_ERR;
   }
   err = AMPLIFY_MP_OKAY;


LBL_ERR:
   AMPLIFY_MP_FREE_BUFFER(buf, (size_t)len);
   return err;
}
#endif

#endif
