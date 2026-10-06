#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_SETUP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* pre-calculate the value required for Barrett reduction
 * For a given modulus "b" it calulates the value required in "a"
 */
amplify_mp_err amplify_mp_reduce_setup(amplify_mp_int *a, const amplify_mp_int *b)
{
   amplify_mp_err err;
   if ((err = amplify_mp_2expt(a, b->used * 2 * AMPLIFY_MP_DIGIT_BIT)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   return amplify_mp_div(a, b, a, NULL);
}
#endif
