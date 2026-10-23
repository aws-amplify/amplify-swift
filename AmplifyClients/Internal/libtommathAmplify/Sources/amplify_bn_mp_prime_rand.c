#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_PRIME_RAND_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* makes a truly random prime of a given size (bits),
 *
 * Flags are as follows:
 *
 *   AMPLIFY_MP_PRIME_BBS      - make prime congruent to 3 mod 4
 *   AMPLIFY_MP_PRIME_SAFE     - make sure (p-1)/2 is prime as well (implies AMPLIFY_MP_PRIME_BBS)
 *   AMPLIFY_MP_PRIME_2MSB_ON  - make the 2nd highest bit one
 *
 * You have to supply a callback which fills in a buffer with random bytes.  "dat" is a parameter you can
 * have passed to the callback (e.g. a state or something).  This function doesn't use "dat" itself
 * so it can be NULL
 *
 */

/* This is possibly the mother of all prime generation functions, muahahahahaha! */
amplify_mp_err amplify_s_mp_prime_random_ex(amplify_mp_int *a, int t, int size, int flags, private_amplify_mp_prime_callback cb, void *dat)
{
   unsigned char *tmp, maskAND, maskOR_msb, maskOR_lsb;
   int bsize, maskOR_msb_offset;
   amplify_mp_bool res;
   amplify_mp_err err;

   /* sanity check the input */
   if ((size <= 1) || (t <= 0)) {
      return AMPLIFY_MP_VAL;
   }

   /* AMPLIFY_MP_PRIME_SAFE implies AMPLIFY_MP_PRIME_BBS */
   if ((flags & AMPLIFY_MP_PRIME_SAFE) != 0) {
      flags |= AMPLIFY_MP_PRIME_BBS;
   }

   /* calc the byte size */
   bsize = (size>>3) + ((size&7)?1:0);

   /* we need a buffer of bsize bytes */
   tmp = (unsigned char *) AMPLIFY_MP_MALLOC((size_t)bsize);
   if (tmp == NULL) {
      return AMPLIFY_MP_MEM;
   }

   /* calc the maskAND value for the MSbyte*/
   maskAND = ((size&7) == 0) ? 0xFFu : (unsigned char)(0xFFu >> (8 - (size & 7)));

   /* calc the maskOR_msb */
   maskOR_msb        = 0;
   maskOR_msb_offset = ((size & 7) == 1) ? 1 : 0;
   if ((flags & AMPLIFY_MP_PRIME_2MSB_ON) != 0) {
      maskOR_msb       |= (unsigned char)(0x80 >> ((9 - size) & 7));
   }

   /* get the maskOR_lsb */
   maskOR_lsb         = 1u;
   if ((flags & AMPLIFY_MP_PRIME_BBS) != 0) {
      maskOR_lsb     |= 3u;
   }

   do {
      /* read the bytes */
      if (cb(tmp, bsize, dat) != bsize) {
         err = AMPLIFY_MP_VAL;
         goto error;
      }

      /* work over the MSbyte */
      tmp[0]    &= maskAND;
      tmp[0]    |= (unsigned char)(1 << ((size - 1) & 7));

      /* mix in the maskORs */
      tmp[maskOR_msb_offset]   |= maskOR_msb;
      tmp[bsize-1]             |= maskOR_lsb;

      /* read it in */
      /* TODO: casting only for now until all lengths have been changed to the type "size_t"*/
      if ((err = amplify_mp_from_ubin(a, tmp, (size_t)bsize)) != AMPLIFY_MP_OKAY) {
         goto error;
      }

      /* is it prime? */
      if ((err = amplify_mp_prime_is_prime(a, t, &res)) != AMPLIFY_MP_OKAY) {
         goto error;
      }
      if (res == AMPLIFY_MP_NO) {
         continue;
      }

      if ((flags & AMPLIFY_MP_PRIME_SAFE) != 0) {
         /* see if (a-1)/2 is prime */
         if ((err = amplify_mp_sub_d(a, 1uL, a)) != AMPLIFY_MP_OKAY) {
            goto error;
         }
         if ((err = amplify_mp_div_2(a, a)) != AMPLIFY_MP_OKAY) {
            goto error;
         }

         /* is it prime? */
         if ((err = amplify_mp_prime_is_prime(a, t, &res)) != AMPLIFY_MP_OKAY) {
            goto error;
         }
      }
   } while (res == AMPLIFY_MP_NO);

   if ((flags & AMPLIFY_MP_PRIME_SAFE) != 0) {
      /* restore a to the original value */
      if ((err = amplify_mp_mul_2(a, a)) != AMPLIFY_MP_OKAY) {
         goto error;
      }
      if ((err = amplify_amplify_mp_add_d(a, 1uL, a)) != AMPLIFY_MP_OKAY) {
         goto error;
      }
   }

   err = AMPLIFY_MP_OKAY;
error:
   AMPLIFY_MP_FREE_BUFFER(tmp, (size_t)bsize);
   return err;
}

static int amplify_s_mp_rand_cb(unsigned char *dst, int len, void *dat)
{
   (void)dat;
   if (len <= 0) {
      return len;
   }
   if (amplify_s_mp_rand_source(dst, (size_t)len) != AMPLIFY_MP_OKAY) {
      return 0;
   }
   return len;
}

amplify_mp_err amplify_mp_prime_rand(amplify_mp_int *a, int t, int size, int flags)
{
   return amplify_s_mp_prime_random_ex(a, t, size, flags, amplify_s_mp_rand_cb, NULL);
}

#endif
