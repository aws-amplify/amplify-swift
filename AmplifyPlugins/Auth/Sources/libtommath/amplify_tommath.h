/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#ifndef AMPLIFY_BN_H_
#define AMPLIFY_BN_H_

#include <stdint.h>
#include <stddef.h>
#include <limits.h>

#ifdef LTM_NO_FILE
#  warning LTM_NO_FILE has been deprecated, use AMPLIFY_MP_NO_FILE.
#  define AMPLIFY_MP_NO_FILE
#endif

#ifndef AMPLIFY_MP_NO_FILE
#  include <stdio.h>
#endif

#ifdef AMPLIFY_MP_8BIT
#  ifdef _MSC_VER
#    pragma message("8-bit (AMPLIFY_MP_8BIT) support is deprecated and will be dropped completely in the next version.")
#  else
#    warning "8-bit (AMPLIFY_MP_8BIT) support is deprecated and will be dropped completely in the next version."
#  endif
#endif

#ifdef __cplusplus
extern "C" {
#endif

/* MS Visual C++ doesn't have a 128bit type for words, so fall back to 32bit MPI's (where words are 64bit) */
#if (defined(_MSC_VER) || defined(__LLP64__) || defined(__e2k__) || defined(__LCC__)) && !defined(AMPLIFY_MP_64BIT)
#   define AMPLIFY_MP_32BIT
#endif

/* detect 64-bit mode if possible */
#if defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || \
    defined(__powerpc64__) || defined(__ppc64__) || defined(__PPC64__) || \
    defined(__s390x__) || defined(__arch64__) || defined(__aarch64__) || \
    defined(__sparcv9) || defined(__sparc_v9__) || defined(__sparc64__) || \
    defined(__ia64) || defined(__ia64__) || defined(__itanium__) || defined(_M_IA64) || \
    defined(__LP64__) || defined(_LP64) || defined(__64BIT__)
#   if !(defined(AMPLIFY_MP_64BIT) || defined(AMPLIFY_MP_32BIT) || defined(AMPLIFY_MP_16BIT) || defined(AMPLIFY_MP_8BIT))
#      if defined(__GNUC__) && !defined(__hppa)
/* we support 128bit integers only via: __attribute__((mode(TI))) */
#         define AMPLIFY_MP_64BIT
#      else
/* otherwise we fall back to AMPLIFY_MP_32BIT even on 64bit platforms */
#         define AMPLIFY_MP_32BIT
#      endif
#   endif
#endif

#ifdef AMPLIFY_MP_DIGIT_BIT
#   error Defining AMPLIFY_MP_DIGIT_BIT is disallowed, use AMPLIFY_MP_8/16/31/32/64BIT
#endif

/* some default configurations.
 *
 * A "amplify_mp_digit" must be able to hold AMPLIFY_MP_DIGIT_BIT + 1 bits
 * A "amplify_mp_word" must be able to hold 2*AMPLIFY_MP_DIGIT_BIT + 1 bits
 *
 * At the very least a amplify_mp_digit must be able to hold 7 bits
 * [any size beyond that is ok provided it doesn't overflow the data type]
 */

#ifdef AMPLIFY_MP_8BIT
typedef uint8_t              amplify_mp_digit;
typedef uint16_t             private_mp_word;
#   define AMPLIFY_MP_DIGIT_BIT 7
#elif defined(AMPLIFY_MP_16BIT)
typedef uint16_t             amplify_mp_digit;
typedef uint32_t             private_mp_word;
#   define AMPLIFY_MP_DIGIT_BIT 15
#elif defined(AMPLIFY_MP_64BIT)
/* for GCC only on supported platforms */
typedef uint64_t amplify_mp_digit;
#if defined(__GNUC__)
typedef unsigned long        private_mp_word __attribute__((mode(TI)));
#endif
#   define AMPLIFY_MP_DIGIT_BIT 60
#else
typedef uint32_t             amplify_mp_digit;
typedef uint64_t             private_mp_word;
#   ifdef AMPLIFY_MP_31BIT
/*
 * This is an extension that uses 31-bit digits.
 * Please be aware that not all functions support this size, especially amplify_s_mp_mul_digs_fast
 * will be reduced to work on small numbers only:
 * Up to 8 limbs, 248 bits instead of up to 512 limbs, 15872 bits with AMPLIFY_MP_28BIT.
 */
#      define AMPLIFY_MP_DIGIT_BIT 31
#   else
/* default case is 28-bit digits, defines AMPLIFY_MP_28BIT as a handy macro to test */
#      define AMPLIFY_MP_DIGIT_BIT 28
#      define AMPLIFY_MP_28BIT
#   endif
#endif

/* amplify_mp_word is a private type */
#define amplify_mp_word AMPLIFY_MP_DEPRECATED_PRAGMA("amplify_mp_word has been made private") private_mp_word

#define AMPLIFY_MP_SIZEOF_MP_DIGIT (AMPLIFY_MP_DEPRECATED_PRAGMA("AMPLIFY_MP_SIZEOF_MP_DIGIT has been deprecated, use sizeof (amplify_mp_digit)") sizeof (amplify_mp_digit))

#define AMPLIFY_MP_MASK          ((((amplify_mp_digit)1)<<((amplify_mp_digit)AMPLIFY_MP_DIGIT_BIT))-((amplify_mp_digit)1))
#define AMPLIFY_MP_DIGIT_MAX     AMPLIFY_MP_MASK

/* Primality generation flags */
#define AMPLIFY_MP_PRIME_BBS      0x0001 /* BBS style prime */
#define AMPLIFY_MP_PRIME_SAFE     0x0002 /* Safe prime (p-1)/2 == prime */
#define AMPLIFY_MP_PRIME_2MSB_ON  0x0008 /* force 2nd MSB to 1 */

#define LTM_PRIME_BBS      (AMPLIFY_MP_DEPRECATED_PRAGMA("LTM_PRIME_BBS has been deprecated, use AMPLIFY_MP_PRIME_BBS") AMPLIFY_MP_PRIME_BBS)
#define LTM_PRIME_SAFE     (AMPLIFY_MP_DEPRECATED_PRAGMA("LTM_PRIME_SAFE has been deprecated, use AMPLIFY_MP_PRIME_SAFE") AMPLIFY_MP_PRIME_SAFE)
#define LTM_PRIME_2MSB_ON  (AMPLIFY_MP_DEPRECATED_PRAGMA("LTM_PRIME_2MSB_ON has been deprecated, use AMPLIFY_MP_PRIME_2MSB_ON") AMPLIFY_MP_PRIME_2MSB_ON)

#ifdef AMPLIFY_MP_USE_ENUMS
typedef enum {
   AMPLIFY_MP_ZPOS = 0,   /* positive */
   AMPLIFY_MP_NEG = 1     /* negative */
} amplify_mp_sign;
typedef enum {
   AMPLIFY_MP_LT = -1,    /* less than */
   AMPLIFY_MP_EQ = 0,     /* equal */
   AMPLIFY_MP_GT = 1      /* greater than */
} amplify_mp_ord;
typedef enum {
   AMPLIFY_MP_NO = 0,
   AMPLIFY_MP_YES = 1
} amplify_mp_bool;
typedef enum {
   AMPLIFY_MP_OKAY  = 0,   /* no error */
   AMPLIFY_MP_ERR   = -1,  /* unknown error */
   AMPLIFY_MP_MEM   = -2,  /* out of mem */
   AMPLIFY_MP_VAL   = -3,  /* invalid input */
   AMPLIFY_MP_ITER  = -4,  /* maximum iterations reached */
   AMPLIFY_MP_BUF   = -5   /* buffer overflow, supplied buffer too small */
} amplify_mp_err;
typedef enum {
   AMPLIFY_MP_LSB_FIRST = -1,
   AMPLIFY_MP_MSB_FIRST =  1
} amplify_mp_order;
typedef enum {
   AMPLIFY_MP_LITTLE_ENDIAN  = -1,
   AMPLIFY_MP_NATIVE_ENDIAN  =  0,
   AMPLIFY_MP_BIG_ENDIAN     =  1
} amplify_mp_endian;
#else
typedef int amplify_mp_sign;
#define AMPLIFY_MP_ZPOS       0   /* positive integer */
#define AMPLIFY_MP_NEG        1   /* negative */
typedef int amplify_mp_ord;
#define AMPLIFY_MP_LT        -1   /* less than */
#define AMPLIFY_MP_EQ         0   /* equal to */
#define AMPLIFY_MP_GT         1   /* greater than */
typedef int amplify_mp_bool;
#define AMPLIFY_MP_YES        1
#define AMPLIFY_MP_NO         0
typedef int amplify_mp_err;
#define AMPLIFY_MP_OKAY       0   /* no error */
#define AMPLIFY_MP_ERR        -1  /* unknown error */
#define AMPLIFY_MP_MEM        -2  /* out of mem */
#define AMPLIFY_MP_VAL        -3  /* invalid input */
#define AMPLIFY_MP_RANGE      (AMPLIFY_MP_DEPRECATED_PRAGMA("AMPLIFY_MP_RANGE has been deprecated in favor of AMPLIFY_MP_VAL") AMPLIFY_MP_VAL)
#define AMPLIFY_MP_ITER       -4  /* maximum iterations reached */
#define AMPLIFY_MP_BUF        -5  /* buffer overflow, supplied buffer too small */
typedef int amplify_mp_order;
#define AMPLIFY_MP_LSB_FIRST -1
#define AMPLIFY_MP_MSB_FIRST  1
typedef int amplify_mp_endian;
#define AMPLIFY_MP_LITTLE_ENDIAN  -1
#define AMPLIFY_MP_NATIVE_ENDIAN  0
#define AMPLIFY_MP_BIG_ENDIAN     1
#endif

/* tunable cutoffs */

#ifndef AMPLIFY_MP_FIXED_CUTOFFS
extern int
AMPLIFY_KARATSUBA_MUL_CUTOFF,
AMPLIFY_KARATSUBA_SQR_CUTOFF,
AMPLIFY_TOOM_MUL_CUTOFF,
AMPLIFY_TOOM_SQR_CUTOFF;
#endif

/* define this to use lower memory usage routines (exptmods mostly) */
/* #define AMPLIFY_MP_LOW_MEM */

/* default precision */
#ifndef AMPLIFY_MP_PREC
#   ifndef AMPLIFY_MP_LOW_MEM
#      define PRIVATE_MP_PREC 32        /* default digits of precision */
#   elif defined(AMPLIFY_MP_8BIT)
#      define PRIVATE_MP_PREC 16        /* default digits of precision */
#   else
#      define PRIVATE_MP_PREC 8         /* default digits of precision */
#   endif
#   define AMPLIFY_MP_PREC (AMPLIFY_MP_DEPRECATED_PRAGMA("AMPLIFY_MP_PREC is an internal macro") PRIVATE_MP_PREC)
#endif

/* size of comba arrays, should be at least 2 * 2**(BITS_PER_WORD - BITS_PER_DIGIT*2) */
#define PRIVATE_AMPLIFY_MP_WARRAY (int)(1uLL << (((CHAR_BIT * sizeof(private_mp_word)) - (2 * AMPLIFY_MP_DIGIT_BIT)) + 1))
#define AMPLIFY_MP_WARRAY (AMPLIFY_MP_DEPRECATED_PRAGMA("AMPLIFY_MP_WARRAY is an internal macro") PRIVATE_AMPLIFY_MP_WARRAY)

#if defined(__GNUC__) && __GNUC__ >= 4
#   define AMPLIFY_MP_NULL_TERMINATED __attribute__((sentinel))
#else
#   define AMPLIFY_MP_NULL_TERMINATED
#endif

/*
 * AMPLIFY_MP_WUR - warn unused result
 * ---------------------------
 *
 * The result of functions annotated with AMPLIFY_MP_WUR must be
 * checked and cannot be ignored.
 *
 * Most functions in libtommath return an error code.
 * This error code must be checked in order to prevent crashes or invalid
 * results.
 *
 * If you still want to avoid the error checks for quick and dirty programs
 * without robustness guarantees, you can `#define AMPLIFY_MP_WUR` before including
 * tommath.h, disabling the warnings.
 */
#ifndef AMPLIFY_MP_WUR
#  if defined(__GNUC__) && __GNUC__ >= 4
#     define AMPLIFY_MP_WUR __attribute__((warn_unused_result))
#  else
#     define AMPLIFY_MP_WUR
#  endif
#endif

#if defined(__GNUC__) && (__GNUC__ * 100 + __GNUC_MINOR__ >= 405)
#  define AMPLIFY_MP_DEPRECATED(x) __attribute__((deprecated("replaced by " #x)))
#  define PRIVATE_AMPLIFY_MP_DEPRECATED_PRAGMA(s) _Pragma(#s)
#  define AMPLIFY_MP_DEPRECATED_PRAGMA(s) PRIVATE_AMPLIFY_MP_DEPRECATED_PRAGMA(GCC warning s)
#elif defined(_MSC_VER) && _MSC_VER >= 1500
#  define AMPLIFY_MP_DEPRECATED(x) __declspec(deprecated("replaced by " #x))
#  define AMPLIFY_MP_DEPRECATED_PRAGMA(s) __pragma(message(s))
#else
#  define AMPLIFY_MP_DEPRECATED(s)
#  define AMPLIFY_MP_DEPRECATED_PRAGMA(s)
#endif

#define DIGIT_BIT   (AMPLIFY_MP_DEPRECATED_PRAGMA("DIGIT_BIT macro is deprecated, AMPLIFY_MP_DIGIT_BIT instead") AMPLIFY_MP_DIGIT_BIT)
#define USED(m)     (AMPLIFY_MP_DEPRECATED_PRAGMA("USED macro is deprecated, use z->used instead") (m)->used)
#define DIGIT(m, k) (AMPLIFY_MP_DEPRECATED_PRAGMA("DIGIT macro is deprecated, use z->dp instead") (m)->dp[(k)])
#define SIGN(m)     (AMPLIFY_MP_DEPRECATED_PRAGMA("SIGN macro is deprecated, use z->sign instead") (m)->sign)

/* the infamous amplify_mp_int structure */
typedef struct  {
   int used, alloc;
   amplify_mp_sign sign;
   amplify_mp_digit *dp;
} amplify_mp_int;

/* callback for amplify_mp_prime_random, should fill dst with random bytes and return how many read [upto len] */
typedef int private_amplify_mp_prime_callback(unsigned char *dst, int len, void *dat);
typedef private_amplify_mp_prime_callback AMPLIFY_MP_DEPRECATED(amplify_mp_rand_source) ltm_prime_callback;

/* error code to char* string */
const char *amplify_mp_error_to_string(amplify_mp_err code) AMPLIFY_MP_WUR;

/* ---> init and deinit bignum functions <--- */
/* init a bignum */
amplify_mp_err amplify_mp_init(amplify_mp_int *a) AMPLIFY_MP_WUR;

/* free a bignum */
void amplify_mp_clear(amplify_mp_int *a);

/* init a null terminated series of arguments */
amplify_mp_err amplify_mp_init_multi(amplify_mp_int *mp, ...) AMPLIFY_MP_NULL_TERMINATED AMPLIFY_MP_WUR;

/* clear a null terminated series of arguments */
void amplify_mp_clear_multi(amplify_mp_int *mp, ...) AMPLIFY_MP_NULL_TERMINATED;

/* exchange two ints */
void amplify_mp_exch(amplify_mp_int *a, amplify_mp_int *b);

/* shrink ram required for a bignum */
amplify_mp_err amplify_mp_shrink(amplify_mp_int *a) AMPLIFY_MP_WUR;

/* grow an int to a given size */
amplify_mp_err amplify_mp_grow(amplify_mp_int *a, int size) AMPLIFY_MP_WUR;

/* init to a given number of digits */
amplify_mp_err amplify_mp_init_size(amplify_mp_int *a, int size) AMPLIFY_MP_WUR;

/* ---> Basic Manipulations <--- */
#define amplify_mp_iszero(a) (((a)->used == 0) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO)
amplify_mp_bool amplify_mp_iseven(const amplify_mp_int *a) AMPLIFY_MP_WUR;
amplify_mp_bool amplify_mp_isodd(const amplify_mp_int *a) AMPLIFY_MP_WUR;
#define amplify_mp_isneg(a)  (((a)->sign != AMPLIFY_MP_ZPOS) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO)

/* set to zero */
void amplify_mp_zero(amplify_mp_int *a);

/* get and set doubles */
double amplify_mp_get_double(const amplify_mp_int *a) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_set_double(amplify_mp_int *a, double b) AMPLIFY_MP_WUR;

/* get integer, set integer and init with integer (int32_t) */
int32_t amplify_mp_get_i32(const amplify_mp_int *a) AMPLIFY_MP_WUR;
void amplify_mp_set_i32(amplify_mp_int *a, int32_t b);
amplify_mp_err amplify_mp_init_i32(amplify_mp_int *a, int32_t b) AMPLIFY_MP_WUR;

/* get integer, set integer and init with integer, behaves like two complement for negative numbers (uint32_t) */
#define amplify_mp_get_u32(a) ((uint32_t)amplify_mp_get_i32(a))
void amplify_mp_set_u32(amplify_mp_int *a, uint32_t b);
amplify_mp_err amplify_amplify_mp_init_u32(amplify_mp_int *a, uint32_t b) AMPLIFY_MP_WUR;

/* get integer, set integer and init with integer (int64_t) */
int64_t amplify_mp_get_i64(const amplify_mp_int *a) AMPLIFY_MP_WUR;
void amplify_mp_set_i64(amplify_mp_int *a, int64_t b);
amplify_mp_err amplify_mp_init_i64(amplify_mp_int *a, int64_t b) AMPLIFY_MP_WUR;

/* get integer, set integer and init with integer, behaves like two complement for negative numbers (uint64_t) */
#define amplify_mp_get_u64(a) ((uint64_t)amplify_mp_get_i64(a))
void amplify_mp_set_u64(amplify_mp_int *a, uint64_t b);
amplify_mp_err amplify_mp_init_u64(amplify_mp_int *a, uint64_t b) AMPLIFY_MP_WUR;

/* get magnitude */
uint32_t amplify_mp_get_mag_u32(const amplify_mp_int *a) AMPLIFY_MP_WUR;
uint64_t amplify_mp_get_mag_u64(const amplify_mp_int *a) AMPLIFY_MP_WUR;
unsigned long amplify_mp_get_mag_ul(const amplify_mp_int *a) AMPLIFY_MP_WUR;
unsigned long long amplify_mp_get_mag_ull(const amplify_mp_int *a) AMPLIFY_MP_WUR;

/* get integer, set integer (long) */
long amplify_mp_get_l(const amplify_mp_int *a) AMPLIFY_MP_WUR;
void amplify_mp_set_l(amplify_mp_int *a, long b);
amplify_mp_err amplify_mp_init_l(amplify_mp_int *a, long b) AMPLIFY_MP_WUR;

/* get integer, set integer (unsigned long) */
#define amplify_mp_get_ul(a) ((unsigned long)amplify_mp_get_l(a))
void amplify_mp_set_ul(amplify_mp_int *a, unsigned long b);
amplify_mp_err amplify_mp_init_ul(amplify_mp_int *a, unsigned long b) AMPLIFY_MP_WUR;

/* get integer, set integer (long long) */
long long amplify_mp_get_ll(const amplify_mp_int *a) AMPLIFY_MP_WUR;
void amplify_mp_set_ll(amplify_mp_int *a, long long b);
amplify_mp_err amplify_mp_init_ll(amplify_mp_int *a, long long b) AMPLIFY_MP_WUR;

/* get integer, set integer (unsigned long long) */
#define amplify_mp_get_ull(a) ((unsigned long long)amplify_mp_get_ll(a))
void amplify_mp_set_ull(amplify_mp_int *a, unsigned long long b);
amplify_mp_err amplify_mp_init_ull(amplify_mp_int *a, unsigned long long b) AMPLIFY_MP_WUR;

/* set to single unsigned digit, up to AMPLIFY_MP_DIGIT_MAX */
void amplify_mp_set(amplify_mp_int *a, amplify_mp_digit b);
amplify_mp_err amplify_mp_init_set(amplify_mp_int *a, amplify_mp_digit b) AMPLIFY_MP_WUR;

/* get integer, set integer and init with integer (deprecated) */
AMPLIFY_MP_DEPRECATED(amplify_mp_get_mag_u32/amplify_mp_get_u32) unsigned long amplify_mp_get_int(const amplify_mp_int *a) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_get_mag_ul/amplify_mp_get_ul) unsigned long amplify_mp_get_long(const amplify_mp_int *a) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_get_mag_ull/amplify_mp_get_ull) unsigned long long amplify_mp_get_long_long(const amplify_mp_int *a) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_set_ul) amplify_mp_err amplify_mp_set_int(amplify_mp_int *a, unsigned long b);
AMPLIFY_MP_DEPRECATED(amplify_mp_set_ul) amplify_mp_err amplify_mp_set_long(amplify_mp_int *a, unsigned long b);
AMPLIFY_MP_DEPRECATED(amplify_mp_set_ull) amplify_mp_err amplify_mp_set_long_long(amplify_mp_int *a, unsigned long long b);
AMPLIFY_MP_DEPRECATED(amplify_mp_init_ul) amplify_mp_err amplify_amplify_mp_init_set_int(amplify_mp_int *a, unsigned long b) AMPLIFY_MP_WUR;

