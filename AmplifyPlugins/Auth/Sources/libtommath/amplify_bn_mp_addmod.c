#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ADDMOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* d = a + b (mod c) */
amplify_mp_err amplify_mp_addmod(const amplify_mp_int *a, const amplify_mp_int *b, const amplify_mp_int *c, amplify_mp_int *d)
{
   amplify_mp_err  err;
   amplify_mp_int  t;

   if ((err = amplify_mp_init(&t)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_add(a, b, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }
   err = amplify_mp_mod(&t, c, d);

LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}
#endif
