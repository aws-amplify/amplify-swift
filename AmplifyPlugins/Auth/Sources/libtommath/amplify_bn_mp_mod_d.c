#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MOD_D_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

amplify_mp_err amplify_mp_mod_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_digit *c)
{
   return amplify_mp_div_d(a, b, NULL, c);
}
#endif
