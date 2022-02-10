#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SHRINK_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shrink a bignum */
amplify_mp_err amplify_mp_shrink(amplify_mp_int *a)
{
   amplify_mp_digit *tmp;
   int alloc = AMPLIFY_MP_MAX(AMPLIFY_MP_MIN_PREC, a->used);
   if (a->alloc != alloc) {
      if ((tmp = (amplify_mp_digit *) AMPLIFY_MP_REALLOC(a->dp,
                                         (size_t)a->alloc * sizeof(amplify_mp_digit),
                                         (size_t)alloc * sizeof(amplify_mp_digit))) == NULL) {
         return AMPLIFY_MP_MEM;
      }
      a->dp    = tmp;
      a->alloc = alloc;
   }
   return AMPLIFY_MP_OKAY;
}
#endif
