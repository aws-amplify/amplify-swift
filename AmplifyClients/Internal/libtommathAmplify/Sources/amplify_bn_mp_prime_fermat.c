#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_PRIME_FERMAT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* performs one Fermat test.
 *
 * If "a" were prime then b**a == b (mod a) since the order of
 * the multiplicative sub-group would be phi(a) = a-1.  That means
 * it would be the same as b**(a mod (a-1)) == b**1 == b (mod a).
 *
 * Sets result to 1 if the congruence holds, or zero otherwise.
 */
amplify_mp_err amplify_mp_prime_fermat(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_bool *result)
{
   amplify_mp_int  t;
   amplify_mp_err  err;

   /* default to composite  */
   *result = AMPLIFY_MP_NO;

   /* ensure b > 1 */
   if (amplify_mp_cmp_d(b, 1uL) != AMPLIFY_MP_GT) {
      return AMPLIFY_MP_VAL;
   }

   /* init t */
   if ((err = amplify_mp_init(&t)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* compute t = b**a mod a */
   if ((err = amplify_mp_exptmod(b, a, a, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_T;
   }

   /* is it equal to b? */
   if (amplify_mp_cmp(&t, b) == AMPLIFY_MP_EQ) {
      *result = AMPLIFY_MP_YES;
   }

   err = AMPLIFY_MP_OKAY;
LBL_T:
   amplify_mp_clear(&t);
   return err;
}
#endif
