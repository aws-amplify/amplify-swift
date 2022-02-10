#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_FREAD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

#ifndef AMPLIFY_MP_NO_FILE
/* read a bigint from a file stream in ASCII */
amplify_mp_err amplify_mp_fread(amplify_mp_int *a, int radix, FILE *stream)
{
   amplify_mp_err err;
   amplify_mp_sign neg;

   /* if first digit is - then set negative */
   int ch = fgetc(stream);
   if (ch == (int)'-') {
      neg = AMPLIFY_MP_NEG;
      ch = fgetc(stream);
   } else {
      neg = AMPLIFY_MP_ZPOS;
   }

   /* no digits, return error */
   if (ch == EOF) {
      return AMPLIFY_MP_ERR;
   }

   /* clear a */
   amplify_mp_zero(a);

   do {
      int y;
      unsigned pos = (unsigned)(ch - (int)'(');
      if (amplify_mp_s_rmap_reverse_sz < pos) {
         break;
      }

      y = (int)amplify_mp_s_rmap_reverse[pos];

      if ((y == 0xff) || (y >= radix)) {
         break;
      }

      /* shift up and add */
      if ((err = amplify_mp_mul_d(a, (amplify_mp_digit)radix, a)) != AMPLIFY_MP_OKAY) {
         return err;
      }
      if ((err = amplify_amplify_mp_add_d(a, (amplify_mp_digit)y, a)) != AMPLIFY_MP_OKAY) {
         return err;
      }
   } while ((ch = fgetc(stream)) != EOF);

   if (a->used != 0) {
      a->sign = neg;
   }

   return AMPLIFY_MP_OKAY;
}
#endif

#endif
