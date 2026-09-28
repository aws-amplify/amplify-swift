#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_EXTEUCLID_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* Extended euclidean algorithm of (a, b) produces
   a*u1 + b*u2 = u3
 */
amplify_mp_err amplify_mp_exteuclid(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *U1, amplify_mp_int *U2, amplify_mp_int *U3)
{
   amplify_mp_int u1, u2, u3, v1, v2, v3, t1, t2, t3, q, tmp;
   amplify_mp_err err;

   if ((err = amplify_mp_init_multi(&u1, &u2, &u3, &v1, &v2, &v3, &t1, &t2, &t3, &q, &tmp, NULL)) != AMPLIFY_MP_OKAY) {
      return err;
   }

   /* initialize, (u1,u2,u3) = (1,0,a) */
   amplify_mp_set(&u1, 1uL);
   if ((err = amplify_mp_copy(a, &u3)) != AMPLIFY_MP_OKAY)                        goto LBL_ERR;

   /* initialize, (v1,v2,v3) = (0,1,b) */
   amplify_mp_set(&v2, 1uL);
   if ((err = amplify_mp_copy(b, &v3)) != AMPLIFY_MP_OKAY)                        goto LBL_ERR;

   /* loop while v3 != 0 */
   while (!AMPLIFY_MP_IS_ZERO(&v3)) {
      /* q = u3/v3 */
      if ((err = amplify_mp_div(&u3, &v3, &q, NULL)) != AMPLIFY_MP_OKAY)          goto LBL_ERR;

      /* (t1,t2,t3) = (u1,u2,u3) - (v1,v2,v3)q */
      if ((err = amplify_mp_mul(&v1, &q, &tmp)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      if ((err = amplify_mp_sub(&u1, &tmp, &t1)) != AMPLIFY_MP_OKAY)              goto LBL_ERR;
      if ((err = amplify_mp_mul(&v2, &q, &tmp)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      if ((err = amplify_mp_sub(&u2, &tmp, &t2)) != AMPLIFY_MP_OKAY)              goto LBL_ERR;
      if ((err = amplify_mp_mul(&v3, &q, &tmp)) != AMPLIFY_MP_OKAY)               goto LBL_ERR;
      if ((err = amplify_mp_sub(&u3, &tmp, &t3)) != AMPLIFY_MP_OKAY)              goto LBL_ERR;

      /* (u1,u2,u3) = (v1,v2,v3) */
      if ((err = amplify_mp_copy(&v1, &u1)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
      if ((err = amplify_mp_copy(&v2, &u2)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
      if ((err = amplify_mp_copy(&v3, &u3)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;

      /* (v1,v2,v3) = (t1,t2,t3) */
      if ((err = amplify_mp_copy(&t1, &v1)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
      if ((err = amplify_mp_copy(&t2, &v2)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
      if ((err = amplify_mp_copy(&t3, &v3)) != AMPLIFY_MP_OKAY)                   goto LBL_ERR;
   }

   /* make sure U3 >= 0 */
   if (u3.sign == AMPLIFY_MP_NEG) {
      if ((err = amplify_mp_neg(&u1, &u1)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
      if ((err = amplify_mp_neg(&u2, &u2)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
      if ((err = amplify_mp_neg(&u3, &u3)) != AMPLIFY_MP_OKAY)                    goto LBL_ERR;
   }

   /* copy result out */
   if (U1 != NULL) {
      amplify_mp_exch(U1, &u1);
   }
   if (U2 != NULL) {
      amplify_mp_exch(U2, &u2);
   }
   if (U3 != NULL) {
      amplify_mp_exch(U3, &u3);
   }

   err = AMPLIFY_MP_OKAY;
LBL_ERR:
   amplify_mp_clear_multi(&u1, &u2, &u3, &v1, &v2, &v3, &t1, &t2, &t3, &q, &tmp, NULL);
   return err;
}
#endif
