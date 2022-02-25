#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_DIV_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#ifdef AMPLIFY_BN_MP_DIV_SMALL

/* slower bit-bang division... also smaller */
amplify_mp_err amplify_mp_div(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, amplify_mp_int *d)
{
   amplify_mp_int ta, tb, tq, q;
   int     n, n2;
   amplify_mp_err err;

   /* is divisor zero ? */
   if (AMPLIFY_MP_IS_ZERO(b)) {
      return AMPLIFY_MP_VAL;
   }

   /* if a < b then q=0, r = a */
   if (amplify_mp_cmp_mag(a, b) == AMPLIFY_MP_LT) {
      if (d != NULL) {
         err = amplify_mp_copy(a, d);
      } else {
         err = AMPLIFY_MP_OKAY;
      }
      if (c != NULL) {
         amplify_mp_zero(c);
      }
      return err;
   }

   /* init our temps */
   if ((err = amplify_mp_init_multi(&ta, &tb, &tq, &q, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }


   amplify_mp_set(&tq, 1uL);
   n = amplify_mp_count_bits(a) - amplify_mp_count_bits(b);
   if ((err = amplify_mp_abs(a, &ta)) != AMPLIFY_MP_OKAY)                         goto LBL_ERR;
   if ((err = amplify_mp_abs(b, &tb)) != AMPLIFY_MP_OKAY)                         goto LBL_ERR;
   if ((err = amplify_mp_mul_2d(&tb, n, &tb)) != AMPLIFY_MP_OKAY)                 goto LBL_ERR;
   if ((err = amplify_mp_mul_2d(&tq, n, &tq)) != AMPLIFY_MP_OKAY)                 goto LBL_ERR;

   while (n-- >= 0) {
      if (amplify_mp_cmp(&tb, &ta) != AMPLIFY_MP_GT) {
         if ((err = amplify_mp_sub(&ta, &tb, &ta)) != AMPLIFY_MP_OKAY)            goto LBL_ERR;
         if ((err = amplify_mp_add(&q, &tq, &q)) != AMPLIFY_MP_OKAY)              goto LBL_ERR;
      }
      if ((err = amplify_mp_div_2d(&tb, 1, &tb, NULL)) != AMPLIFY_MP_OKAY)        goto LBL_ERR;
      if ((err = amplify_mp_div_2d(&tq, 1, &tq, NULL)) != AMPLIFY_MP_OKAY)        goto LBL_ERR;
   }

   /* now q == quotient and ta == remainder */
   n  = a->sign;
   n2 = (a->sign == b->sign) ? AMPLIFY_MP_ZPOS : AMPLIFY_MP_NEG;
   if (c != NULL) {
      amplify_mp_exch(c, &q);
      c->sign  = AMPLIFY_MP_IS_ZERO(c) ? AMPLIFY_MP_ZPOS : n2;
   }
   if (d != NULL) {
      amplify_mp_exch(d, &ta);
      d->sign = AMPLIFY_MP_IS_ZERO(d) ? AMPLIFY_MP_ZPOS : n;
   }
LBL_ERR:
   amplify_mp_clear_multi(&ta, &tb, &tq, &q, NULL);
   return err;
}

#else

/* integer signed division.
 * c*b + d == a [e.g. a/b, c=quotient, d=remainder]
 * HAC pp.598 Algorithm 14.20
 *
 * Note that the description in HAC is horribly
 * incomplete.  For example, it doesn't consider
 * the case where digits are removed from 'x' in
 * the inner loop.  It also doesn't consider the
 * case that y has fewer than three digits, etc..
 *
 * The overall algorithm is as described as
 * 14.20 from HAC but fixed to treat these cases.
*/
amplify_mp_err amplify_mp_div(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, amplify_mp_int *d)
{
   amplify_mp_int  q, x, y, t1, t2;
   int     n, t, i, norm;
   amplify_mp_sign neg;
   amplify_mp_err  err;

   /* is divisor zero ? */
   if (AMPLIFY_MP_IS_ZERO(b)) {
      return AMPLIFY_MP_VAL;
   }

   /* if a < b then q=0, r = a */
   if (amplify_mp_cmp_mag(a, b) == AMPLIFY_MP_LT) {
      if (d != NULL) {
         err = amplify_mp_copy(a, d);
      } else {
         err = AMPLIFY_MP_OKAY;
      }
      if (c != NULL) {
         amplify_mp_zero(c);
      }
      return err;
   }

   if ((err = amplify_mp_init_size(&q, a->used + 2)) != AMPLIFY_MP_OKAY) {
      return err;
   }
   q.used = a->used + 2;

   if ((err = amplify_mp_init(&t1)) != AMPLIFY_MP_OKAY)                           goto LBL_Q;

   if ((err = amplify_mp_init(&t2)) != AMPLIFY_MP_OKAY)                           goto LBL_T1;

   if ((err = amplify_mp_init_copy(&x, a)) != AMPLIFY_MP_OKAY)                    goto LBL_T2;

   if ((err = amplify_mp_init_copy(&y, b)) != AMPLIFY_MP_OKAY)                    goto LBL_X;

   /* fix the sign */
   neg = (a->sign == b->sign) ? AMPLIFY_MP_ZPOS : AMPLIFY_MP_NEG;
   x.sign = y.sign = AMPLIFY_MP_ZPOS;

   /* normalize both x and y, ensure that y >= b/2, [b == 2**AMPLIFY_MP_DIGIT_BIT] */
   norm = amplify_mp_count_bits(&y) % AMPLIFY_MP_DIGIT_BIT;
   if (norm < (AMPLIFY_MP_DIGIT_BIT - 1)) {
      norm = (AMPLIFY_MP_DIGIT_BIT - 1) - norm;
      if ((err = amplify_mp_mul_2d(&x, norm, &x)) != AMPLIFY_MP_OKAY)             goto LBL_Y;
      if ((err = amplify_mp_mul_2d(&y, norm, &y)) != AMPLIFY_MP_OKAY)             goto LBL_Y;
   } else {
      norm = 0;
   }

   /* note hac does 0 based, so if used==5 then its 0,1,2,3,4, e.g. use 4 */
   n = x.used - 1;
   t = y.used - 1;

   /* while (x >= y*b**n-t) do { q[n-t] += 1; x -= y*b**{n-t} } */
   /* y = y*b**{n-t} */
   if ((err = amplify_mp_lshd(&y, n - t)) != AMPLIFY_MP_OKAY)                     goto LBL_Y;

   while (amplify_mp_cmp(&x, &y) != AMPLIFY_MP_LT) {
      ++(q.dp[n - t]);
      if ((err = amplify_mp_sub(&x, &y, &x)) != AMPLIFY_MP_OKAY)                  goto LBL_Y;
   }

   /* reset y by shifting it back down */
   amplify_mp_rshd(&y, n - t);

   /* step 3. for i from n down to (t + 1) */
   for (i = n; i >= (t + 1); i--) {
      if (i > x.used) {
         continue;
      }

      /* step 3.1 if xi == yt then set q{i-t-1} to b-1,
       * otherwise set q{i-t-1} to (xi*b + x{i-1})/yt */
      if (x.dp[i] == y.dp[t]) {
         q.dp[(i - t) - 1] = ((amplify_mp_digit)1 << (amplify_mp_digit)AMPLIFY_MP_DIGIT_BIT) - (amplify_mp_digit)1;
      } else {
         amplify_mp_word tmp;
         tmp = (amplify_mp_word)x.dp[i] << (amplify_mp_word)AMPLIFY_MP_DIGIT_BIT;
         tmp |= (amplify_mp_word)x.dp[i - 1];
         tmp /= (amplify_mp_word)y.dp[t];
         if (tmp > (amplify_mp_word)AMPLIFY_MP_MASK) {
            tmp = AMPLIFY_MP_MASK;
         }
         q.dp[(i - t) - 1] = (amplify_mp_digit)(tmp & (amplify_mp_word)AMPLIFY_MP_MASK);
      }

      /* while (q{i-t-1} * (yt * b + y{t-1})) >
               xi * b**2 + xi-1 * b + xi-2

         do q{i-t-1} -= 1;
      */
      q.dp[(i - t) - 1] = (q.dp[(i - t) - 1] + 1uL) & (amplify_mp_digit)AMPLIFY_MP_MASK;
      do {
         q.dp[(i - t) - 1] = (q.dp[(i - t) - 1] - 1uL) & (amplify_mp_digit)AMPLIFY_MP_MASK;

         /* find left hand */
         amplify_mp_zero(&t1);
         t1.dp[0] = ((t - 1) < 0) ? 0u : y.dp[t - 1];
         t1.dp[1] = y.dp[t];
         t1.used = 2;
         if ((err = amplify_mp_mul_d(&t1, q.dp[(i - t) - 1], &t1)) != AMPLIFY_MP_OKAY) goto LBL_Y;

         /* find right hand */
         t2.dp[0] = ((i - 2) < 0) ? 0u : x.dp[i - 2];
         t2.dp[1] = x.dp[i - 1]; /* i >= 1 always holds */
         t2.dp[2] = x.dp[i];
         t2.used = 3;
      } while (amplify_mp_cmp_mag(&t1, &t2) == AMPLIFY_MP_GT);

      /* step 3.3 x = x - q{i-t-1} * y * b**{i-t-1} */
      if ((err = amplify_mp_mul_d(&y, q.dp[(i - t) - 1], &t1)) != AMPLIFY_MP_OKAY) goto LBL_Y;

      if ((err = amplify_mp_lshd(&t1, (i - t) - 1)) != AMPLIFY_MP_OKAY)           goto LBL_Y;

      if ((err = amplify_mp_sub(&x, &t1, &x)) != AMPLIFY_MP_OKAY)                 goto LBL_Y;

      /* if x < 0 then { x = x + y*b**{i-t-1}; q{i-t-1} -= 1; } */
      if (x.sign == AMPLIFY_MP_NEG) {
         if ((err = amplify_mp_copy(&y, &t1)) != AMPLIFY_MP_OKAY)                 goto LBL_Y;
         if ((err = amplify_mp_lshd(&t1, (i - t) - 1)) != AMPLIFY_MP_OKAY)        goto LBL_Y;
         if ((err = amplify_mp_add(&x, &t1, &x)) != AMPLIFY_MP_OKAY)              goto LBL_Y;

         q.dp[(i - t) - 1] = (q.dp[(i - t) - 1] - 1uL) & AMPLIFY_MP_MASK;
      }
   }

   /* now q is the quotient and x is the remainder
    * [which we have to normalize]
    */

   /* get sign before writing to c */
   x.sign = (x.used == 0) ? AMPLIFY_MP_ZPOS : a->sign;

   if (c != NULL) {
      amplify_mp_clamp(&q);
      amplify_mp_exch(&q, c);
      c->sign = neg;
   }

   if (d != NULL) {
      if ((err = amplify_mp_div_2d(&x, norm, &x, NULL)) != AMPLIFY_MP_OKAY)       goto LBL_Y;
      amplify_mp_exch(&x, d);
   }

   err = AMPLIFY_MP_OKAY;

LBL_Y:
   amplify_mp_clear(&y);
LBL_X:
   amplify_mp_clear(&x);
LBL_T2:
   amplify_mp_clear(&t2);
LBL_T1:
   amplify_mp_clear(&t1);
LBL_Q:
   amplify_mp_clear(&q);
   return err;
}

#endif

#endif
