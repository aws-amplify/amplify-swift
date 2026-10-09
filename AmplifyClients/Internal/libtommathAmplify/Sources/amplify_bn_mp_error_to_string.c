#include "amplify_tommath_private.h"
#ifdef AMPLIFY_BN_MP_ERROR_TO_STRING_C
/* LibTomMath, multiple-precision integer library -- Tom St Denis */
/* SPDX-License-Identifier: Unlicense */
/* Modifications Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved. */

/* return a char * string for a given code */
const char *amplify_mp_error_to_string(amplify_mp_err code)
{
   switch (code) {
   case AMPLIFY_MP_OKAY:
      return "Successful";
   case AMPLIFY_MP_ERR:
      return "Unknown error";
   case AMPLIFY_MP_MEM:
      return "Out of heap";
   case AMPLIFY_MP_VAL:
      return "Value out of range";
   case AMPLIFY_MP_ITER:
      return "Max. iterations reached";
   case AMPLIFY_MP_BUF:
      return "Buffer overflow";
   default:
      return "Invalid error code";
   }
}

#endif
