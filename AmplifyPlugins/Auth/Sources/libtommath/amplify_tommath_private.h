/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#ifndef AMPLIFY_TOMMATH_PRIV_H_
#define AMPLIFY_TOMMATH_PRIV_H_

#include "amplify_tommath.h"
#include "amplify_tommath_class.h"

/*
 * Private symbols
 * ---------------
 *
 * On Unix symbols can be marked as hidden if libtommath is compiled
 * as a shared object. By default, symbols are visible.
 * As of now, this feature is opt-in via the AMPLIFY_MP_PRIVATE_SYMBOLS define.
 *
 * On Win32 a .def file must be used to specify the exported symbols.
 */
#if defined (AMPLIFY_MP_PRIVATE_SYMBOLS) && defined(__GNUC__) && __GNUC__ >= 4
#   define AMPLIFY_MP_PRIVATE __attribute__ ((visibility ("hidden")))
#else
#   define AMPLIFY_MP_PRIVATE
#endif

/* Hardening libtommath
 * --------------------
 *
 * By default memory is zeroed before calling
 * AMPLIFY_MP_FREE to avoid leaking data. This is good
 * practice in cryptographical applications.
 *
 * Note however that memory allocators used
 * in cryptographical applications can often
 * be configured by itself to clear memory,
 * rendering the clearing in tommath unnecessary.
 * See for example https://github.com/GrapheneOS/hardened_malloc
 * and the option CONFIG_ZERO_ON_FREE.
 *
 * Furthermore there are applications which
 * value performance more and want this
 * feature to be disabled. For such applications
 * define AMPLIFY_MP_NO_ZERO_ON_FREE during compilation.
 */
#ifdef AMPLIFY_MP_NO_ZERO_ON_FREE
#  define AMPLIFY_MP_FREE_BUFFER(mem, size)   AMPLIFY_MP_FREE((mem), (size))
#  define AMPLIFY_MP_FREE_DIGITS(mem, digits) AMPLIFY_MP_FREE((mem), sizeof (amplify_mp_digit) * (size_t)(digits))
#else
#  define AMPLIFY_MP_FREE_BUFFER(mem, size)                     \
do {                                                    \
   size_t fs_ = (size);                                 \
   void* fm_ = (mem);                                   \
   if (fm_ != NULL) {                                   \
      AMPLIFY_MP_ZERO_BUFFER(fm_, fs_);                         \
      AMPLIFY_MP_FREE(fm_, fs_);                                \
   }                                                    \
} while (0)
#  define AMPLIFY_MP_FREE_DIGITS(mem, digits)                   \
do {                                                    \
   int fd_ = (digits);                                  \
   void* fm_ = (mem);                                   \
   if (fm_ != NULL) {                                   \
      size_t fs_ = sizeof (amplify_mp_digit) * (size_t)fd_;     \
      AMPLIFY_MP_ZERO_BUFFER(fm_, fs_);                         \
      AMPLIFY_MP_FREE(fm_, fs_);                                \
   }                                                    \
} while (0)
#endif

#ifdef AMPLIFY_MP_USE_MEMSET
#  include <string.h>
#  define AMPLIFY_MP_ZERO_BUFFER(mem, size)   memset((mem), 0, (size))
#  define AMPLIFY_MP_ZERO_DIGITS(mem, digits)                   \
do {                                                    \
   int zd_ = (digits);                                  \
   if (zd_ > 0) {                                       \
      memset((mem), 0, sizeof(amplify_mp_digit) * (size_t)zd_); \
   }                                                    \
} while (0)
#else
#  define AMPLIFY_MP_ZERO_BUFFER(mem, size)                     \
do {                                                    \
   size_t zs_ = (size);                                 \
   char* zm_ = (char*)(mem);                            \
   while (zs_-- > 0u) {                                 \
      *zm_++ = '\0';                                    \
   }                                                    \
} while (0)
#  define AMPLIFY_MP_ZERO_DIGITS(mem, digits)                   \
do {                                                    \
   int zd_ = (digits);                                  \
   amplify_mp_digit* zm_ = (mem);                               \
   while (zd_-- > 0) {                                  \
      *zm_++ = 0;                                       \
   }                                                    \
} while (0)
#endif

