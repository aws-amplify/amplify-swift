#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_CLEAR_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* clear one (frees)  */
void amplify_mp_clear(amplify_mp_int *a)
{
   /* only do anything if a hasn't been freed previously */
   if (a->dp != NULL) {
      /* free ram */
      AMPLIFY_MP_FREE_DIGITS(a->dp, a->alloc);

      /* reset members to make debugging easier */
      a->dp    = NULL;
      a->alloc = a->used = 0;
      a->sign  = AMPLIFY_MP_ZPOS;
   }
}
#endif
