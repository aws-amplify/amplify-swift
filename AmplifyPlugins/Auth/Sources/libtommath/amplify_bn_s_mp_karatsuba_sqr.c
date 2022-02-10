#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_KARATSUBA_SQR_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* Karatsuba squaring, computes b = a*a using three
 * half size squarings
 *
 * See comments of karatsuba_mul for details.  It
 * is essentially the same algorithm but merely
 * tuned to perform recursive squarings.
 */
amplify_mp_err amplify_s_mp_karatsuba_sqr(const amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_int  x0, x1, t1, t2, x0x0, x1x1;
   int     B;
   amplify_mp_err  err = AMPLIFY_MP_MEM;

   /* min # of digits */
   B = a->used;

   /* now divide in two */
   B = B >> 1;

   /* init copy all the temps */
   if (amplify_mp_init_size(&x0, B) != AMPLIFY_MP_OKAY)
      goto LBL_ERR;
   if (amplify_mp_init_size(&x1, a->used - B) != AMPLIFY_MP_OKAY)
      goto X0;

   /* init temps */
   if (amplify_mp_init_size(&t1, a->used * 2) != AMPLIFY_MP_OKAY)
      goto X1;
   if (amplify_mp_init_size(&t2, a->used * 2) != AMPLIFY_MP_OKAY)
      goto T1;
   if (amplify_mp_init_size(&x0x0, B * 2) != AMPLIFY_MP_OKAY)
      goto T2;
   if (amplify_mp_init_size(&x1x1, (a->used - B) * 2) != AMPLIFY_MP_OKAY)
      goto X0X0;

   {
      int x;
      amplify_mp_digit *dst, *src;

      src = a->dp;

      /* now shift the digits */
      dst = x0.dp;
      for (x = 0; x < B; x++) {
         *dst++ = *src++;
      }

      dst = x1.dp;
      for (x = B; x < a->used; x++) {
         *dst++ = *src++;
      }
   }

   x0.used = B;
   x1.used = a->used - B;

   amplify_mp_clamp(&x0);

   /* now calc the products x0*x0 and x1*x1 */
   if (amplify_mp_sqr(&x0, &x0x0) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* x0x0 = x0*x0 */
   if (amplify_mp_sqr(&x1, &x1x1) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* x1x1 = x1*x1 */

   /* now calc (x1+x0)**2 */
   if (amplify_s_mp_add(&x1, &x0, &t1) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t1 = x1 - x0 */
   if (amplify_mp_sqr(&t1, &t1) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t1 = (x1 - x0) * (x1 - x0) */

   /* add x0y0 */
   if (amplify_s_mp_add(&x0x0, &x1x1, &t2) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t2 = x0x0 + x1x1 */
   if (amplify_s_mp_sub(&t1, &t2, &t1) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t1 = (x1+x0)**2 - (x0x0 + x1x1) */

   /* shift by B */
   if (amplify_mp_lshd(&t1, B) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t1 = (x0x0 + x1x1 - (x1-x0)*(x1-x0))<<B */
   if (amplify_mp_lshd(&x1x1, B * 2) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* x1x1 = x1x1 << 2*B */

   if (amplify_mp_add(&x0x0, &t1, &t1) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t1 = x0x0 + t1 */
   if (amplify_mp_add(&t1, &x1x1, b) != AMPLIFY_MP_OKAY)
      goto X1X1;           /* t1 = x0x0 + t1 + x1x1 */

   err = AMPLIFY_MP_OKAY;

X1X1:
   amplify_mp_clear(&x1x1);
X0X0:
   amplify_mp_clear(&x0x0);
T2:
   amplify_mp_clear(&t2);
T1:
   amplify_mp_clear(&t1);
X1:
   amplify_mp_clear(&x1);
X0:
   amplify_mp_clear(&x0);
LBL_ERR:
   return err;
}
#endif
