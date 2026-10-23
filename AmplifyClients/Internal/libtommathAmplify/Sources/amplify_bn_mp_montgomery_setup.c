#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_MONTGOMERY_SETUP_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* setups the montgomery reduction stuff */
amplify_mp_err amplify_mp_montgomery_setup(const amplify_mp_int *n, amplify_mp_digit *rho)
{
   amplify_mp_digit x, b;

   /* fast inversion mod 2**k
    *
    * Based on the fact that
    *
    * XA = 1 (mod 2**n)  =>  (X(2-XA)) A = 1 (mod 2**2n)
    *                    =>  2*X*A - X*X*A*A = 1
    *                    =>  2*(1) - (1)     = 1
    */
   b = n->dp[0];

   if ((b & 1u) == 0u) {
      return AMPLIFY_MP_VAL;
   }

   x = (((b + 2u) & 4u) << 1) + b; /* here x*a==1 mod 2**4 */
   x *= 2u - (b * x);              /* here x*a==1 mod 2**8 */
#if !defined(AMPLIFY_MP_8BIT)
   x *= 2u - (b * x);              /* here x*a==1 mod 2**16 */
#endif
#if defined(AMPLIFY_MP_64BIT) || !(defined(AMPLIFY_MP_8BIT) || defined(AMPLIFY_MP_16BIT))
   x *= 2u - (b * x);              /* here x*a==1 mod 2**32 */
#endif
#ifdef AMPLIFY_MP_64BIT
   x *= 2u - (b * x);              /* here x*a==1 mod 2**64 */
#endif

   /* rho = -1/m mod b */
   *rho = (amplify_mp_digit)(((amplify_mp_word)1 << (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT) - x) & AMPLIFY_MP_MASK;

   return AMPLIFY_MP_OKAY;
}
#endif
