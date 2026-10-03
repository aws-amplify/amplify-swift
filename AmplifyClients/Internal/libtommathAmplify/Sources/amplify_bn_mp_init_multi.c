#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_INIT_MULTI_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#include <stdarg.h>

amplify_mp_err amplify_mp_init_multi(amplify_mp_int *mp, ...)
{
   amplify_mp_err err = AMPLIFY_MP_OKAY;      /* Assume ok until proven otherwise */
   int n = 0;                 /* Number of ok inits */
   amplify_mp_int *cur_arg = mp;
   va_list args;

   va_start(args, mp);        /* init args to next argument from caller */
   while (cur_arg != NULL) {
      if (amplify_mp_init(cur_arg) != AMPLIFY_MP_OKAY) {
         /* Oops - error! Back-track and amplify_mp_clear what we already
            succeeded in init-ing, then return error.
         */
         va_list clean_args;

         /* now start cleaning up */
         cur_arg = mp;
         va_start(clean_args, mp);
         while (n-- != 0) {
            amplify_mp_clear(cur_arg);
            cur_arg = va_arg(clean_args, amplify_mp_int *);
         }
         va_end(clean_args);
         err = AMPLIFY_MP_MEM;
         break;
      }
      n++;
      cur_arg = va_arg(args, amplify_mp_int *);
   }
   va_end(args);
   return err;                /* Assumed ok, if error flagged above. */
}

#endif
