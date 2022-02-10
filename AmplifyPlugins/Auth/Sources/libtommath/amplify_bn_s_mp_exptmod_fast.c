#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_EXPTMOD_FAST_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* computes Y == G**X mod P, HAC pp.616, Algorithm 14.85
 *
 * Uses a left-to-right k-ary sliding window to compute the modular exponentiation.
 * The value of k changes based on the size of the exponent.
 *
 * Uses Montgomery or Diminished Radix reduction [whichever appropriate]
 */

#ifdef AMPLIFY_MP_LOW_MEM
#   define TAB_SIZE 32
#   define MAX_WINSIZE 5
#else
#   define TAB_SIZE 256
#   define MAX_WINSIZE 0
#endif

amplify_mp_err amplify_s_mp_exptmod_fast(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P, amplify_mp_int *Y, int redmode)
{
   amplify_mp_int  M[TAB_SIZE], res;
   amplify_mp_digit buf, mp;
   int     bitbuf, bitcpy, bitcnt, mode, digidx, x, y, winsize;
   amplify_mp_err   err;

   /* use a pointer to the reduction algorithm.  This allows us to use
    * one of many reduction algorithms without modding the guts of
    * the code with if statements everywhere.
    */
   amplify_mp_err(*redux)(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit rho);

   /* find window size */
   x = amplify_mp_count_bits(X);
   if (x <= 7) {
      winsize = 2;
   } else if (x <= 36) {
      winsize = 3;
   } else if (x <= 140) {
      winsize = 4;
   } else if (x <= 450) {
      winsize = 5;
   } else if (x <= 1303) {
      winsize = 6;
   } else if (x <= 3529) {
      winsize = 7;
   } else {
      winsize = 8;
   }

   winsize = MAX_WINSIZE ? AMPLIFY_MP_MIN(MAX_WINSIZE, winsize) : winsize;

   /* init M array */
   /* init first cell */
   if ((err = amplify_mp_init_size(&M[1], P->alloc)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* now init the second half of the array */
   for (x = 1<<(winsize-1); x < (1 << winsize); x++) {
      if ((err = amplify_mp_init_size(&M[x], P->alloc)) != AMPLIFY_MP_OKAY) {
         for (y = 1<<(winsize-1); y < x; y++) {
            amplify_mp_clear(&M[y]);
         }
         amplify_mp_clear(&M[1]);
         return err;
      }
   }

   /* determine and setup reduction code */
   if (redmode == 0) {
      if (AMPLIFY_MP_HAS(MP_MONTGOMERY_SETUP)) {
         /* now setup montgomery  */
         if ((err = amplify_mp_montgomery_setup(P, &mp)) != AMPLIFY_MP_OKAY)      goto LBL_M;
      } else {
         err = AMPLIFY_MP_VAL;
         goto LBL_M;
      }

      /* automatically pick the comba one if available (saves quite a few calls/ifs) */
      if (AMPLIFY_MP_HAS(S_MP_MONTGOMERY_REDUCE_FAST) &&
          (((P->used * 2) + 1) < AMPLIFY_MP_WARRAY) &&
          (P->used < AMPLIFY_MP_MAXFAST)) {
         redux = amplify_s_mp_montgomery_reduce_fast;
      } else if (AMPLIFY_MP_HAS(MP_MONTGOMERY_REDUCE)) {
         /* use slower baseline Montgomery method */
         redux = amplify_mp_montgomery_reduce;
      } else {
         err = AMPLIFY_MP_VAL;
         goto LBL_M;
      }
   } else if (redmode == 1) {
      if (AMPLIFY_MP_HAS(MP_DR_SETUP) && AMPLIFY_MP_HAS(MP_DR_REDUCE)) {
         /* setup DR reduction for moduli of the form B**k - b */
         amplify_mp_dr_setup(P, &mp);
         redux = amplify_mp_dr_reduce;
      } else {
         err = AMPLIFY_MP_VAL;
         goto LBL_M;
      }
   } else if (AMPLIFY_MP_HAS(MP_REDUCE_2K_SETUP) && AMPLIFY_MP_HAS(MP_REDUCE_2K)) {
      /* setup DR reduction for moduli of the form 2**k - b */
      if ((err = amplify_mp_reduce_2k_setup(P, &mp)) != AMPLIFY_MP_OKAY)          goto LBL_M;
      redux = amplify_mp_reduce_2k;
   } else {
      err = AMPLIFY_MP_VAL;
      goto LBL_M;
   }

   /* setup result */
   if ((err = amplify_mp_init_size(&res, P->alloc)) != AMPLIFY_MP_OKAY)           goto LBL_M;

   /* create M table
    *

    *
    * The first half of the table is not computed though accept for M[0] and M[1]
    */

   if (redmode == 0) {
      if (AMPLIFY_MP_HAS(MP_MONTGOMERY_CALC_NORMALIZATION)) {
         /* now we need R mod m */
         if ((err = amplify_mp_montgomery_calc_normalization(&res, P)) != AMPLIFY_MP_OKAY) goto LBL_RES;

         /* now set M[1] to G * R mod m */
         if ((err = amplify_mp_mulmod(G, &res, P, &M[1])) != AMPLIFY_MP_OKAY)     goto LBL_RES;
      } else {
         err = AMPLIFY_MP_VAL;
         goto LBL_RES;
      }
   } else {
      amplify_mp_set(&res, 1uL);
      if ((err = amplify_mp_mod(G, P, &M[1])) != AMPLIFY_MP_OKAY)                 goto LBL_RES;
   }

   /* compute the value at M[1<<(winsize-1)] by squaring M[1] (winsize-1) times */
   if ((err = amplify_mp_copy(&M[1], &M[(size_t)1 << (winsize - 1)])) != AMPLIFY_MP_OKAY) goto LBL_RES;

   for (x = 0; x < (winsize - 1); x++) {
      if ((err = amplify_mp_sqr(&M[(size_t)1 << (winsize - 1)], &M[(size_t)1 << (winsize - 1)])) != AMPLIFY_MP_OKAY) goto LBL_RES;
      if ((err = redux(&M[(size_t)1 << (winsize - 1)], P, mp)) != AMPLIFY_MP_OKAY) goto LBL_RES;
   }

   /* create upper table */
   for (x = (1 << (winsize - 1)) + 1; x < (1 << winsize); x++) {
      if ((err = amplify_mp_mul(&M[x - 1], &M[1], &M[x])) != AMPLIFY_MP_OKAY)     goto LBL_RES;
      if ((err = redux(&M[x], P, mp)) != AMPLIFY_MP_OKAY)                 goto LBL_RES;
   }

   /* set initial mode and bit cnt */
   mode   = 0;
   bitcnt = 1;
   buf    = 0;
   digidx = X->used - 1;
   bitcpy = 0;
   bitbuf = 0;

   for (;;) {
      /* grab next digit as required */
      if (--bitcnt == 0) {
         /* if digidx == -1 we are out of digits so break */
         if (digidx == -1) {
            break;
         }
         /* read next digit and reset bitcnt */
         buf    = X->dp[digidx--];
         bitcnt = (int)AMPLIFY_MP_DIGIT_BIT;
      }

      /* grab the next msb from the exponent */
      y     = (amplify_mp_digit)(buf >> (AMPLIFY_MP_DIGIT_BIT - 1)) & 1uL;
      buf <<= (amplify_mp_digit)1;

      /* if the bit is zero and mode == 0 then we ignore it
       * These represent the leading zero bits before the first 1 bit
       * in the exponent.  Technically this opt is not required but it
       * does lower the # of trivial squaring/reductions used
       */
      if ((mode == 0) && (y == 0)) {
         continue;
      }

      /* if the bit is zero and mode == 1 then we square */
      if ((mode == 1) && (y == 0)) {
         if ((err = amplify_mp_sqr(&res, &res)) != AMPLIFY_MP_OKAY)               goto LBL_RES;
         if ((err = redux(&res, P, mp)) != AMPLIFY_MP_OKAY)               goto LBL_RES;
         continue;
      }

      /* else we add it to the window */
      bitbuf |= (y << (winsize - ++bitcpy));
      mode    = 2;

      if (bitcpy == winsize) {
         /* ok window is filled so square as required and multiply  */
         /* square first */
         for (x = 0; x < winsize; x++) {
            if ((err = amplify_mp_sqr(&res, &res)) != AMPLIFY_MP_OKAY)            goto LBL_RES;
            if ((err = redux(&res, P, mp)) != AMPLIFY_MP_OKAY)            goto LBL_RES;
         }

         /* then multiply */
         if ((err = amplify_mp_mul(&res, &M[bitbuf], &res)) != AMPLIFY_MP_OKAY)   goto LBL_RES;
         if ((err = redux(&res, P, mp)) != AMPLIFY_MP_OKAY)               goto LBL_RES;

         /* empty window and reset */
         bitcpy = 0;
         bitbuf = 0;
         mode   = 1;
      }
   }

   /* if bits remain then square/multiply */
   if ((mode == 2) && (bitcpy > 0)) {
      /* square then multiply if the bit is set */
      for (x = 0; x < bitcpy; x++) {
         if ((err = amplify_mp_sqr(&res, &res)) != AMPLIFY_MP_OKAY)               goto LBL_RES;
         if ((err = redux(&res, P, mp)) != AMPLIFY_MP_OKAY)               goto LBL_RES;

         /* get next bit of the window */
         bitbuf <<= 1;
         if ((bitbuf & (1 << winsize)) != 0) {
            /* then multiply */
            if ((err = amplify_mp_mul(&res, &M[1], &res)) != AMPLIFY_MP_OKAY)     goto LBL_RES;
            if ((err = redux(&res, P, mp)) != AMPLIFY_MP_OKAY)            goto LBL_RES;
         }
      }
   }

   if (redmode == 0) {
      /* fixup result if Montgomery reduction is used
       * recall that any value in a Montgomery system is
       * actually multiplied by R mod n.  So we have
       * to reduce one more time to cancel out the factor
       * of R.
       */
      if ((err = redux(&res, P, mp)) != AMPLIFY_MP_OKAY)                  goto LBL_RES;
   }

   /* swap res with Y */
   amplify_mp_exch(&res, Y);
   err = AMPLIFY_MP_OKAY;
LBL_RES:
   amplify_mp_clear(&res);
LBL_M:
   amplify_mp_clear(&M[1]);
   for (x = 1<<(winsize-1); x < (1 << winsize); x++) {
      amplify_mp_clear(&M[x]);
   }
   return err;
}
#endif
