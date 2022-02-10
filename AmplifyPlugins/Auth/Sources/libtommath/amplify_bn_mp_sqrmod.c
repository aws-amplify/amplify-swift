#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SQRMOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* c = a * a (mod b) */
amplify_mp_err amplify_mp_sqrmod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   amplify_mp_err  err;
   amplify_mp_int  t;

   if ((err = amplify_mp_init(&t)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_sqr(a, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }
   err = amplify_mp_mod(&t, b, c);

LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}
#endif
