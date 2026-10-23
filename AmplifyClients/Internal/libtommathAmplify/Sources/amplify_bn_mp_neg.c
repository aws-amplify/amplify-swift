#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_NEG_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* b = -a */
amplify_mp_err amplify_mp_neg(const amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_err err;
   if (a != b) {
      if ((err = amplify_mp_copy(a, b)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   if (!AMPLIFY_MP_IS_ZERO(b)) {
      b->sign = (a->sign == AMPLIFY_MP_ZPOS) ? AMPLIFY_MP_NEG : AMPLIFY_MP_ZPOS;
   } else {
      b->sign = AMPLIFY_MP_ZPOS;
   }

   return AMPLIFY_MP_OKAY;
}
#endif
