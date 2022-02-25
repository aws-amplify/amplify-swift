#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SBIN_SIZE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* get the size for an signed equivalent */
size_t amplify_mp_sbin_size(const amplify_mp_int *a)
{
   return 1u + amplify_mp_ubin_size(a);
}
#endif
