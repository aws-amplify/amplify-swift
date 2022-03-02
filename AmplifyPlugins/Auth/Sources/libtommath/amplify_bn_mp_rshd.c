#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_RSHD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* shift right a certain amount of digits */
void amplify_mp_rshd(amplify_mp_int *a, int b)
{
   int     x;
   amplify_mp_digit *bottom, *top;

   /* if b <= 0 then ignore it */
   if (b <= 0) {
      return;
   }

   /* if b > used then simply zero it and return */
   if (a->used <= b) {
      amplify_mp_zero(a);
      return;
   }

   /* shift the digits down */

   /* bottom */
   bottom = a->dp;

   /* top [offset into digits] */
   top = a->dp + b;

   /* this is implemented as a sliding window where
    * the window is b-digits long and digits from
    * the top of the window are copied to the bottom
    *
    * e.g.

    b-2 | b-1 | b0 | b1 | b2 | ... | bb |   ---->
                /\                   |      ---->
                 \-------------------/      ---->
    */
   for (x = 0; x < (a->used - b); x++) {
      *bottom++ = *top++;
   }

   /* zero the top digits */
   AMPLIFY_MP_ZERO_DIGITS(bottom, a->used - x);

   /* remove excess digits */
   a->used -= b;
}
#endif
