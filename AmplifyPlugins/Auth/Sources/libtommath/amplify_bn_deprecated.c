#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_DEPRECATED_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

#ifdef AMPLIFY_BN_MP_GET_BIT_C
int amplify_mp_get_bit(const amplify_mp_int *a, int b)
{
   if (b < 0) {
      return AMPLIFY_MP_VAL;
   }
   return (amplify_s_mp_get_bit(a, (unsigned int)b) == AMPLIFY_MP_YES) ? AMPLIFY_MP_YES : AMPLIFY_MP_NO;
}
#endif
#ifdef AMPLIFY_BN_MP_JACOBI_C
amplify_mp_err amplify_mp_jacobi(const amplify_mp_int *a, const amplify_mp_int *n, int *c)
{
   if (a->sign == AMPLIFY_MP_NEG) {
      return AMPLIFY_MP_VAL;
   }
   if (amplify_mp_cmp_d(n, 0uL) != AMPLIFY_MP_GT) {
      return AMPLIFY_MP_VAL;
   }
   return amplify_mp_kronecker(a, n, c);
}
#endif
#ifdef AMPLIFY_BN_MP_PRIME_RANDOM_EX_C
amplify_mp_err amplify_mp_prime_random_ex(amplify_mp_int *a, int t, int size, int flags, private_amplify_mp_prime_callback cb, void *dat)
{
   return amplify_s_mp_prime_random_ex(a, t, size, flags, cb, dat);
}
#endif
#ifdef AMPLIFY_BN_MP_RAND_DIGIT_C
amplify_mp_err amplify_mp_rand_digit(amplify_mp_digit *r)
{
   amplify_mp_err err = amplify_s_mp_rand_source(r, sizeof(amplify_mp_digit));
   *r &= AMPLIFY_MP_MASK;
   return err;
}
#endif
#ifdef AMPLIFY_BN_FAST_MP_INVMOD_C
amplify_mp_err amplify_fast_mp_invmod(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_s_mp_invmod_fast(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_FAST_MP_MONTGOMERY_REDUCE_C
amplify_mp_err amplify_fast_mp_montgomery_reduce(amplify_mp_int *x, const amplify_mp_int *n, amplify_mp_digit rho)
{
   return amplify_s_mp_montgomery_reduce_fast(x, n, rho);
}
#endif
#ifdef AMPLIFY_BN_FAST_S_MP_MUL_DIGS_C
amplify_mp_err amplify_fast_s_mp_mul_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs)
{
   return amplify_s_mp_mul_digs_fast(a, b, c, digs);
}
#endif
#ifdef AMPLIFY_BN_FAST_S_MP_MUL_HIGH_DIGS_C
amplify_mp_err amplify_fast_s_mp_mul_high_digs(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c, int digs)
{
   return amplify_s_mp_mul_high_digs_fast(a, b, c, digs);
}
#endif
#ifdef AMPLIFY_BN_FAST_S_MP_SQR_C
amplify_mp_err amplify_fast_s_mp_sqr(const amplify_mp_int *a, amplify_mp_int *b)
{
   return amplify_s_mp_sqr_fast(a, b);
}
#endif
#ifdef AMPLIFY_BN_MP_BALANCE_MUL_C
amplify_mp_err amplify_mp_balance_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return s_amplify_mp_balance_mul(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_EXPTMOD_FAST_C
amplify_mp_err amplify_mp_exptmod_fast(const amplify_mp_int *G, const amplify_mp_int *X, const amplify_mp_int *P, amplify_mp_int *Y, int redmode)
{
   return amplify_s_mp_exptmod_fast(G, X, P, Y, redmode);
}
#endif
#ifdef AMPLIFY_BN_MP_INVMOD_SLOW_C
amplify_mp_err amplify_mp_invmod_slow(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_s_mp_invmod_slow(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_KARATSUBA_MUL_C
amplify_mp_err amplify_mp_karatsuba_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_s_mp_karatsuba_mul(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_KARATSUBA_SQR_C
amplify_mp_err amplify_mp_karatsuba_sqr(const amplify_mp_int *a, amplify_mp_int *b)
{
   return amplify_s_mp_karatsuba_sqr(a, b);
}
#endif
#ifdef AMPLIFY_BN_MP_TOOM_MUL_C
amplify_mp_err amplify_mp_toom_mul(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_s_mp_toom_mul(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_TOOM_SQR_C
amplify_mp_err amplify_mp_toom_sqr(const amplify_mp_int *a, amplify_mp_int *b)
{
   return amplify_s_mp_toom_sqr(a, b);
}
#endif
#ifdef AMPLIFY_S_MP_REVERSE_C
void amplify_bn_reverse(unsigned char *s, int len)
{
   if (len > 0) {
      amplify_s_mp_reverse(s, (size_t)len);
   }
}
#endif
#ifdef AMPLIFY_BN_MP_TC_AND_C
amplify_mp_err amplify_mp_tc_and(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_mp_and(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_TC_OR_C
amplify_mp_err amplify_mp_tc_or(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_mp_or(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_TC_XOR_C
amplify_mp_err amplify_mp_tc_xor(const amplify_mp_int *a, const amplify_mp_int *b, amplify_mp_int *c)
{
   return amplify_mp_xor(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_TC_DIV_2D_C
amplify_mp_err amplify_mp_tc_div_2d(const amplify_mp_int *a, int b, amplify_mp_int *c)
{
   return amplify_amplify_mp_signed_rsh(a, b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_INIT_SET_INT_C
amplify_mp_err amplify_amplify_mp_init_set_int(amplify_mp_int *a, unsigned long b)
{
   return amplify_amplify_mp_init_u32(a, (uint32_t)b);
}
#endif
#ifdef AMPLIFY_BN_MP_SET_INT_C
amplify_mp_err amplify_mp_set_int(amplify_mp_int *a, unsigned long b)
{
   amplify_mp_set_u32(a, (uint32_t)b);
   return AMPLIFY_MP_OKAY;
}
#endif
#ifdef AMPLIFY_BN_MP_SET_LONG_C
amplify_mp_err amplify_mp_set_long(amplify_mp_int *a, unsigned long b)
{
   amplify_mp_set_u64(a, b);
   return AMPLIFY_MP_OKAY;
}
#endif
#ifdef AMPLIFY_BN_MP_SET_LONG_LONG_C
amplify_mp_err amplify_mp_set_long_long(amplify_mp_int *a, unsigned long long b)
{
   amplify_mp_set_u64(a, b);
   return AMPLIFY_MP_OKAY;
}
#endif
#ifdef AMPLIFY_BN_MP_GET_INT_C
unsigned long amplify_mp_get_int(const amplify_mp_int *a)
{
   return (unsigned long)amplify_mp_get_mag_u32(a);
}
#endif
#ifdef AMPLIFY_BN_MP_GET_LONG_C
unsigned long amplify_mp_get_long(const amplify_mp_int *a)
{
   return (unsigned long)amplify_mp_get_mag_ul(a);
}
#endif
#ifdef AMPLIFY_BN_MP_GET_LONG_LONG_C
unsigned long long amplify_mp_get_long_long(const amplify_mp_int *a)
{
   return amplify_mp_get_mag_ull(a);
}
#endif
#ifdef AMPLIFY_BN_MP_PRIME_IS_DIVISIBLE_C
amplify_mp_err amplify_mp_prime_is_divisible(const amplify_mp_int *a, amplify_mp_bool *result)
{
   return amplify_s_mp_prime_is_divisible(a, result);
}
#endif
#ifdef AMPLIFY_BN_MP_EXPT_D_EX_C
amplify_mp_err amplify_mp_expt_d_ex(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c, int fast)
{
   (void)fast;
   if (b > AMPLIFY_MP_MIN(AMPLIFY_MP_DIGIT_MAX, UINT32_MAX)) {
      return AMPLIFY_MP_VAL;
   }
   return amplify_mp_expt_u32(a, (uint32_t)b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_EXPT_D_C
amplify_mp_err amplify_mp_expt_d(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c)
{
   if (b > AMPLIFY_MP_MIN(AMPLIFY_MP_DIGIT_MAX, UINT32_MAX)) {
      return AMPLIFY_MP_VAL;
   }
   return amplify_mp_expt_u32(a, (uint32_t)b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_N_ROOT_EX_C
amplify_mp_err amplify_amplify_mp_n_root_ex(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c, int fast)
{
   (void)fast;
   if (b > AMPLIFY_MP_MIN(AMPLIFY_MP_DIGIT_MAX, UINT32_MAX)) {
      return AMPLIFY_MP_VAL;
   }
   return amplify_mp_root_u32(a, (uint32_t)b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_N_ROOT_C
amplify_mp_err amplify_mp_n_root(const amplify_mp_int *a, amplify_mp_digit b, amplify_mp_int *c)
{
   if (b > AMPLIFY_MP_MIN(AMPLIFY_MP_DIGIT_MAX, UINT32_MAX)) {
      return AMPLIFY_MP_VAL;
   }
   return amplify_mp_root_u32(a, (uint32_t)b, c);
}
#endif
#ifdef AMPLIFY_BN_MP_UNSIGNED_BIN_SIZE_C
int amplify_mp_unsigned_bin_size(const amplify_mp_int *a)
{
   return (int)amplify_mp_ubin_size(a);
}
#endif
#ifdef AMPLIFY_BN_MP_READ_UNSIGNED_BIN_C
amplify_mp_err amplify_mp_read_unsigned_bin(amplify_mp_int *a, const unsigned char *b, int c)
{
   return amplify_mp_from_ubin(a, b, (size_t) c);
}
#endif
#ifdef AMPLIFY_BN_MP_TO_UNSIGNED_BIN_C
amplify_mp_err amplify_mp_to_unsigned_bin(const amplify_mp_int *a, unsigned char *b)
{
   return amplify_mp_to_ubin(a, b, SIZE_MAX, NULL);
}
#endif
#ifdef AMPLIFY_BN_MP_TO_UNSIGNED_BIN_N_C
amplify_mp_err amplify_mp_to_unsigned_bin_n(const amplify_mp_int *a, unsigned char *b, unsigned long *outlen)
{
   size_t n = amplify_mp_ubin_size(a);
   if (*outlen < (unsigned long)n) {
      return AMPLIFY_MP_VAL;
   }
   *outlen = (unsigned long)n;
   return amplify_mp_to_ubin(a, b, n, NULL);
}
#endif
#ifdef AMPLIFY_BN_MP_SIGNED_BIN_SIZE_C
int amplify_amplify_mp_signed_bin_size(const amplify_mp_int *a)
{
   return (int)amplify_mp_sbin_size(a);
}
#endif
#ifdef AMPLIFY_BN_MP_READ_SIGNED_BIN_C
amplify_mp_err amplify_mp_read_signed_bin(amplify_mp_int *a, const unsigned char *b, int c)
{
   return amplify_mp_from_sbin(a, b, (size_t) c);
}
#endif
#ifdef AMPLIFY_BN_MP_TO_SIGNED_BIN_C
amplify_mp_err amplify_mp_to_signed_bin(const amplify_mp_int *a, unsigned char *b)
{
   return amplify_mp_to_sbin(a, b, SIZE_MAX, NULL);
}
#endif
#ifdef AMPLIFY_BN_MP_TO_SIGNED_BIN_N_C
amplify_mp_err amplify_mp_to_signed_bin_n(const amplify_mp_int *a, unsigned char *b, unsigned long *outlen)
{
   size_t n = amplify_mp_sbin_size(a);
   if (*outlen < (unsigned long)n) {
      return AMPLIFY_MP_VAL;
   }
   *outlen = (unsigned long)n;
   return amplify_mp_to_sbin(a, b, n, NULL);
}
#endif
#ifdef AMPLIFY_BN_MP_TORADIX_N_C
amplify_mp_err amplify_amplify_mp_toradix_n(const amplify_mp_int *a, char *str, int radix, int maxlen)
{
   if (maxlen < 0) {
      return AMPLIFY_MP_VAL;
   }
   return amplify_mp_to_radix(a, str, (size_t)maxlen, NULL, radix);
}
#endif
#ifdef AMPLIFY_BN_MP_TORADIX_C
amplify_mp_err amplify_mp_toradix(const amplify_mp_int *a, char *str, int radix)
{
   return amplify_mp_to_radix(a, str, SIZE_MAX, NULL, radix);
}
#endif
#ifdef AMPLIFY_BN_MP_IMPORT_C
amplify_mp_err amplify_mp_import(amplify_mp_int *rop, size_t count, int order, size_t size, int endian, size_t nails,
                 const void *op)
{
   return amplify_mp_unpack(rop, count, order, size, endian, nails, op);
}
#endif
#ifdef AMPLIFY_BN_MP_EXPORT_C
amplify_mp_err amplify_mp_export(void *rop, size_t *countp, int order, size_t size,
                 int endian, size_t nails, const amplify_mp_int *op)
{
   return amplify_mp_pack(rop, SIZE_MAX, countp, order, size, endian, nails, op);
}
#endif
#endif
