#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SIGNED_RSH_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* shift right by a certain bit count with sign extension */
amplify_mp_err amplify_amplify_mp_signed_rsh(const amplify_mp_int *a, int b, amplify_mp_int *c)
{
   amplify_mp_err res;
   if (a->sign == AMPLIFY_MP_ZPOS) {
      return amplify_mp_div_2d(a, b, c, NULL);
   }

   res = amplify_amplify_mp_add_d(a, 1uL, c);
   if (res != AMPLIFY_MP_OKAY) {
      return res;
   }

   res = amplify_mp_div_2d(c, b, c, NULL);
   return (res == AMPLIFY_MP_OKAY) ? amplify_mp_sub_d(c, 1uL, c) : res;
}
#endif
