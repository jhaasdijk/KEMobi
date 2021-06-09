
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

## Benchmarks

Running benchmarks currently employs a rather simplified approach, simply to
establish the effect of intermediate changes on the overall cycle count. We
compile the sources and run the execution 500 times, taking the median of the
reported CPU cycle counts. This can be done by executing the following
instructions:

```shell
$ make
$ for number in {1..500}; do ./ntrulpr761.out; done \
    | grep -v 'This is correct!' \
    | sort \
    | awk '{ count[NR + 1] = $1; } END { print count[NR / 2]; }'
```

The list below roughly keeps track of our progress.

* `20/05 - 600767`<br>
This value can be used as a baseline for future implementations. No real
optimizations have been implemented apart from the Montgomery reduction and the
NTT based approach for polynomial multiplication in itself. Simple things like
removing print statements and merging (or unrolling) for loops have not been
done.

* `09/06 - 457216`<br>
This value has been achieved after completely implementing the forward and
inverse NTT transformations (including reduce_coefficients) inside assembly.
