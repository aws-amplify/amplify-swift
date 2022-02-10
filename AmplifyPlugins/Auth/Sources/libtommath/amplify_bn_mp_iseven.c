#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ISEVEN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

amplify_mp_bool amplify_mp_iseven(const amplify_mp_int *a)
{
   return AMPLIFY_MP_IS_EVEN(a) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
}
#endif
