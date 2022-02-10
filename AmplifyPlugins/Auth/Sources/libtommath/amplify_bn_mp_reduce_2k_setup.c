#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_2K_SETUP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* determines the setup value */
amplify_mp_err amplify_mp_reduce_2k_setup(const amplify_mp_int *a, amplify_mp_digit *d)
{
   amplify_mp_err err;
   amplify_mp_int tmp;
   int    p;

   if ((err = amplify_mp_init(&tmp)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   p = amplify_mp_count_bits(a);
   if ((err = amplify_mp_2expt(&tmp, p)) != AMPLIFY_MP_OKAY) {
      amplify_mp_clear(&tmp);
      return err;
   }

   if ((err = amplify_s_mp_sub(&tmp, a, &tmp)) != AMPLIFY_MP_OKAY) {
      amplify_mp_clear(&tmp);
      return err;
   }

   *d = tmp.dp[0];
   amplify_mp_clear(&tmp);
   return AMPLIFY_MP_OKAY;
}
#endif
