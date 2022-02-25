#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_EXPTMOD_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* this is a shell function that calls either the normal or Montgomery
 * exptmod functions.  Originally the call to the montgomery code was
 * embedded in the normal function but that wasted alot of stack space
 * for nothing (since 99% of the time the Montgomery code would be called)
 */
amplify_mp_err amplify_mp_exptmod(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P, amplify_mp_int *Y)
{
   int dr;

   /* modulus P must be positive */
   if (P->sign == AMPLIFY_MP_NEG) {
      return AMPLIFY_MP_VAL;
   }

   /* if exponent X is negative we have to recurse */
   if (X->sign == AMPLIFY_MP_NEG) {
      amplify_mp_int tmpG, tmpX;
      amplify_mp_err err;

      if (!AMPLIFY_MP_HAS(MP_INVMOD)) {
         return AMPLIFY_MP_VAL;
      }

      if ((err = amplify_mp_init_multi(&tmpG, &tmpX, NULL)) != AMPLIFY_MP_OKAY) {
         return err;
      }

      /* first compute 1/G mod P */
      if ((err = amplify_mp_invmod(G, P, &tmpG)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }

      /* now get |X| */
      if ((err = amplify_mp_abs(X, &tmpX)) != AMPLIFY_MP_OKAY) {
         goto LBL_ERR;
      }

      /* and now compute (1/G)**|X| instead of G**X [X < 0] */
      err = amplify_mp_exptmod(&tmpG, &tmpX, P, Y);
LBL_ERR:
      amplify_mp_clear_multi(&tmpG, &tmpX, NULL);
      return err;
   }

   /* modified diminished radix reduction */
   if (AMPLIFY_MP_HAS(MP_REDUCE_IS_2K_L) && AMPLIFY_MP_HAS(MP_REDUCE_2K_L) && AMPLIFY_MP_HAS(S_MP_EXPTMOD) &&
       (amplify_mp_reduce_is_2k_l(P) == AMPLIFY_MP_YES)) {
      return amplify_s_mp_exptmod(G, X, P, Y, 1);
   }

   /* is it a DR modulus? default to no */
   dr = (AMPLIFY_MP_HAS(MP_DR_IS_MODULUS) && (amplify_mp_dr_is_modulus(P) == AMPLIFY_MP_YES)) ? 1 : 0;

   /* if not, is it a unrestricted DR modulus? */
   if (AMPLIFY_MP_HAS(MP_REDUCE_IS_2K) && (dr == 0)) {
      dr = (amplify_mp_reduce_is_2k(P) == AMPLIFY_MP_YES) ? 2 : 0;
   }

   /* if the modulus is odd or dr != 0 use the montgomery method */
   if (AMPLIFY_MP_HAS(S_MP_EXPTMOD_FAST) && (AMPLIFY_MP_IS_ODD(P) || (dr != 0))) {
      return amplify_s_mp_exptmod_fast(G, X, P, Y, dr);
   } else if (AMPLIFY_MP_HAS(S_MP_EXPTMOD)) {
      /* otherwise use the generic Barrett reduction technique */
      return amplify_s_mp_exptmod(G, X, P, Y, 0);
   } else {
      /* no exptmod for evens */
      return AMPLIFY_MP_VAL;
   }
}

#endif
