#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_SQRT_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* this function is less generic than amplify_mp_n_root, simpler and faster */
amplify_mp_err amplify_mp_sqrt(const amplify_mp_int *arg, amplify_mp_int *ret)
{
   amplify_mp_err err;
   amplify_mp_int t1, t2;

   /* must be positive */
   if (arg->sign == AMPLIFY_MP_NEG) {
      return AMPLIFY_MP_VAL;
   }

   /* easy out */
   if (AMPLIFY_MP_IS_ZERO(arg)) {
      amplify_mp_zero(ret);
      return AMPLIFY_MP_OKAY;
   }

   if ((err = amplify_mp_init_copy(&t1, arg)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   if ((err = amplify_mp_init(&t2)) != AMPLIFY_MP_OKAY) {
      goto E2;
   }

   /* First approx. (not very bad for large arg) */
   amplify_mp_rshd(&t1, t1.used/2);

   /* t1 > 0  */
   if ((err = amplify_mp_div(arg, &t1, &t2, NULL)) != AMPLIFY_MP_OKAY) {
      goto E1;
   }
   if ((err = amplify_mp_add(&t1, &t2, &t1)) != AMPLIFY_MP_OKAY) {
      goto E1;
   }
   if ((err = amplify_mp_div_2(&t1, &t1)) != AMPLIFY_MP_OKAY) {
      goto E1;
   }
   /* And now t1 > sqrt(arg) */
   do {
      if ((err = amplify_mp_div(arg, &t1, &t2, NULL)) != AMPLIFY_MP_OKAY) {
         goto E1;
      }
      if ((err = amplify_mp_add(&t1, &t2, &t1)) != AMPLIFY_MP_OKAY) {
         goto E1;
      }
      if ((err = amplify_mp_div_2(&t1, &t1)) != AMPLIFY_MP_OKAY) {
         goto E1;
      }
      /* t1 >= sqrt(arg) >= t2 at this point */
   } while (amplify_mp_cmp_mag(&t1, &t2) == AMPLIFY_MP_GT);

   amplify_mp_exch(&t1, ret);

E1:
   amplify_mp_clear(&t2);
E2:
   amplify_mp_clear(&t1);
   return err;
}

#endif
