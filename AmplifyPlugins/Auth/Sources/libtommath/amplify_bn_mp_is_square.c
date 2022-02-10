#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_IS_SQUARE_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Check if remainders are possible squares - fast exclude non-squares */
static const char rem_128[128] = {
   0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1,
   1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1
};

static const char rem_105[105] = {
   0, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1,
   0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1,
   0, 1, 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1,
   1, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1,
   0, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1,
   1, 1, 1, 1, 0, 1, 0, 1, 1, 0, 0, 1, 1, 1, 1,
   1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 1, 1
};

/* Store non-zero to ret if arg is square, and zero if not */
amplify_mp_err amplify_mp_is_square(const amplify_mp_int *arg, amplify_mp_bool *ret)
{
   amplify_mp_err        err;
   amplify_mp_digit      c;
   amplify_mp_int        t;
   unsigned long r;

   /* Default to Non-square :) */
   *ret = AMPLIFY_MP_NO;

   if (arg->sign == AMPLIFY_MP_NEG) {
      return AMPLIFY_MP_VAL;
   }

   if (AMPLIFY_MP_IS_ZERO(arg)) {
      return AMPLIFY_MP_OKAY;
   }

   /* First check mod 128 (suppose that AMPLIFY_MP_DIGIT_BIT is at least 7) */
   if (rem_128[127u & arg->dp[0]] == (char)1) {
      return AMPLIFY_MP_OKAY;
   }

   /* Next check mod 105 (3*5*7) */
   if ((err = amplify_mp_mod_d(arg, 105uL, &c)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   if (rem_105[c] == (char)1) {
      return AMPLIFY_MP_OKAY;
   }


   if ((err = amplify_amplify_mp_init_u32(&t, 11u*13u*17u*19u*23u*29u*31u)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   if ((err = amplify_mp_mod(arg, &t, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }
   r = amplify_mp_get_u32(&t);
   /* Check for other prime modules, note it's not an ERROR but we must
    * free "t" so the easiest way is to goto LBL_ERR.  We know that err
    * is already equal to AMPLIFY_MP_OKAY from the amplify_mp_mod call
    */
   if (((1uL<<(r%11uL)) & 0x5C4uL) != 0uL)         goto LBL_ERR;
   if (((1uL<<(r%13uL)) & 0x9E4uL) != 0uL)         goto LBL_ERR;
   if (((1uL<<(r%17uL)) & 0x5CE8uL) != 0uL)        goto LBL_ERR;
   if (((1uL<<(r%19uL)) & 0x4F50CuL) != 0uL)       goto LBL_ERR;
   if (((1uL<<(r%23uL)) & 0x7ACCA0uL) != 0uL)      goto LBL_ERR;
   if (((1uL<<(r%29uL)) & 0xC2EDD0CuL) != 0uL)     goto LBL_ERR;
   if (((1uL<<(r%31uL)) & 0x6DE2B848uL) != 0uL)    goto LBL_ERR;

   /* Final check - is sqr(sqrt(arg)) == arg ? */
   if ((err = amplify_mp_sqrt(arg, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }
   if ((err = amplify_mp_sqr(&t, &t)) != AMPLIFY_MP_OKAY) {
      goto LBL_ERR;
   }

   *ret = (amplify_mp_cmp_mag(&t, arg) == AMPLIFY_MP_EQ) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
LBL_ERR:
   amplify_mp_clear(&t);
   return err;
}
#endif
