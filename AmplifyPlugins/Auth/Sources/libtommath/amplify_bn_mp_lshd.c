#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_LSHD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* shift left a certain amount of digits */
amplify_mp_err amplify_mp_lshd(amplify_mp_int *a, int b)
{
   int x;
   amplify_mp_err err;
   amplify_mp_digit *top, *bottom;

   /* if its less than zero return */
   if (b <= 0) {
      return AMPLIFY_MP_OKAY;
   }
   /* no need to shift 0 around */
   if (AMPLIFY_MP_IS_ZERO(a)) {
      return AMPLIFY_MP_OKAY;
   }

   /* grow to fit the new digits */
   if (a->alloc < (a->used + b)) {
      if ((err = amplify_mp_grow(a, a->used + b)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   }

   /* increment the used by the shift amount then copy upwards */
   a->used += b;

   /* top */
   top = a->dp + a->used - 1;

   /* base */
   bottom = (a->dp + a->used - 1) - b;

   /* much like amplify_mp_rshd this is implemented using a sliding window
    * except the window goes the otherway around.  Copying from
    * the bottom to the top.  see amplify_bn_mp_rshd.c for more info.
    */
   for (x = a->used - 1; x >= b; x--) {
      *top-- = *bottom--;
   }

   /* zero the lower digits */
   AMPLIFY_MP_ZERO_DIGITS(a->dp, b);

   return AMPLIFY_MP_OKAY;
}
#endif
