#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_PRIME_IS_DIVISIBLE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* determines if an integers is divisible by one
 * of the first PRIME_SIZE primes or not
 *
 * sets result to 0 if not, 1 if yes
 */
amplify_mp_err amplify_s_mp_prime_is_divisible(const amplify_mp_int *a, amplify_mp_bool *result)
{
   int      ix;
   amplify_mp_err   err;
   amplify_mp_digit res;

   /* default to not */
   *result = AMPLIFY_MP_NO;

   for (ix = 0; ix < PRIVATE_MP_PRIME_TAB_SIZE; ix++) {
      /* what is a mod LBL_prime_tab[ix] */
      if ((err = amplify_mp_mod_d(a, amplify_s_mp_prime_tab[ix], &res)) != AMPLIFY_MP_OKAY) {
         return err;
      }

      /* is the residue zero? */
      if (res == 0u) {
         *result = AMPLIFY_MP_YES;
         return AMPLIFY_MP_OKAY;
      }
   }

   return AMPLIFY_MP_OKAY;
}
#endif
