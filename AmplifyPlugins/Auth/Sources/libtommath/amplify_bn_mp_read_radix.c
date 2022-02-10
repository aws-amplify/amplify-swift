#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_READ_RADIX_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#define AMPLIFY_MP_TOUPPER(c) ((((c) >= 'a') && ((c) <= 'z')) ? (((c) + 'A') - 'a') : (c))

/* read a string [ASCII] in a given radix */
amplify_mp_err amplify_mp_read_radix(amplify_mp_int *a, const char *str, int radix)
{
   amplify_mp_err   err;
   int      y;
   amplify_mp_sign  neg;
   unsigned pos;
   char     ch;

   /* zero the digit bignum */
   amplify_mp_zero(a);

   /* make sure the radix is ok */
   if ((radix < 2) || (radix > 64)) {
      return AMPLIFY_MP_VAL;
   }

   /* if the leading digit is a
    * minus set the sign to negative.
    */
   if (*str == '-') {
      ++str;
      neg = AMPLIFY_MP_NEG;
   } else {
      neg = AMPLIFY_MP_ZPOS;
   }

   /* set the integer to the default of zero */
   amplify_mp_zero(a);

   /* process each digit of the string */
   while (*str != '\0') {
      /* if the radix <= 36 the conversion is case insensitive
       * this allows numbers like 1AB and 1ab to represent the same  value
       * [e.g. in hex]
       */
      ch = (radix <= 36) ? (char)AMPLIFY_MP_TOUPPER((int)*str) : *str;
      pos = (unsigned)(ch - '(');
      if (amplify_mp_s_rmap_reverse_sz < pos) {
         break;
      }
      y = (int)amplify_mp_s_rmap_reverse[pos];

      /* if the char was found in the map
       * and is less than the given radix add it
       * to the number, otherwise exit the loop.
       */
      if ((y == 0xff) || (y >= radix)) {
         break;
      }
      if ((err = amplify_mp_mul_d(a, (amplify_mp_digit)radix, a)) != AMPLIFY_MP_OKAY) {
         return err;
      }
      if ((err = amplify_amplify_mp_add_d(a, (amplify_mp_digit)y, a)) != AMPLIFY_MP_OKAY) {
         return err;
      }
      ++str;
   }

   /* if an illegal character was found, fail. */
   if (!((*str == '\0') || (*str == '\r') || (*str == '\n'))) {
      amplify_mp_zero(a);
      return AMPLIFY_MP_VAL;
   }

   /* set the sign only if a != 0 */
   if (!AMPLIFY_MP_IS_ZERO(a)) {
      a->sign = neg;
   }
   return AMPLIFY_MP_OKAY;
}
#endif
