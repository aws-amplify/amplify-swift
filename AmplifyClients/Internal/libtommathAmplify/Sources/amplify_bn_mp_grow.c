#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_GROW_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* grow as required */
amplify_mp_err amplify_mp_grow(amplify_mp_int *a, int size)
{
   int     i;
   amplify_mp_digit *tmp;

   /* if the alloc size is smaller alloc more ram */
   if (a->alloc < size) {
      /* reallocate the array a->dp
       *
       * We store the return in a temporary variable
       * in case the operation failed we don't want
       * to overwrite the dp member of a.
       */
      tmp = (amplify_mp_digit *) AMPLIFY_MP_REALLOC(a->dp,
                                    (size_t)a->alloc * sizeof(amplify_mp_digit),
                                    (size_t)size * sizeof(amplify_mp_digit));
      if (tmp == NULL) {
         /* reallocation failed but "a" is still valid [can be freed] */
         return AMPLIFY_MP_MEM;
      }

      /* reallocation succeeded so set a->dp */
      a->dp = tmp;

      /* zero excess digits */
      i        = a->alloc;
      a->alloc = size;
      AMPLIFY_MP_ZERO_DIGITS(a->dp + i, a->alloc - i);
   }
   return AMPLIFY_MP_OKAY;
}
#endif
