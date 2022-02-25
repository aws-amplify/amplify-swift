#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ADD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* high level addition (handles signs) */
amplify_mp_err amplify_mp_add(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_sign sa, sb;
   amplify_mp_err err;

   /* get sign of both inputs */
   sa = a->sign;
   sb = b->sign;

   /* handle two cases, not four */
   if (sa == sb) {
      /* both positive or both negative */
      /* add their magnitudes, copy the sign */
      c->sign = sa;
      err = amplify_s_mp_add(a, b, c);
   } else {
      /* one positive, the other negative */
      /* subtract the one with the greater magnitude from */
      /* the one of the lesser magnitude.  The result gets */
      /* the sign of the one with the greater magnitude. */
      if (amplify_mp_cmp_mag(a, b) == AMPLIFY_MP_LT) {
         c->sign = sb;
         err = amplify_s_mp_sub(b, a, c);
      } else {
         c->sign = sa;
         err = amplify_s_mp_sub(a, b, c);
      }
   }
   return err;
}

#endif
