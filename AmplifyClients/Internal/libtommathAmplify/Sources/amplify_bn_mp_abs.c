#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ABS_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* b = |a|
 *
 * Simple function copies the input and fixes the sign to positive
 */
amplify_mp_err amplify_mp_abs(const amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_err     err;

   /* copy a to b */
   if (a != b) {
      if ((err = amplify_mp_copy(a, b)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* force the sign of b to positive */
   b->sign = AMPLIFY_MP_ZPOS;

   return AMPLIFY_MP_OKAY;
}
#endif
