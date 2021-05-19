
# Number Theoretic Transform (NTT)

This directory contains the **C** sources for performing NTT based polynomial
multiplication. It contains a complete implementation with which you can compare
and review how NTT based polynomial multiplication works, in C. Please refer to
the specific function or value for more details. Every function and constant
value has been documented extensively.

Please note that this directory has been optimized for **speed**, not for
readability.

## TLDR

* This source can be used to perform NTT based polynomial multiplication of two
polynomials for the NTRU LPRime 'kem/ntrulpr761' parameter set.

* While 761 is not an NTT friendly prime and the reduction polynomial is not of
the form x^n + 1 or x^n - 1, we can use Good's permutation after padding to size
1536 to perform 3 size 512 NTTs instead.  These smaller size 512 cyclic NTTs are
used to multiply polynomials in Z_6984193 [x] / (x^512 - 1).

* Instead of defining a custom type for representing polynomials, each
polynomial is represented using an array of its integer coefficients. For
instance {1, 2, 3} represents the polynomial 3x^2 + 2x + 1. Each coefficient is
represented as signed 32 bit integer (int32_t). This makes it easier to identify
and use numeric types properly instead of hiding what types are being used under
the hood.

* Since the modulus Q (6984193) defines that the largest integer coefficient can
be 6984192, we know that integer values are at most 23 bits long. We can use
this information in our choice for numeric types.

* Please be aware that in NTRU LPRime one of the multiplicands for the
polynomial multiplications is always small/short, i.e., has only coefficients in
{-1, 0, 1}. We can use this information in our choice for bounds and sizes.
