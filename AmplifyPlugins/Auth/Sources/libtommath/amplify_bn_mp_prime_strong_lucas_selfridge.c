#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_PRIME_STRONG_LUCAS_SELFRIDGE_C

/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/*
 *  See file amplify_bn_mp_prime_is_prime.c or the documentation in doc/bn.tex for the details
 */
#ifndef LTM_USE_ONLY_MR

/*
 *  8-bit is just too small. You can try the Frobenius test
 *  but that frobenius test can fail, too, for the same reason.
 */
#ifndef AMPLIFY_MP_8BIT

/*
 * multiply bigint a with int d and put the result in c
 * Like amplify_mp_mul_d() but with a signed long as the small input
 */
static amplify_mp_err amplify_s_mp_mul_si(const amplify_mp_int *a, int32_t d, amplify_mp_int *c)
{
   amplify_mp_int t;
   amplify_mp_err err;

   if ((err = amplify_mp_init(&t)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /*
    * amplify_mp_digit might be smaller than a long, which excludes
    * the use of amplify_mp_mul_d() here.
    */
   amplify_mp_set_i32(&t, d);
   err = amplify_mp_mul(a, &t, c);
   amplify_mp_clear(&t);
   return err;
}
/*
    Strong Lucas-Selfridge test.
    returns AMPLIFY_MP_YES if it is a strong L-S prime, AMPLIFY_MP_NO if it is composite

    Code ported from  Thomas Ray Nicely's implementation of the BPSW test
    at http://www.trnicely.net/misc/bpsw.html

    Freeware copyright (C) 2016 Thomas R. Nicely <http://www.trnicely.net>.
    Released into the public domain by the author, who disclaims any legal
    liability arising from its use

    The multi-line comments are made by Thomas R. Nicely and are copied verbatim.
    Additional comments marked "CZ" (without the quotes) are by the code-portist.

    (If that name sounds familiar, he is the guy who found the fdiv bug in the
     Pentium (P5x, I think) Intel processor)
*/
amplify_mp_err amplify_mp_prime_strong_lucas_selfridge(const amplify_mp_int *a, amplify_mp_bool *result)
{
   /* CZ TODO: choose better variable names! */
   amplify_mp_int Dz, gcd, Np1, Uz, Vz, U2mz, V2mz, Qmz, Q2mz, Qkdz, T1z, T2z, T3z, T4z, Q2kdz;
   /* CZ TODO: Some of them need the full 32 bit, hence the (temporary) exclusion of AMPLIFY_MP_8BIT */
   int32_t D, Ds, J, sign, P, Q, r, s, u, Nbits;
   amplify_mp_err err;
   amplify_mp_bool oddness;

   *result = AMPLIFY_MP_NO;
   /*
   Find the first element D in the sequence {5, -7, 9, -11, 13, ...}
   such that Jacobi(D,N) = -1 (Selfridge's algorithm). Theory
   indicates that, if N is not a perfect square, D will "nearly
   always" be "small." Just in case, an overflow trap for D is
   included.
   */

   if ((err = amplify_mp_init_multi(&Dz, &gcd, &Np1, &Uz, &Vz, &U2mz, &V2mz, &Qmz, &Q2mz, &Qkdz, &T1z, &T2z, &T3z, &T4z, &Q2kdz,
                            NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   D = 5;
   sign = 1;

   for (;;) {
      Ds   = sign * D;
      sign = -sign;
      amplify_mp_set_u32(&Dz, (uint32_t)D);
      if ((err = amplify_mp_gcd(a, &Dz, &gcd)) != AMPLIFY_MP_OKAY)                goto LBL_LS_ERR;

      /* if 1 < GCD < N then N is composite with factor "D", and
         Jacobi(D,N) is technically undefined (but often returned
         as zero). */
      if ((amplify_mp_cmp_d(&gcd, 1uL) == AMPLIFY_MP_GT) && (amplify_mp_cmp(&gcd, a) == AMPLIFY_MP_LT)) {
         goto LBL_LS_ERR;
      }
      if (Ds < 0) {
         Dz.sign = AMPLIFY_MP_NEG;
      }
      if ((err = amplify_mp_kronecker(&Dz, a, &J)) != AMPLIFY_MP_OKAY)            goto LBL_LS_ERR;

      if (J == -1) {
         break;
      }
      D += 2;

      if (D > (INT_MAX - 2)) {
         err = AMPLIFY_MP_VAL;
         goto LBL_LS_ERR;
      }
   }



   P = 1;              /* Selfridge's choice */
   Q = (1 - Ds) / 4;   /* Required so D = P*P - 4*Q */

   /* NOTE: The conditions (a) N does not divide Q, and
      (b) D is square-free or not a perfect square, are included by
      some authors; e.g., "Prime numbers and computer methods for
      factorization," Hans Riesel (2nd ed., 1994, Birkhauser, Boston),
      p. 130. For this particular application of Lucas sequences,
      these conditions were found to be immaterial. */

   /* Now calculate N - Jacobi(D,N) = N + 1 (even), and calculate the
      odd positive integer d and positive integer s for which
      N + 1 = 2^s*d (similar to the step for N - 1 in Miller's test).
      The strong Lucas-Selfridge test then returns N as a strong
      Lucas probable prime (slprp) if any of the following
      conditions is met: U_d=0, V_d=0, V_2d=0, V_4d=0, V_8d=0,
      V_16d=0, ..., etc., ending with V_{2^(s-1)*d}=V_{(N+1)/2}=0
      (all equalities mod N). Thus d is the highest index of U that
      must be computed (since V_2m is independent of U), compared
      to U_{N+1} for the standard Lucas-Selfridge test; and no
      index of V beyond (N+1)/2 is required, just as in the
      standard Lucas-Selfridge test. However, the quantity Q^d must
      be computed for use (if necessary) in the latter stages of
      the test. The result is that the strong Lucas-Selfridge test
      has a running time only slightly greater (order of 10 %) than
      that of the standard Lucas-Selfridge test, while producing
      only (roughly) 30 % as many pseudoprimes (and every strong
      Lucas pseudoprime is also a standard Lucas pseudoprime). Thus
      the evidence indicates that the strong Lucas-Selfridge test is
      more effective than the standard Lucas-Selfridge test, and a
      Baillie-PSW test based on the strong Lucas-Selfridge test
      should be more reliable. */

   if ((err = amplify_amplify_mp_add_d(a, 1uL, &Np1)) != AMPLIFY_MP_OKAY)                 goto LBL_LS_ERR;
   s = amplify_mp_cnt_lsb(&Np1);

   /* CZ
    * This should round towards zero because
    * Thomas R. Nicely used GMP's mpz_tdiv_q_2exp()
    * and amplify_mp_div_2d() is equivalent. Additionally:
    * dividing an even number by two does not produce
    * any leftovers.
    */
   if ((err = amplify_mp_div_2d(&Np1, s, &Dz, NULL)) != AMPLIFY_MP_OKAY)          goto LBL_LS_ERR;
   /* We must now compute U_d and V_d. Since d is odd, the accumulated
      values U and V are initialized to U_1 and V_1 (if the target
      index were even, U and V would be initialized instead to U_0=0
      and V_0=2). The values of U_2m and V_2m are also initialized to
      U_1 and V_1; the FOR loop calculates in succession U_2 and V_2,
      U_4 and V_4, U_8 and V_8, etc. If the corresponding bits
      (1, 2, 3, ...) of t are on (the zero bit having been accounted
      for in the initialization of U and V), these values are then
      combined with the previous totals for U and V, using the
      composition formulas for addition of indices. */

   amplify_mp_set(&Uz, 1uL);    /* U=U_1 */
   amplify_mp_set(&Vz, (amplify_mp_digit)P);    /* V=V_1 */
   amplify_mp_set(&U2mz, 1uL);  /* U_1 */
   amplify_mp_set(&V2mz, (amplify_mp_digit)P);  /* V_1 */

   amplify_mp_set_i32(&Qmz, Q);
   if ((err = amplify_mp_mul_2(&Qmz, &Q2mz)) != AMPLIFY_MP_OKAY)                  goto LBL_LS_ERR;
   /* Initializes calculation of Q^d */
   amplify_mp_set_i32(&Qkdz, Q);

   Nbits = amplify_mp_count_bits(&Dz);

   for (u = 1; u < Nbits; u++) { /* zero bit off, already accounted for */
      /* Formulas for doubling of indices (carried out mod N). Note that
       * the indices denoted as "2m" are actually powers of 2, specifically
       * 2^(ul-1) beginning each loop and 2^ul ending each loop.
       *
       * U_2m = U_m*V_m
       * V_2m = V_m*V_m - 2*Q^m
       */

      if ((err = amplify_mp_mul(&U2mz, &V2mz, &U2mz)) != AMPLIFY_MP_OKAY)         goto LBL_LS_ERR;
      if ((err = amplify_mp_mod(&U2mz, a, &U2mz)) != AMPLIFY_MP_OKAY)             goto LBL_LS_ERR;
      if ((err = amplify_mp_sqr(&V2mz, &V2mz)) != AMPLIFY_MP_OKAY)                goto LBL_LS_ERR;
      if ((err = amplify_mp_sub(&V2mz, &Q2mz, &V2mz)) != AMPLIFY_MP_OKAY)         goto LBL_LS_ERR;
      if ((err = amplify_mp_mod(&V2mz, a, &V2mz)) != AMPLIFY_MP_OKAY)             goto LBL_LS_ERR;

      /* Must calculate powers of Q for use in V_2m, also for Q^d later */
      if ((err = amplify_mp_sqr(&Qmz, &Qmz)) != AMPLIFY_MP_OKAY)                  goto LBL_LS_ERR;

      /* prevents overflow */ /* CZ  still necessary without a fixed prealloc'd mem.? */
      if ((err = amplify_mp_mod(&Qmz, a, &Qmz)) != AMPLIFY_MP_OKAY)               goto LBL_LS_ERR;
      if ((err = amplify_mp_mul_2(&Qmz, &Q2mz)) != AMPLIFY_MP_OKAY)               goto LBL_LS_ERR;

      if (amplify_s_mp_get_bit(&Dz, (unsigned int)u) == AMPLIFY_MP_YES) {
         /* Formulas for addition of indices (carried out mod N);
          *
          * U_(m+n) = (U_m*V_n + U_n*V_m)/2
          * V_(m+n) = (V_m*V_n + D*U_m*U_n)/2
          *
          * Be careful with division by 2 (mod N)!
          */
         if ((err = amplify_mp_mul(&U2mz, &Vz, &T1z)) != AMPLIFY_MP_OKAY)         goto LBL_LS_ERR;
         if ((err = amplify_mp_mul(&Uz, &V2mz, &T2z)) != AMPLIFY_MP_OKAY)         goto LBL_LS_ERR;
         if ((err = amplify_mp_mul(&V2mz, &Vz, &T3z)) != AMPLIFY_MP_OKAY)         goto LBL_LS_ERR;
         if ((err = amplify_mp_mul(&U2mz, &Uz, &T4z)) != AMPLIFY_MP_OKAY)         goto LBL_LS_ERR;
         if ((err = amplify_s_mp_mul_si(&T4z, Ds, &T4z)) != AMPLIFY_MP_OKAY)      goto LBL_LS_ERR;
         if ((err = amplify_mp_add(&T1z, &T2z, &Uz)) != AMPLIFY_MP_OKAY)          goto LBL_LS_ERR;
         if (AMPLIFY_MP_IS_ODD(&Uz)) {
            if ((err = amplify_mp_add(&Uz, a, &Uz)) != AMPLIFY_MP_OKAY)           goto LBL_LS_ERR;
         }
         /* CZ
          * This should round towards negative infinity because
          * Thomas R. Nicely used GMP's mpz_fdiv_q_2exp().
          * But amplify_mp_div_2() does not do so, it is truncating instead.
          */
         oddness = AMPLIFY_MP_IS_ODD(&Uz) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
         if ((err = amplify_mp_div_2(&Uz, &Uz)) != AMPLIFY_MP_OKAY)               goto LBL_LS_ERR;
         if ((Uz.sign == AMPLIFY_MP_NEG) && (oddness != AMPLIFY_MP_NO)) {
            if ((err = amplify_mp_sub_d(&Uz, 1uL, &Uz)) != AMPLIFY_MP_OKAY)       goto LBL_LS_ERR;
         }
         if ((err = amplify_mp_add(&T3z, &T4z, &Vz)) != AMPLIFY_MP_OKAY)          goto LBL_LS_ERR;
         if (AMPLIFY_MP_IS_ODD(&Vz)) {
            if ((err = amplify_mp_add(&Vz, a, &Vz)) != AMPLIFY_MP_OKAY)           goto LBL_LS_ERR;
         }
         oddness = AMPLIFY_MP_IS_ODD(&Vz) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
         if ((err = amplify_mp_div_2(&Vz, &Vz)) != AMPLIFY_MP_OKAY)               goto LBL_LS_ERR;
         if ((Vz.sign == AMPLIFY_MP_NEG) && (oddness != AMPLIFY_MP_NO)) {
            if ((err = amplify_mp_sub_d(&Vz, 1uL, &Vz)) != AMPLIFY_MP_OKAY)       goto LBL_LS_ERR;
         }
         if ((err = amplify_mp_mod(&Uz, a, &Uz)) != AMPLIFY_MP_OKAY)              goto LBL_LS_ERR;
         if ((err = amplify_mp_mod(&Vz, a, &Vz)) != AMPLIFY_MP_OKAY)              goto LBL_LS_ERR;

         /* Calculating Q^d for later use */
         if ((err = amplify_mp_mul(&Qkdz, &Qmz, &Qkdz)) != AMPLIFY_MP_OKAY)       goto LBL_LS_ERR;
         if ((err = amplify_mp_mod(&Qkdz, a, &Qkdz)) != AMPLIFY_MP_OKAY)          goto LBL_LS_ERR;
      }
   }

   /* If U_d or V_d is congruent to 0 mod N, then N is a prime or a
      strong Lucas pseudoprime. */
   if (AMPLIFY_MP_IS_ZERO(&Uz) || AMPLIFY_MP_IS_ZERO(&Vz)) {
      *result = AMPLIFY_MP_YES;
      goto LBL_LS_ERR;
   }

   /* NOTE: Ribenboim ("The new book of prime number records," 3rd ed.,
      1995/6) omits the condition V0 on p.142, but includes it on
      p. 130. The condition is NECESSARY; otherwise the test will
      return false negatives---e.g., the primes 29 and 2000029 will be
      returned as composite. */

   /* Otherwise, we must compute V_2d, V_4d, V_8d, ..., V_{2^(s-1)*d}
      by repeated use of the formula V_2m = V_m*V_m - 2*Q^m. If any of
      these are congruent to 0 mod N, then N is a prime or a strong
      Lucas pseudoprime. */

   /* Initialize 2*Q^(d*2^r) for V_2m */
   if ((err = amplify_mp_mul_2(&Qkdz, &Q2kdz)) != AMPLIFY_MP_OKAY)                goto LBL_LS_ERR;

   for (r = 1; r < s; r++) {
      if ((err = amplify_mp_sqr(&Vz, &Vz)) != AMPLIFY_MP_OKAY)                    goto LBL_LS_ERR;
      if ((err = amplify_mp_sub(&Vz, &Q2kdz, &Vz)) != AMPLIFY_MP_OKAY)            goto LBL_LS_ERR;
      if ((err = amplify_mp_mod(&Vz, a, &Vz)) != AMPLIFY_MP_OKAY)                 goto LBL_LS_ERR;
      if (AMPLIFY_MP_IS_ZERO(&Vz)) {
         *result = AMPLIFY_MP_YES;
         goto LBL_LS_ERR;
      }
      /* Calculate Q^{d*2^r} for next r (final iteration irrelevant). */
      if (r < (s - 1)) {
         if ((err = amplify_mp_sqr(&Qkdz, &Qkdz)) != AMPLIFY_MP_OKAY)             goto LBL_LS_ERR;
         if ((err = amplify_mp_mod(&Qkdz, a, &Qkdz)) != AMPLIFY_MP_OKAY)          goto LBL_LS_ERR;
         if ((err = amplify_mp_mul_2(&Qkdz, &Q2kdz)) != AMPLIFY_MP_OKAY)          goto LBL_LS_ERR;
      }
   }
LBL_LS_ERR:
   amplify_mp_clear_multi(&Q2kdz, &T4z, &T3z, &T2z, &T1z, &Qkdz, &Q2mz, &Qmz, &V2mz, &U2mz, &Vz, &Uz, &Np1, &gcd, &Dz, NULL);
   return err;
}
#endif
#endif
#endif
