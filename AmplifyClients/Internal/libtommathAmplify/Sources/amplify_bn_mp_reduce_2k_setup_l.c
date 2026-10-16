#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_REDUCE_2K_SETUP_L_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* determines the setup value */
amplify_mp_err amplify_mp_reduce_2k_setup_l(const amplify_mp_int *a, amplify_mp_int *d)
{
   amplify_mp_err err;
   amplify_mp_int tmp;

   if ((err = amplify_mp_init(&tmp)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_2expt(&tmp, amplify_mp_count_bits(a))) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

   if ((err = amplify_s_mp_sub(&tmp, a, d)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

LBL_ERR:
   amplify_mp_clear(&tmp);
   return err;
}
#endif
