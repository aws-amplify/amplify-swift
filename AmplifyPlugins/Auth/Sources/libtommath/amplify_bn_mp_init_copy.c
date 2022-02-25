#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_INIT_COPY_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* creates "a" then copies b into it */
amplify_mp_err amplify_mp_init_copy(amplify_mp_int *a, const amplify_mp_int *b)
{
   amplify_mp_err     err;

   if ((err = amplify_mp_init_size(a, b->used)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_copy(b, a)) != AMPLIFY_MP_OKAY) {
      amplify_mp_clear(a);
   }

   return err;
}
#endif
