#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_INIT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* init a new amplify_mp_int */
amplify_mp_err amplify_mp_init(amplify_mp_int *a)
{
   /* allocate memory required and clear it */
   a->dp = (amplify_mp_digit *) AMPLIFY_MP_CALLOC((size_t)AMPLIFY_MP_PREC, sizeof(amplify_mp_digit));
   if (a->dp == NULL) {
      return AMPLIFY_MP_MEM;
   }

   /* set the used to zero, allocated digits to the default precision
    * and sign to positive */
   a->used  = 0;
   a->alloc = AMPLIFY_MP_PREC;
   a->sign  = AMPLIFY_MP_ZPOS;

   return AMPLIFY_MP_OKAY;
}
#endif
