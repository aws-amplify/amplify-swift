#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_S_MP_RAND_PLATFORM_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* First the OS-specific special cases
 * - *BSD
 * - Windows
 */
#if defined(__FreeBSD__) || defined(__OpenBSD__) || defined(__NetBSD__) || defined(__DragonFly__)
#define AMPLIFY_BN_S_READ_ARC4RANDOM_C
static amplify_mp_err s_read_arc4random(void *p, size_t n)
{
   arc4random_buf(p, n);
   return AMPLIFY_MP_OKAY;
}
#endif

#if defined(_WIN32) || defined(_WIN32_WCE)
#define AMPLIFY_BN_S_READ_WINCSP_C

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0400
#endif
#ifdef _WIN32_WCE
#define UNDER_CE
#define ARM
#endif

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <wincrypt.h>

static amplify_mp_err s_read_wincsp(void *p, size_t n)
{
   static HCRYPTPROV hProv = 0;
   if (hProv == 0) {
      HCRYPTPROV h = 0;
      if (!CryptAcquireContext(&h, NULL, MS_DEF_PROV, PROV_RSA_FULL,
                               (CRYPT_VERIFYCONTEXT | CRYPT_MACHINE_KEYSET)) &&
          !CryptAcquireContext(&h, NULL, MS_DEF_PROV, PROV_RSA_FULL,
                               CRYPT_VERIFYCONTEXT | CRYPT_MACHINE_KEYSET | CRYPT_NEWKEYSET)) {
         return AMPLIFY_MP_ERR;
      }
      hProv = h;
   }
   return CryptGenRandom(hProv, (DWORD)n, (BYTE *)p) == TRUE ? AMPLIFY_MP_OKAY : AMPLIFY_MP_ERR;
}
#endif /* WIN32 */

#if !defined(AMPLIFY_BN_S_READ_WINCSP_C) && defined(__linux__) && defined(__GLIBC_PREREQ)
#if __GLIBC_PREREQ(2, 25)
#define AMPLIFY_BN_S_READ_GETRANDOM_C
#include <sys/random.h>
#include <errno.h>

static amplify_mp_err s_read_getrandom(void *p, size_t n)
{
   char *q = (char *)p;
   while (n > 0u) {
      ssize_t ret = getrandom(q, n, 0);
      if (ret < 0) {
         if (errno == EINTR) {
            continue;
         }
         return AMPLIFY_MP_ERR;
      }
      q += ret;
      n -= (size_t)ret;
   }
   return AMPLIFY_MP_OKAY;
}
#endif
#endif

/* We assume all platforms besides windows provide "/dev/urandom".
 * In case yours doesn't, define AMPLIFY_MP_NO_DEV_URANDOM at compile-time.
 */
#if !defined(AMPLIFY_BN_S_READ_WINCSP_C) && !defined(AMPLIFY_MP_NO_DEV_URANDOM)
#define AMPLIFY_BN_S_READ_URANDOM_C
#ifndef AMPLIFY_MP_DEV_URANDOM
#define AMPLIFY_MP_DEV_URANDOM "/dev/urandom"
#endif
#include <fcntl.h>
#include <errno.h>
#include <unistd.h>

static amplify_mp_err s_read_urandom(void *p, size_t n)
{
   int fd;
   char *q = (char *)p;

   do {
      fd = open(AMPLIFY_MP_DEV_URANDOM, O_RDONLY);
   } while ((fd == -1) && (errno == EINTR));
   if (fd == -1) return AMPLIFY_MP_ERR;

   while (n > 0u) {
      ssize_t ret = read(fd, p, n);
      if (ret < 0) {
         if (errno == EINTR) {
            continue;
         }
         close(fd);
         return AMPLIFY_MP_ERR;
      }
      q += ret;
      n -= (size_t)ret;
   }

   close(fd);
   return AMPLIFY_MP_OKAY;
}
#endif

#if defined(AMPLIFY_MP_PRNG_ENABLE_LTM_RNG)
#define AMPLIFY_BN_S_READ_LTM_RNG
unsigned long (*ltm_rng)(unsigned char *out, unsigned long outlen, void (*callback)(void));
void (*ltm_rng_callback)(void);

static amplify_mp_err s_read_ltm_rng(void *p, size_t n)
{
   unsigned long res;
   if (ltm_rng == NULL) return AMPLIFY_MP_ERR;
   res = ltm_rng(p, n, ltm_rng_callback);
   if (res != n) return AMPLIFY_MP_ERR;
   return AMPLIFY_MP_OKAY;
}
#endif

amplify_mp_err s_read_arc4random(void *p, size_t n);
amplify_mp_err s_read_wincsp(void *p, size_t n);
amplify_mp_err s_read_getrandom(void *p, size_t n);
amplify_mp_err s_read_urandom(void *p, size_t n);
amplify_mp_err s_read_ltm_rng(void *p, size_t n);

amplify_mp_err amplify_s_mp_rand_platform(void *p, size_t n)
{
   amplify_mp_err err = AMPLIFY_MP_ERR;
   if ((err != AMPLIFY_MP_OKAY) && AMPLIFY_MP_HAS(S_READ_ARC4RANDOM)) err = s_read_arc4random(p, n);
   if ((err != AMPLIFY_MP_OKAY) && AMPLIFY_MP_HAS(S_READ_WINCSP))     err = s_read_wincsp(p, n);
   if ((err != AMPLIFY_MP_OKAY) && AMPLIFY_MP_HAS(S_READ_GETRANDOM))  err = s_read_getrandom(p, n);
   if ((err != AMPLIFY_MP_OKAY) && AMPLIFY_MP_HAS(S_READ_URANDOM))    err = s_read_urandom(p, n);
   if ((err != AMPLIFY_MP_OKAY) && AMPLIFY_MP_HAS(S_READ_LTM_RNG))    err = s_read_ltm_rng(p, n);
   return err;
}

#endif
