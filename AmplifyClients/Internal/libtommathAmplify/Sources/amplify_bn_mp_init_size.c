#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_INIT_SIZE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* init an amplify_mp_init for a given size */
amplify_mp_err amplify_mp_init_size(amplify_mp_int *a, int size)
{
   size = AMPLIFY_MP_MAX(AMPLIFY_MP_MIN_PREC, size);

   /* alloc mem */
   a->dp = (amplify_mp_digit *) AMPLIFY_MP_CALLOC((size_t)size, sizeof(amplify_mp_digit));
   if (a->dp == NULL) {
      return AMPLIFY_MP_MEM;
   }

   /* set the members */
   a->used  = 0;
   a->alloc = size;
   a->sign  = AMPLIFY_MP_ZPOS;

   return AMPLIFY_MP_OKAY;
}
#endif
