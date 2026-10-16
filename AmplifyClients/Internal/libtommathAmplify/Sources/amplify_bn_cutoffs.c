#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_CUTOFFS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#ifndef AMPLIFY_MP_FIXED_CUTOFFS
#include "amplify_tommath_cutoffs.h"
int AMPLIFY_KARATSUBA_MUL_CUTOFF = AMPLIFY_MP_DEFAULT_KARATSUBA_MUL_CUTOFF,
    AMPLIFY_KARATSUBA_SQR_CUTOFF = AMPLIFY_MP_DEFAULT_KARATSUBA_SQR_CUTOFF,
    AMPLIFY_TOOM_MUL_CUTOFF = AMPLIFY_MP_DEFAULT_TOOM_MUL_CUTOFF,
    AMPLIFY_TOOM_SQR_CUTOFF = AMPLIFY_MP_DEFAULT_TOOM_SQR_CUTOFF;
#endif

#endif