/* Tunable cutoffs
 * ---------------
 *
 *  - In the default settings, a cutoff X can be modified at runtime
 *    by adjusting the corresponding X_CUTOFF variable.
 *
 *  - Tunability of the library can be disabled at compile time
 *    by defining the AMPLIFY_MP_FIXED_CUTOFFS macro.
 *
 *  - There is an additional file tommath_cutoffs.h, which defines
 *    the default cutoffs. These can be adjusted manually or by the
 *    autotuner.
 *
 */

#ifdef AMPLIFY_MP_FIXED_CUTOFFS
#  include "tommath_cutoffs.h"
#  define AMPLIFY_MP_KARATSUBA_MUL_CUTOFF AMPLIFY_MP_DEFAULT_KARATSUBA_MUL_CUTOFF
#  define AMPLIFY_MP_KARATSUBA_SQR_CUTOFF AMPLIFY_MP_DEFAULT_KARATSUBA_SQR_CUTOFF
#  define AMPLIFY_MP_TOOM_MUL_CUTOFF      AMPLIFY_MP_DEFAULT_TOOM_MUL_CUTOFF
#  define AMPLIFY_MP_TOOM_SQR_CUTOFF      AMPLIFY_MP_DEFAULT_TOOM_SQR_CUTOFF
#else
#  define AMPLIFY_MP_KARATSUBA_MUL_CUTOFF AMPLIFY_KARATSUBA_MUL_CUTOFF
#  define AMPLIFY_MP_KARATSUBA_SQR_CUTOFF AMPLIFY_KARATSUBA_SQR_CUTOFF
#  define AMPLIFY_MP_TOOM_MUL_CUTOFF      AMPLIFY_TOOM_MUL_CUTOFF
#  define AMPLIFY_MP_TOOM_SQR_CUTOFF      AMPLIFY_TOOM_SQR_CUTOFF
#endif

/* define heap macros */
#ifndef AMPLIFY_MP_MALLOC
/* default to libc stuff */
#   include <stdlib.h>
#   define AMPLIFY_MP_MALLOC(size)                   malloc(size)
#   define AMPLIFY_MP_REALLOC(mem, oldsize, newsize) realloc((mem), (newsize))
#   define AMPLIFY_MP_CALLOC(nmemb, size)            calloc((nmemb), (size))
#   define AMPLIFY_MP_FREE(mem, size)                free(mem)
#else
/* prototypes for our heap functions */
extern void *AMPLIFY_MP_MALLOC(size_t size);
extern void *AMPLIFY_MP_REALLOC(void *mem, size_t oldsize, size_t newsize);
extern void *AMPLIFY_MP_CALLOC(size_t nmemb, size_t size);
extern void AMPLIFY_MP_FREE(void *mem, size_t size);
#endif

/* feature detection macro */
#ifdef _MSC_VER
/* Prevent false positive: not enough arguments for function-like macro invocation */
#pragma warning(disable: 4003)
#endif
#define AMPLIFY_MP_STRINGIZE(x)  AMPLIFY_MP__STRINGIZE(x)
#define AMPLIFY_MP__STRINGIZE(x) ""#x""
#define AMPLIFY_MP_HAS(x)        (sizeof(AMPLIFY_MP_STRINGIZE(AMPLIFY_BN_##x##_C)) == 1u)

/* TODO: Remove private_mp_word as soon as deprecated amplify_mp_word is removed from tommath. */
#undef amplify_mp_word
typedef private_mp_word amplify_mp_word;

#define AMPLIFY_MP_MIN(x, y) (((x) < (y)) ? (x) : (y))
#define AMPLIFY_MP_MAX(x, y) (((x) > (y)) ? (x) : (y))

/* Static assertion */
#define AMPLIFY_MP_STATIC_ASSERT(msg, cond) typedef char amplify_mp_static_assert_##msg[(cond) ? 1 : -1];

/* ---> Basic Manipulations <--- */
#define AMPLIFY_MP_IS_ZERO(a) ((a)->used == 0)
#define AMPLIFY_MP_IS_EVEN(a) (((a)->used == 0) || (((a)->dp[0] & 1u) == 0u))
#define AMPLIFY_MP_IS_ODD(a)  (((a)->used > 0) && (((a)->dp[0] & 1u) == 1u))

