#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_EXCH_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */

/* swap the elements of two integers, for cases where you can't simply swap the
 * amplify_mp_int pointers around
 */
void amplify_mp_exch(amplify_mp_int *a, amplify_mp_int *b)
{
   amplify_mp_int  t;

   t  = *a;
   *a = *b;
   *b = t;
}
#endif
