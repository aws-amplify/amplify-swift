# libtommath

This is the fork for [LibTomMath](https://github.com/libtom/libtommath). Fork is created from the v1.2.0 at the commit 6ca6898bf37f583c4cc9943441cd60dd69f4b8f2 
With the following changes:

- Renamed files and variables with `amplify` prefix.
- Removed unsupported platform code from Sources/libtommath/amplify_bn_s_mp_rand_platform.c
- Removed compile time warning due to unreachable code in Sources/libtommath/amplify_bn_mp_set_double.c