#define AMPLIFY_MP_SIZEOF_BITS(type)    ((size_t)CHAR_BIT * sizeof(type))
#define AMPLIFY_MP_MAXFAST              (int)(1uL << (AMPLIFY_MP_SIZEOF_BITS(amplify_mp_word) - (2u * (size_t)AMPLIFY_MP_DIGIT_BIT)))

/* TODO: Remove PRIVATE_AMPLIFY_MP_WARRAY as soon as deprecated AMPLIFY_MP_WARRAY is removed from tommath.h */
#undef AMPLIFY_MP_WARRAY
#define AMPLIFY_MP_WARRAY PRIVATE_AMPLIFY_MP_WARRAY

/* TODO: Remove PRIVATE_MP_PREC as soon as deprecated AMPLIFY_MP_PREC is removed from tommath.h */
#ifdef PRIVATE_MP_PREC
#   undef AMPLIFY_MP_PREC
#   define AMPLIFY_MP_PREC PRIVATE_MP_PREC
#endif

/* Minimum number of available digits in amplify_mp_int, AMPLIFY_MP_PREC >= AMPLIFY_MP_MIN_PREC */
#define AMPLIFY_MP_MIN_PREC ((((int)AMPLIFY_MP_SIZEOF_BITS(long long) + AMPLIFY_MP_DIGIT_BIT) - 1) / AMPLIFY_MP_DIGIT_BIT)

AMPLIFY_MP_STATIC_ASSERT(prec_geq_min_prec, AMPLIFY_MP_PREC >= AMPLIFY_MP_MIN_PREC)

/* random number source */
extern AMPLIFY_MP_PRIVATE amplify_mp_err(*amplify_s_mp_rand_source)(void *out, size_t size);

/* lowlevel functions, do not call! */
AMPLIFY_MP_PRIVATE amplify_mp_bool amplify_s_mp_get_bit(const amplify_mp_int *a, unsigned int b);
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_add(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_sub(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_mul_digs_fast(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_mul_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_mul_high_digs_fast(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_mul_high_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_sqr_fast(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_sqr(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err s_amplify_mp_balance_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_karatsuba_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_toom_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_karatsuba_sqr(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_toom_sqr(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_invmod_fast(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_invmod_slow(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_montgomery_reduce_fast(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit rho) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_exptmod_fast(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P, amplify_mp_int *Y, int redmode) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_exptmod(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P, amplify_mp_int *Y, int redmode) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_rand_platform(void *p, size_t n) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_prime_random_ex(amplify_mp_int *a, int t, int size, int flags, private_amplify_mp_prime_callback cb, void *dat);
AMPLIFY_MP_PRIVATE void amplify_s_mp_reverse(unsigned char *s, size_t len);
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_prime_is_divisible(const amplify_mp_int *a, amplify_mp_bool *result);

/* TODO: jenkins prng is not thread safe as of now */
AMPLIFY_MP_PRIVATE amplify_mp_err amplify_s_mp_rand_jenkins(void *p, size_t n) AMPLIFY_MP_WUR;
AMPLIFY_MP_PRIVATE void amplify_s_mp_rand_jenkins_init(uint64_t seed);

extern AMPLIFY_MP_PRIVATE const char *const amplify_mp_s_rmap;
extern AMPLIFY_MP_PRIVATE const uint8_t amplify_mp_s_rmap_reverse[];
extern AMPLIFY_MP_PRIVATE const size_t amplify_mp_s_rmap_reverse_sz;
extern AMPLIFY_MP_PRIVATE const amplify_mp_digit *amplify_s_mp_prime_tab;

/* deprecated functions */
AMPLIFY_MP_DEPRECATED(amplify_s_mp_invmod_fast) amplify_mp_err amplify_fast_mp_invmod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_montgomery_reduce_fast) amplify_mp_err amplify_fast_mp_montgomery_reduce(amplify_mp_int *x, const amplify_mp_int *n,
      amplify_mp_digit rho);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_mul_digs_fast) amplify_mp_err amplify_fast_s_mp_mul_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c,
      int digs);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_mul_high_digs_fast) amplify_mp_err amplify_fast_s_mp_mul_high_digs(const amplify_mp_int *a, const amplify_mp_int *b,
      amplify_mp_int *c,
      int digs);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_sqr_fast) amplify_mp_err amplify_fast_s_mp_sqr(const amplify_mp_int *a, amplify_mp_int *b);
AMPLIFY_MP_DEPRECATED(s_amplify_mp_balance_mul) amplify_mp_err amplify_mp_balance_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_exptmod_fast) amplify_mp_err amplify_mp_exptmod_fast(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P,
      amplify_mp_int *Y,
      int redmode);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_invmod_slow) amplify_mp_err amplify_mp_invmod_slow(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_karatsuba_mul) amplify_mp_err amplify_mp_karatsuba_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_karatsuba_sqr) amplify_mp_err amplify_mp_karatsuba_sqr(const amplify_mp_int *a, amplify_mp_int *b);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_toom_mul) amplify_mp_err amplify_mp_toom_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_toom_sqr) amplify_mp_err amplify_mp_toom_sqr(const amplify_mp_int *a, amplify_mp_int *b);
