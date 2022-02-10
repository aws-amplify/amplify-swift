#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SQRTMOD_PRIME_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Tonelli-Shanks algorithm
 * https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm
 * https://gmplib.org/list-archives/gmp-discuss/2013-April/005300.html
 *
 */

amplify_mp_err amplify_mp_sqrtmod_prime(const amplify_mp_int *n, const amplify_mp_int *prime, amplify_mp_int *ret)
{
   amplify_mp_err err;
   int legendre;
   amplify_mp_int t1, C, Q, S, Z, M, T, R, two;
   amplify_mp_digit i;

   /* first handle the simple cases */
   if (amplify_mp_cmp_d(n, 0uL) == AMPLIFY_MP_EQ) {
      amplify_mp_zero(ret);
      return AMPLIFY_MP_OKAY;
   }
   if (amplify_mp_cmp_d(prime, 2uL) == AMPLIFY_MP_EQ)                            return AMPLIFY_MP_VAL; /* prime must be odd */
   if ((err = amplify_mp_kronecker(n, prime, &legendre)) != AMPLIFY_MP_OKAY)        return err;
   if (legendre == -1)                                           return AMPLIFY_MP_VAL; /* quadratic non-residue mod prime */

   if ((err = amplify_mp_init_multi(&t1, &C, &Q, &S, &Z, &M, &T, &R, &two, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* SPECIAL CASE: if prime mod 4 == 3
    * compute directly: err = n^(prime+1)/4 mod prime
    * Handbook of Applied Cryptography algorithm 3.36
    */
   if ((err = amplify_mp_mod_d(prime, 4uL, &i)) != AMPLIFY_MP_OKAY)               goto cleanup;
   if (i == 3u) {
      if ((err = amplify_amplify_mp_add_d(prime, 1uL, &t1)) != AMPLIFY_MP_OKAY)           goto cleanup;
      if ((err = amplify_mp_div_2(&t1, &t1)) != AMPLIFY_MP_OKAY)                  goto cleanup;
      if ((err = amplify_mp_div_2(&t1, &t1)) != AMPLIFY_MP_OKAY)                  goto cleanup;
      if ((err = amplify_mp_exptmod(n, &t1, prime, ret)) != AMPLIFY_MP_OKAY)      goto cleanup;
      err = AMPLIFY_MP_OKAY;
      goto cleanup;
   }

   /* NOW: Tonelli-Shanks algorithm */

   /* factor out powers of 2 from prime-1, defining Q and S as: prime-1 = Q*2^S */
   if ((err = amplify_mp_copy(prime, &Q)) != AMPLIFY_MP_OKAY)                    goto cleanup;
   if ((err = amplify_mp_sub_d(&Q, 1uL, &Q)) != AMPLIFY_MP_OKAY)                 goto cleanup;
   /* Q = prime - 1 */
   amplify_mp_zero(&S);
   /* S = 0 */
   while (AMPLIFY_MP_IS_EVEN(&Q)) {
      if ((err = amplify_mp_div_2(&Q, &Q)) != AMPLIFY_MP_OKAY)                    goto cleanup;
      /* Q = Q / 2 */
      if ((err = amplify_amplify_mp_add_d(&S, 1uL, &S)) != AMPLIFY_MP_OKAY)               goto cleanup;
      /* S = S + 1 */
   }

   /* find a Z such that the Legendre symbol (Z|prime) == -1 */
   amplify_mp_set_u32(&Z, 2u);
   /* Z = 2 */
   for (;;) {
      if ((err = amplify_mp_kronecker(&Z, prime, &legendre)) != AMPLIFY_MP_OKAY)     goto cleanup;
      if (legendre == -1) break;
      if ((err = amplify_amplify_mp_add_d(&Z, 1uL, &Z)) != AMPLIFY_MP_OKAY)               goto cleanup;
      /* Z = Z + 1 */
   }

   if ((err = amplify_mp_exptmod(&Z, &Q, prime, &C)) != AMPLIFY_MP_OKAY)         goto cleanup;
   /* C = Z ^ Q mod prime */
   if ((err = amplify_amplify_mp_add_d(&Q, 1uL, &t1)) != AMPLIFY_MP_OKAY)                goto cleanup;
   if ((err = amplify_mp_div_2(&t1, &t1)) != AMPLIFY_MP_OKAY)                    goto cleanup;
   /* t1 = (Q + 1) / 2 */
   if ((err = amplify_mp_exptmod(n, &t1, prime, &R)) != AMPLIFY_MP_OKAY)         goto cleanup;
   /* R = n ^ ((Q + 1) / 2) mod prime */
   if ((err = amplify_mp_exptmod(n, &Q, prime, &T)) != AMPLIFY_MP_OKAY)          goto cleanup;
   /* T = n ^ Q mod prime */
   if ((err = amplify_mp_copy(&S, &M)) != AMPLIFY_MP_OKAY)                       goto cleanup;
   /* M = S */
   amplify_mp_set_u32(&two, 2u);

   for (;;) {
      if ((err = amplify_mp_copy(&T, &t1)) != AMPLIFY_MP_OKAY)                    goto cleanup;
      i = 0;
      for (;;) {
         if (amplify_mp_cmp_d(&t1, 1uL) == AMPLIFY_MP_EQ) break;
         if ((err = amplify_mp_exptmod(&t1, &two, prime, &t1)) != AMPLIFY_MP_OKAY) goto cleanup;
         i++;
      }
      if (i == 0u) {
         if ((err = amplify_mp_copy(&R, ret)) != AMPLIFY_MP_OKAY)                  goto cleanup;
         err = AMPLIFY_MP_OKAY;
         goto cleanup;
      }
      if ((err = amplify_mp_sub_d(&M, i, &t1)) != AMPLIFY_MP_OKAY)                goto cleanup;
      if ((err = amplify_mp_sub_d(&t1, 1uL, &t1)) != AMPLIFY_MP_OKAY)             goto cleanup;
      if ((err = amplify_mp_exptmod(&two, &t1, prime, &t1)) != AMPLIFY_MP_OKAY)   goto cleanup;
      /* t1 = 2 ^ (M - i - 1) */
      if ((err = amplify_mp_exptmod(&C, &t1, prime, &t1)) != AMPLIFY_MP_OKAY)     goto cleanup;
      /* t1 = C ^ (2 ^ (M - i - 1)) mod prime */
      if ((err = amplify_mp_sqrmod(&t1, prime, &C)) != AMPLIFY_MP_OKAY)           goto cleanup;
      /* C = (t1 * t1) mod prime */
      if ((err = amplify_mp_mulmod(&R, &t1, prime, &R)) != AMPLIFY_MP_OKAY)       goto cleanup;
      /* R = (R * t1) mod prime */
      if ((err = amplify_mp_mulmod(&T, &C, prime, &T)) != AMPLIFY_MP_OKAY)        goto cleanup;
      /* T = (T * C) mod prime */
      amplify_mp_set(&M, i);
      /* M = i */
   }

cleanup:
   amplify_mp_clear_multi(&t1, &C, &Q, &S, &Z, &M, &T, &R, &two, NULL);
   return err;
}

#endif
