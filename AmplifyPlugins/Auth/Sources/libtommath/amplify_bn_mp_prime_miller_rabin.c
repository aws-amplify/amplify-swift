#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_PRIME_MILLER_RABIN_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Miller-Rabin test of "a" to the base of "b" as described in
 * HAC pp. 139 Algorithm 4.24
 *
 * Sets result to 0 if definitely composite or 1 if probably prime.
 * Randomly the chance of error is no more than 1/4 and often
 * very much lower.
 */
amplify_mp_err amplify_mp_prime_miller_rabin(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_bool *result)
{
   amplify_mp_int  n1, y, r;
   amplify_mp_err  err;
   int     s, j;

   /* default */
   *result = AMPLIFY_MP_NO;

   /* ensure b > 1 */
   if (amplify_mp_cmp_d(b, 1uL) != AMPLIFY_MP_GT) {
      return AMPLIFY_MP_VAL;
   }

   /* get n1 = a - 1 */
   if ((err = amplify_mp_init_copy(&n1, a)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   if ((err = amplify_mp_sub_d(&n1, 1uL, &n1)) != AMPLIFY_MP_OKAY) {
      goto LBL_N1;
   }

   /* set 2**s * r = n1 */
   if ((err = amplify_mp_init_copy(&r, &n1)) != AMPLIFY_MP_OKAY) {
      goto LBL_N1;
   }

   /* count the number of least significant bits
    * which are zero
    */
   s = amplify_mp_cnt_lsb(&r);

   /* now divide n - 1 by 2**s */
   if ((err = amplify_mp_div_2d(&r, s, &r, NULL)) != AMPLIFY_MP_OKAY) {
      goto LBL_R;
   }

   /* compute y = b**r mod a */
   if ((err = amplify_mp_init(&y)) != AMPLIFY_MP_OKAY) {
      goto LBL_R;
   }
   if ((err = amplify_mp_exptmod(b, &r, a, &y)) != AMPLIFY_MP_OKAY) {
      goto LBL_Y;
   }

   /* if y != 1 and y != n1 do */
   if ((amplify_mp_cmp_d(&y, 1uL) != AMPLIFY_MP_EQ) && (amplify_mp_cmp(&y, &n1) != AMPLIFY_MP_EQ)) {
      j = 1;
      /* while j <= s-1 and y != n1 */
      while ((j <= (s - 1)) && (amplify_mp_cmp(&y, &n1) != AMPLIFY_MP_EQ)) {
         if ((err = amplify_mp_sqrmod(&y, a, &y)) != AMPLIFY_MP_OKAY) {
            goto LBL_Y;
         }

         /* if y == 1 then composite */
         if (amplify_mp_cmp_d(&y, 1uL) == AMPLIFY_MP_EQ) {
            goto LBL_Y;
         }

         ++j;
      }

      /* if y != n1 then composite */
      if (amplify_mp_cmp(&y, &n1) != AMPLIFY_MP_EQ) {
         goto LBL_Y;
      }
   }

   /* probably prime now */
   *result = AMPLIFY_MP_YES;
LBL_Y:
   amplify_mp_clear(&y);
LBL_R:
   amplify_mp_clear(&r);
LBL_N1:
   amplify_mp_clear(&n1);
   return err;
}
#endif
