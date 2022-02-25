#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DR_SETUP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* determines the setup value */
void amplify_mp_dr_setup(const amplify_mp_int *a, amplify_mp_digit *d)
{
   /* the casts are required if AMPLIFY_MP_DIGIT_BIT is one less than
    * the number of bits in a amplify_mp_digit [e.g. AMPLIFY_MP_DIGIT_BIT==31]
    */
   *d = (amplify_mp_digit)(((amplify_mp_word)1 << (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT) - (amplify_mp_word)a->dp[0]);
}

#endif
