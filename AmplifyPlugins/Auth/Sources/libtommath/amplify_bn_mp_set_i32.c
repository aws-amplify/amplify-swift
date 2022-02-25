#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SET_I32_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

AMPLIFY_MP_SET_SIGNED(amplify_mp_set_i32, amplify_mp_set_u32, int32_t, uint32_t)
#endif
