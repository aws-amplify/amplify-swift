#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* c = a mod b, 0 <= c < b if b > 0, b < c <= 0 if b < 0 */
amplify_mp_err amplify_mp_mod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_int  t;
   amplify_mp_err  err;

   if ((err = amplify_mp_init_size(&t, b->used)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_div(a, b, NULL, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

   if (AMPLIFY_MP_IS_ZERO(&t) || (t.sign == b->sign)) {
      err = AMPLIFY_MP_OKAY;
      amplify_mp_exch(&t, c);
   } else {
      err = amplify_mp_add(b, &t, c);
   }

LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}
#endif