AMPLIFY_MP_DEPRECATED(amplify_s_mp_reverse) void amplify_bn_reverse(unsigned char *s, int len);

#define AMPLIFY_MP_GET_ENDIANNESS(x) \
   do{\
      int16_t n = 0x1;                                          \
      char *p = (char *)&n;                                     \
      x = (p[0] == '\x01') ? AMPLIFY_MP_LITTLE_ENDIAN : AMPLIFY_MP_BIG_ENDIAN;  \
   } while (0)

/* code-generating macros */
#define AMPLIFY_MP_SET_UNSIGNED(name, type)                                                    \
    void name(amplify_mp_int * a, type b)                                                      \
    {                                                                                  \
        int i = 0;                                                                     \
        while (b != 0u) {                                                              \
            a->dp[i++] = ((amplify_mp_digit)b & AMPLIFY_MP_MASK);                                      \
            if (AMPLIFY_MP_SIZEOF_BITS(type) <= AMPLIFY_MP_DIGIT_BIT) { break; }                       \
            b >>= ((AMPLIFY_MP_SIZEOF_BITS(type) <= AMPLIFY_MP_DIGIT_BIT) ? 0 : AMPLIFY_MP_DIGIT_BIT);         \
        }                                                                              \
        a->used = i;                                                                   \
        a->sign = AMPLIFY_MP_ZPOS;                                                             \
        AMPLIFY_MP_ZERO_DIGITS(a->dp + a->used, a->alloc - a->used);                           \
    }

#define AMPLIFY_MP_SET_SIGNED(name, uname, type, utype)          \
    void name(amplify_mp_int * a, type b)                        \
    {                                                    \
        uname(a, (b < 0) ? -(utype)b : (utype)b);        \
        if (b < 0) { a->sign = AMPLIFY_MP_NEG; }                 \
    }

#define AMPLIFY_MP_INIT_INT(name , set, type)                    \
    amplify_mp_err name(amplify_mp_int * a, type b)                      \
    {                                                    \
        amplify_mp_err err;                                      \
        if ((err = amplify_mp_init(a)) != AMPLIFY_MP_OKAY) {             \
            return err;                                  \
        }                                                \
        set(a, b);                                       \
        return AMPLIFY_MP_OKAY;                                  \
    }

#define AMPLIFY_MP_GET_MAG(name, type)                                                         \
    type name(const amplify_mp_int* a)                                                         \
    {                                                                                  \
        unsigned i = AMPLIFY_MP_MIN((unsigned)a->used, (unsigned)((AMPLIFY_MP_SIZEOF_BITS(type) + AMPLIFY_MP_DIGIT_BIT - 1) / AMPLIFY_MP_DIGIT_BIT)); \
        type res = 0u;                                                                 \
        while (i --> 0u) {                                                             \
            res <<= ((AMPLIFY_MP_SIZEOF_BITS(type) <= AMPLIFY_MP_DIGIT_BIT) ? 0 : AMPLIFY_MP_DIGIT_BIT);       \
            res |= (type)a->dp[i];                                                     \
            if (AMPLIFY_MP_SIZEOF_BITS(type) <= AMPLIFY_MP_DIGIT_BIT) { break; }                       \
        }                                                                              \
        return res;                                                                    \
    }

#define AMPLIFY_MP_GET_SIGNED(name, mag, type, utype)                 \
    type name(const amplify_mp_int* a)                                \
    {                                                         \
        utype res = mag(a);                                   \
        return (a->sign == AMPLIFY_MP_NEG) ? (type)-res : (type)res;  \
    }

#endif
