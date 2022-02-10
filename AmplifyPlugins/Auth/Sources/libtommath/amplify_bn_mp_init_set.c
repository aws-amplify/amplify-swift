#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_INIT_SET_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* initialize and set a digit */
amplify_mp_err amplify_mp_init_set(amplify_mp_int *a, amplify_mp_digit b)
{
   amplify_mp_err err;
   if ((err = amplify_mp_init(a)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   amplify_mp_set(a, b);
   return err;
}
#endif
