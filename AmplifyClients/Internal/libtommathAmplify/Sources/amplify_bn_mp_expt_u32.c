#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_EXPT_U32_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* calculate c = a**b  using a square-multiply algorithm */
amplify_mp_err amplify_mp_expt_u32(const amplify_mp_int *a, uint32_t b, amplify_mp_int *c)
{
   amplify_mp_err err;

   amplify_mp_int  g;

   if ((err = amplify_mp_init_copy(&g, a)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* set initial result */
   amplify_mp_set(c, 1uL);

   while (b > 0u) {
      /* if the bit is set multiply */
      if ((b & 1u) != 0u) {
         if ((err = amplify_mp_mul(c, &g, c)) != AMPLIFY_MP_OKAY) {
            goto LBL_ERR;
         }
      }

      /* square */
      if (b > 1u) {
         if ((err = amplify_mp_sqr(&g, &g)) != AMPLIFY_MP_OKAY) {
            goto LBL_ERR;
         }
      }

      /* shift to next bit */
      b >>= 1;
   }

   err = AMPLIFY_MP_OKAY;

LBL_ERR:
   amplify_mp_clear(&g);
   return err;
}

#endif