/* copy, b = a */
amplify_mp_err amplify_mp_copy(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* inits and copies, a = b */
amplify_mp_err amplify_mp_init_copy(amplify_mp_int *a, const amplify_mp_int *b) AMPLIFY_MP_WUR;

/* trim unused digits */
void amplify_mp_clamp(amplify_mp_int *a);


/* export binary data */
AMPLIFY_MP_DEPRECATED(amplify_mp_pack) amplify_mp_err amplify_mp_export(void *rop, size_t *countp, int order, size_t size,
                                        int endian, size_t nails, const amplify_mp_int *op) AMPLIFY_MP_WUR;

/* import binary data */
AMPLIFY_MP_DEPRECATED(amplify_mp_unpack) amplify_mp_err amplify_mp_import(amplify_mp_int *rop, size_t count, int order,
      size_t size, int endian, size_t nails,
      const void *op) AMPLIFY_MP_WUR;

/* unpack binary data */
amplify_mp_err amplify_mp_unpack(amplify_mp_int *rop, size_t count, amplify_mp_order order, size_t size, amplify_mp_endian endian,
                 size_t nails, const void *op) AMPLIFY_MP_WUR;

/* pack binary data */
size_t amplify_mp_pack_count(const amplify_mp_int *a, size_t nails, size_t size) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_pack(void *rop, size_t maxcount, size_t *written, amplify_mp_order order, size_t size,
               amplify_mp_endian endian, size_t nails, const amplify_mp_int *op) AMPLIFY_MP_WUR;

/* ---> digit manipulation <--- */

/* right shift by "b" digits */
void amplify_mp_rshd(amplify_mp_int *a, int b);

/* left shift by "b" digits */
amplify_mp_err amplify_mp_lshd(amplify_mp_int *a, int b) AMPLIFY_MP_WUR;

/* c = a / 2**b, implemented as c = a >> b */
amplify_mp_err amplify_mp_div_2d(const amplify_mp_int *a, int b, amplify_mp_int *c, amplify_mp_int *d) AMPLIFY_MP_WUR;

/* b = a/2 */
amplify_mp_err amplify_mp_div_2(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* a/3 => 3c + d == a */
amplify_mp_err amplify_mp_div_3(const amplify_mp_int *a, amplify_mp_int *c, amplify_mp_digit *d) AMPLIFY_MP_WUR;

/* c = a * 2**b, implemented as c = a << b */
amplify_mp_err amplify_mp_mul_2d(const amplify_mp_int *a, int b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* b = a*2 */
amplify_mp_err amplify_mp_mul_2(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* c = a mod 2**b */
amplify_mp_err amplify_mp_mod_2d(const amplify_mp_int *a, int b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* computes a = 2**b */
amplify_mp_err amplify_mp_2expt(amplify_mp_int *a, int b) AMPLIFY_MP_WUR;

/* Counts the number of lsbs which are zero before the first zero bit */
int amplify_mp_cnt_lsb(const amplify_mp_int *a) AMPLIFY_MP_WUR;

/* I Love Earth! */

/* makes a pseudo-random amplify_mp_int of a given size */
amplify_mp_err amplify_mp_rand(amplify_mp_int *a, int digits) AMPLIFY_MP_WUR;
/* makes a pseudo-random small int of a given size */
AMPLIFY_MP_DEPRECATED(amplify_mp_rand) amplify_mp_err amplify_mp_rand_digit(amplify_mp_digit *r) AMPLIFY_MP_WUR;
/* use custom random data source instead of source provided the platform */
void amplify_mp_rand_source(amplify_mp_err(*source)(void *out, size_t size));

#ifdef AMPLIFY_MP_PRNG_ENABLE_LTM_RNG
#  warning AMPLIFY_MP_PRNG_ENABLE_LTM_RNG has been deprecated, use amplify_mp_rand_source instead.
/* A last resort to provide random data on systems without any of the other
 * implemented ways to gather entropy.
 * It is compatible with `rng_get_bytes()` from libtomcrypt so you could
 * provide that one and then set `ltm_rng = rng_get_bytes;` */
extern unsigned long (*ltm_rng)(unsigned char *out, unsigned long outlen, void (*callback)(void));
extern void (*ltm_rng_callback)(void);
#endif

/* ---> binary operations <--- */

/* Checks the bit at position b and returns AMPLIFY_MP_YES
 * if the bit is 1, AMPLIFY_MP_NO if it is 0 and AMPLIFY_MP_VAL
 * in case of error
 */
AMPLIFY_MP_DEPRECATED(amplify_s_mp_get_bit) int amplify_mp_get_bit(const amplify_mp_int *a, int b) AMPLIFY_MP_WUR;

/* c = a XOR b (two complement) */
AMPLIFY_MP_DEPRECATED(amplify_mp_xor) amplify_mp_err amplify_mp_tc_xor(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_xor(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = a OR b (two complement) */
AMPLIFY_MP_DEPRECATED(amplify_mp_or) amplify_mp_err amplify_mp_tc_or(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_or(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = a AND b (two complement) */
AMPLIFY_MP_DEPRECATED(amplify_mp_and) amplify_mp_err amplify_mp_tc_and(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_and(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* b = ~a (bitwise not, two complement) */
amplify_mp_err amplify_mp_complement(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* right shift with sign extension */
AMPLIFY_MP_DEPRECATED(amplify_amplify_mp_signed_rsh) amplify_mp_err amplify_mp_tc_div_2d(const amplify_mp_int *a, int b, amplify_mp_int *c) AMPLIFY_MP_WUR;
amplify_mp_err amplify_amplify_mp_signed_rsh(const amplify_mp_int *a, int b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* ---> Basic arithmetic <--- */

/* b = -a */
amplify_mp_err amplify_mp_neg(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* b = |a| */
amplify_mp_err amplify_mp_abs(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* compare a to b */
amplify_mp_ord amplify_mp_cmp(const amplify_mp_int *a, const amplify_mp_int *b) AMPLIFY_MP_WUR;

/* compare |a| to |b| */
amplify_mp_ord amplify_mp_cmp_mag(const amplify_mp_int *a, const amplify_mp_int *b) AMPLIFY_MP_WUR;

/* c = a + b */
amplify_mp_err amplify_mp_add(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = a - b */
amplify_mp_err amplify_mp_sub(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = a * b */
amplify_mp_err amplify_mp_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* b = a*a  */
amplify_mp_err amplify_mp_sqr(const amplify_mp_int *a, amplify_mp_int *b) AMPLIFY_MP_WUR;

/* a/b => cb + d == a */
amplify_mp_err amplify_mp_div(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, amplify_mp_int *d) AMPLIFY_MP_WUR;

/* c = a mod b, 0 <= c < b  */
amplify_mp_err amplify_mp_mod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* Increment "a" by one like "a++". Changes input! */
amplify_mp_err amplify_mp_incr(amplify_mp_int *a) AMPLIFY_MP_WUR;

/* Decrement "a" by one like "a--". Changes input! */
amplify_mp_err amplify_mp_decr(amplify_mp_int *a) AMPLIFY_MP_WUR;

/* ---> single digit functions <--- */

/* compare against a single digit */
amplify_mp_ord amplify_mp_cmp_d(const amplify_mp_int *a, amplify_mp_digit b) AMPLIFY_MP_WUR;

/* c = a + b */
amplify_mp_err amplify_amplify_mp_add_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = a - b */
amplify_mp_err amplify_mp_sub_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = a * b */
amplify_mp_err amplify_mp_mul_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* a/b => cb + d == a */
amplify_mp_err amplify_mp_div_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c, amplify_mp_digit *d) AMPLIFY_MP_WUR;

/* c = a mod b, 0 <= c < b  */
amplify_mp_err amplify_mp_mod_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_digit *c) AMPLIFY_MP_WUR;

/* ---> number theory <--- */

/* d = a + b (mod c) */
amplify_mp_err amplify_mp_addmod(const amplify_mp_int *a, const amplify_mp_int *b, const amplify_mp_int *c, amplify_mp_int *d) AMPLIFY_MP_WUR;

/* d = a - b (mod c) */
amplify_mp_err amplify_mp_submod(const amplify_mp_int *a, const amplify_mp_int *b, const amplify_mp_int *c, amplify_mp_int *d) AMPLIFY_MP_WUR;

/* d = a * b (mod c) */
amplify_mp_err amplify_mp_mulmod(const amplify_mp_int *a, const amplify_mp_int *b, const amplify_mp_int *c, amplify_mp_int *d) AMPLIFY_MP_WUR;

/* c = a * a (mod b) */
amplify_mp_err amplify_mp_sqrmod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = 1/a (mod b) */
amplify_mp_err amplify_mp_invmod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* c = (a, b) */
amplify_mp_err amplify_mp_gcd(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* produces value such that U1*a + U2*b = U3 */
amplify_mp_err amplify_mp_exteuclid(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *U1, amplify_mp_int *U2, amplify_mp_int *U3) AMPLIFY_MP_WUR;

/* c = [a, b] or (a*b)/(a, b) */
amplify_mp_err amplify_mp_lcm(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c) AMPLIFY_MP_WUR;

/* finds one of the b'th root of a, such that |c|**b <= |a|
 *
 * returns error if a < 0 and b is even
 */
amplify_mp_err amplify_mp_root_u32(const amplify_mp_int *a, uint32_t b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_root_u32) amplify_mp_err amplify_mp_n_root(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_root_u32) amplify_mp_err amplify_amplify_mp_n_root_ex(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c, int fast) AMPLIFY_MP_WUR;

/* special sqrt algo */
amplify_mp_err amplify_mp_sqrt(const amplify_mp_int *arg, amplify_mp_int *ret) AMPLIFY_MP_WUR;

/* special sqrt (mod prime) */
amplify_mp_err amplify_mp_sqrtmod_prime(const amplify_mp_int *n, const amplify_mp_int *prime, amplify_mp_int *ret) AMPLIFY_MP_WUR;

/* is number a square? */
amplify_mp_err amplify_mp_is_square(const amplify_mp_int *arg, amplify_mp_bool *ret) AMPLIFY_MP_WUR;

/* computes the jacobi c = (a | n) (or Legendre if b is prime)  */
AMPLIFY_MP_DEPRECATED(amplify_mp_kronecker) amplify_mp_err amplify_mp_jacobi(const amplify_mp_int *a, const amplify_mp_int *n, int *c) AMPLIFY_MP_WUR;

/* computes the Kronecker symbol c = (a | p) (like jacobi() but with {a,p} in Z */
amplify_mp_err amplify_mp_kronecker(const amplify_mp_int *a, const amplify_mp_int *p, int *c) AMPLIFY_MP_WUR;

/* used to setup the Barrett reduction for a given modulus b */
amplify_mp_err amplify_mp_reduce_setup(amplify_mp_int *a, const amplify_mp_int *b) AMPLIFY_MP_WUR;

/* Barrett Reduction, computes a (mod b) with a precomputed value c
 *
 * Assumes that 0 < x <= m*m, note if 0 > x > -(m*m) then you can merely
 * compute the reduction as -1 * amplify_mp_reduce(amplify_mp_abs(x)) [pseudo code].
 */
amplify_mp_err amplify_mp_reduce(amplify_mp_int *x, const amplify_mp_int *m, const amplify_mp_int *mu) AMPLIFY_MP_WUR;

/* setups the montgomery reduction */
amplify_mp_err amplify_mp_montgomery_setup(const amplify_mp_int *n, amplify_mp_digit *rho) AMPLIFY_MP_WUR;

/* computes a = B**n mod b without division or multiplication useful for
 * normalizing numbers in a Montgomery system.
 */
amplify_mp_err amplify_mp_montgomery_calc_normalization(amplify_mp_int *a, const amplify_mp_int *b) AMPLIFY_MP_WUR;

/* computes x/R == x (mod N) via Montgomery Reduction */
amplify_mp_err amplify_mp_montgomery_reduce(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit rho) AMPLIFY_MP_WUR;

/* returns 1 if a is a valid DR modulus */
amplify_mp_bool amplify_mp_dr_is_modulus(const amplify_mp_int *a) AMPLIFY_MP_WUR;

/* sets the value of "d" required for amplify_mp_dr_reduce */
void amplify_mp_dr_setup(const amplify_mp_int *a, amplify_mp_digit *d);

/* reduces a modulo n using the Diminished Radix method */
amplify_mp_err amplify_mp_dr_reduce(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit k) AMPLIFY_MP_WUR;

/* returns true if a can be reduced with amplify_mp_reduce_2k */
amplify_mp_bool amplify_mp_reduce_is_2k(const amplify_mp_int *a) AMPLIFY_MP_WUR;

/* determines k value for 2k reduction */
amplify_mp_err amplify_mp_reduce_2k_setup(const amplify_mp_int *a, amplify_mp_digit *d) AMPLIFY_MP_WUR;

/* reduces a modulo b where b is of the form 2**p - k [0 <= a] */
amplify_mp_err amplify_mp_reduce_2k(amplify_mp_int *a, const amplify_mp_int *n, amplify_mp_digit d) AMPLIFY_MP_WUR;

/* returns true if a can be reduced with amplify_mp_reduce_2k_l */
amplify_mp_bool amplify_mp_reduce_is_2k_l(const amplify_mp_int *a) AMPLIFY_MP_WUR;

/* determines k value for 2k reduction */
amplify_mp_err amplify_mp_reduce_2k_setup_l(const amplify_mp_int *a, amplify_mp_int *d) AMPLIFY_MP_WUR;

/* reduces a modulo b where b is of the form 2**p - k [0 <= a] */
amplify_mp_err amplify_mp_reduce_2k_l(amplify_mp_int *a, const amplify_mp_int *n, const amplify_mp_int *d) AMPLIFY_MP_WUR;

/* Y = G**X (mod P) */
amplify_mp_err amplify_mp_exptmod(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P, amplify_mp_int *Y) AMPLIFY_MP_WUR;

/* ---> Primes <--- */

/* number of primes */
#ifdef AMPLIFY_MP_8BIT
#  define PRIVATE_MP_PRIME_TAB_SIZE 31
#else
#  define PRIVATE_MP_PRIME_TAB_SIZE 256
#endif
#define PRIME_SIZE (AMPLIFY_MP_DEPRECATED_PRAGMA("PRIME_SIZE has been made internal") PRIVATE_MP_PRIME_TAB_SIZE)

/* table of first PRIME_SIZE primes */
AMPLIFY_MP_DEPRECATED(internal) extern const amplify_mp_digit ltm_prime_tab[PRIVATE_MP_PRIME_TAB_SIZE];

/* result=1 if a is divisible by one of the first PRIME_SIZE primes */
AMPLIFY_MP_DEPRECATED(amplify_mp_prime_is_prime) amplify_mp_err amplify_mp_prime_is_divisible(const amplify_mp_int *a, amplify_mp_bool *result) AMPLIFY_MP_WUR;

/* performs one Fermat test of "a" using base "b".
 * Sets result to 0 if composite or 1 if probable prime
 */
amplify_mp_err amplify_mp_prime_fermat(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_bool *result) AMPLIFY_MP_WUR;

/* performs one Miller-Rabin test of "a" using base "b".
 * Sets result to 0 if composite or 1 if probable prime
 */
amplify_mp_err amplify_mp_prime_miller_rabin(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_bool *result) AMPLIFY_MP_WUR;

/* This gives [for a given bit size] the number of trials required
 * such that Miller-Rabin gives a prob of failure lower than 2^-96
 */
int amplify_mp_prime_rabin_miller_trials(int size) AMPLIFY_MP_WUR;

/* performs one strong Lucas-Selfridge test of "a".
 * Sets result to 0 if composite or 1 if probable prime
 */
amplify_mp_err amplify_mp_prime_strong_lucas_selfridge(const amplify_mp_int *a, amplify_mp_bool *result) AMPLIFY_MP_WUR;

/* performs one Frobenius test of "a" as described by Paul Underwood.
 * Sets result to 0 if composite or 1 if probable prime
 */
amplify_mp_err amplify_mp_prime_frobenius_underwood(const amplify_mp_int *N, amplify_mp_bool *result) AMPLIFY_MP_WUR;

/* performs t random rounds of Miller-Rabin on "a" additional to
 * bases 2 and 3.  Also performs an initial sieve of trial
 * division.  Determines if "a" is prime with probability
 * of error no more than (1/4)**t.
 * Both a strong Lucas-Selfridge to complete the BPSW test
 * and a separate Frobenius test are available at compile time.
 * With t<0 a deterministic test is run for primes up to
 * 318665857834031151167461. With t<13 (abs(t)-13) additional
 * tests with sequential small primes are run starting at 43.
 * Is Fips 186.4 compliant if called with t as computed by
 * amplify_mp_prime_rabin_miller_trials();
 *
 * Sets result to 1 if probably prime, 0 otherwise
 */
amplify_mp_err amplify_mp_prime_is_prime(const amplify_mp_int *a, int t, amplify_mp_bool *result) AMPLIFY_MP_WUR;

/* finds the next prime after the number "a" using "t" trials
 * of Miller-Rabin.
 *
 * bbs_style = 1 means the prime must be congruent to 3 mod 4
 */
amplify_mp_err amplify_mp_prime_next_prime(amplify_mp_int *a, int t, int bbs_style) AMPLIFY_MP_WUR;

/* makes a truly random prime of a given size (bytes),
 * call with bbs = 1 if you want it to be congruent to 3 mod 4
 *
 * You have to supply a callback which fills in a buffer with random bytes.  "dat" is a parameter you can
 * have passed to the callback (e.g. a state or something).  This function doesn't use "dat" itself
 * so it can be NULL
 *
 * The prime generated will be larger than 2^(8*size).
 */
#define amplify_mp_prime_random(a, t, size, bbs, cb, dat) (AMPLIFY_MP_DEPRECATED_PRAGMA("amplify_mp_prime_random has been deprecated, use amplify_mp_prime_rand instead") amplify_mp_prime_random_ex(a, t, ((size) * 8) + 1, (bbs==1)?AMPLIFY_MP_PRIME_BBS:0, cb, dat))

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
AMPLIFY_MP_DEPRECATED(amplify_mp_prime_rand) amplify_mp_err amplify_mp_prime_random_ex(amplify_mp_int *a, int t, int size, int flags,
      private_amplify_mp_prime_callback cb, void *dat) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_prime_rand(amplify_mp_int *a, int t, int size, int flags) AMPLIFY_MP_WUR;

/* Integer logarithm to integer base */
amplify_mp_err amplify_mp_log_u32(const amplify_mp_int *a, uint32_t base, uint32_t *c) AMPLIFY_MP_WUR;

/* c = a**b */
amplify_mp_err amplify_mp_expt_u32(const amplify_mp_int *a, uint32_t b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_expt_u32) amplify_mp_err amplify_mp_expt_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_expt_u32) amplify_mp_err amplify_mp_expt_d_ex(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c, int fast) AMPLIFY_MP_WUR;

/* ---> radix conversion <--- */
int amplify_mp_count_bits(const amplify_mp_int *a) AMPLIFY_MP_WUR;


AMPLIFY_MP_DEPRECATED(amplify_mp_ubin_size) int amplify_mp_unsigned_bin_size(const amplify_mp_int *a) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_from_ubin) amplify_mp_err amplify_mp_read_unsigned_bin(amplify_mp_int *a, const unsigned char *b, int c) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_to_ubin) amplify_mp_err amplify_mp_to_unsigned_bin(const amplify_mp_int *a, unsigned char *b) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_to_ubin) amplify_mp_err amplify_mp_to_unsigned_bin_n(const amplify_mp_int *a, unsigned char *b, unsigned long *outlen) AMPLIFY_MP_WUR;

AMPLIFY_MP_DEPRECATED(amplify_mp_sbin_size) int amplify_amplify_mp_signed_bin_size(const amplify_mp_int *a) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_from_sbin) amplify_mp_err amplify_mp_read_signed_bin(amplify_mp_int *a, const unsigned char *b, int c) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_to_sbin) amplify_mp_err amplify_mp_to_signed_bin(const amplify_mp_int *a,  unsigned char *b) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_to_sbin) amplify_mp_err amplify_mp_to_signed_bin_n(const amplify_mp_int *a, unsigned char *b, unsigned long *outlen) AMPLIFY_MP_WUR;

size_t amplify_mp_ubin_size(const amplify_mp_int *a) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_from_ubin(amplify_mp_int *a, const unsigned char *buf, size_t size) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_to_ubin(const amplify_mp_int *a, unsigned char *buf, size_t maxlen, size_t *written) AMPLIFY_MP_WUR;

size_t amplify_mp_sbin_size(const amplify_mp_int *a) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_from_sbin(amplify_mp_int *a, const unsigned char *buf, size_t size) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_to_sbin(const amplify_mp_int *a, unsigned char *buf, size_t maxlen, size_t *written) AMPLIFY_MP_WUR;

amplify_mp_err amplify_mp_read_radix(amplify_mp_int *a, const char *str, int radix) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_to_radix) amplify_mp_err amplify_mp_toradix(const amplify_mp_int *a, char *str, int radix) AMPLIFY_MP_WUR;
AMPLIFY_MP_DEPRECATED(amplify_mp_to_radix) amplify_mp_err amplify_amplify_mp_toradix_n(const amplify_mp_int *a, char *str, int radix, int maxlen) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_to_radix(const amplify_mp_int *a, char *str, size_t maxlen, size_t *written, int radix) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_radix_size(const amplify_mp_int *a, int radix, int *size) AMPLIFY_MP_WUR;

#ifndef AMPLIFY_MP_NO_FILE
amplify_mp_err amplify_mp_fread(amplify_mp_int *a, int radix, FILE *stream) AMPLIFY_MP_WUR;
amplify_mp_err amplify_mp_fwrite(const amplify_mp_int *a, int radix, FILE *stream) AMPLIFY_MP_WUR;
#endif

#define amplify_mp_read_raw(mp, str, len) (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_read_signed_bin") amplify_mp_read_signed_bin((mp), (str), (len)))
#define amplify_mp_raw_size(mp)           (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_amplify_mp_signed_bin_size") amplify_amplify_mp_signed_bin_size(mp))
#define amplify_mp_toraw(mp, str)         (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_to_signed_bin") amplify_mp_to_signed_bin((mp), (str)))
#define amplify_mp_read_mag(mp, str, len) (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_read_unsigned_bin") amplify_mp_read_unsigned_bin((mp), (str), (len))
#define amplify_mp_mag_size(mp)           (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_unsigned_bin_size") amplify_mp_unsigned_bin_size(mp))
#define amplify_mp_tomag(mp, str)         (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_to_unsigned_bin") amplify_mp_to_unsigned_bin((mp), (str)))

#define amplify_mp_tobinary(M, S)  (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_to_binary")  amplify_mp_toradix((M), (S), 2))
#define amplify_mp_tooctal(M, S)   (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_to_octal")   amplify_mp_toradix((M), (S), 8))
#define amplify_mp_todecimal(M, S) (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_to_decimal") amplify_mp_toradix((M), (S), 10))
#define amplify_mp_tohex(M, S)     (AMPLIFY_MP_DEPRECATED_PRAGMA("replaced by amplify_mp_to_hex")     amplify_mp_toradix((M), (S), 16))

#define amplify_mp_to_binary(M, S, N)  amplify_mp_to_radix((M), (S), (N), NULL, 2)
#define amplify_mp_to_octal(M, S, N)   amplify_mp_to_radix((M), (S), (N), NULL, 8)
#define amplify_mp_to_decimal(M, S, N) amplify_mp_to_radix((M), (S), (N), NULL, 10)
#define amplify_mp_to_hex(M, S, N)     amplify_mp_to_radix((M), (S), (N), NULL, 16)

#ifdef __cplusplus
}
#endif

#endif
