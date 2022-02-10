#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_RADIX_SIZE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* returns size of ASCII representation */
amplify_mp_err amplify_mp_radix_size(const amplify_mp_int *a, int radix, int *size)
{
   amplify_mp_err  err;
   int digs;
   amplify_mp_int   t;
   amplify_mp_digit d;

   *size = 0;

   /* make sure the radix is in range */
   if ((radix < 2) || (radix > 64)) {
      return AMPLIFY_MP_VAL;
   }

   if (AMPLIFY_MP_IS_ZERO(a)) {
      *size = 2;
      return AMPLIFY_MP_OKAY;
   }

   /* special case for binary */
   if (radix == 2) {
      *size = (amplify_mp_count_bits(a) + ((a->sign == AMPLIFY_MP_NEG) ? 1 : 0) + 1);
      return AMPLIFY_MP_OKAY;
   }

   /* digs is the digit count */
   digs = 0;

   /* if it's negative add one for the sign */
   if (a->sign == AMPLIFY_MP_NEG) {
      ++digs;
   }

   /* init a copy of the input */
   if ((err = amplify_mp_init_copy(&t, a)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* force temp to positive */
   t.sign = AMPLIFY_MP_ZPOS;

   /* fetch out all of the digits */
   while (!AMPLIFY_MP_IS_ZERO(&t)) {
      if ((err = amplify_mp_div_d(&t, (amplify_mp_digit)radix, &t, &d)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }
      ++digs;
   }

   /* return digs + 1, the 1 is for the NULL byte that would be required. */
   *size = digs + 1;
   err = AMPLIFY_MP_OKAY;

LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}

#endif
