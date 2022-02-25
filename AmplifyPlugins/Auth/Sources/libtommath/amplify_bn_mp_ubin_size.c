#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_UBIN_SIZE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* get the size for an unsigned equivalent */
size_t amplify_mp_ubin_size(const amplify_mp_int *a)
{
   size_t size = (size_t)amplify_mp_count_bits(a);
   return (size / 8u) + (((size & 7u) != 0u) ? 1u : 0u);
}
#endif
