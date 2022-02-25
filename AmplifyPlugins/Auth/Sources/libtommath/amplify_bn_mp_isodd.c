#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ISODD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

amplify_mp_bool amplify_mp_isodd(const amplify_mp_int *a)
{
   return AMPLIFY_MP_IS_ODD(a) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
}
#endif
