
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
instance `{1, 2, 3}` represents the polynomial 3x^2 + 2x + 1. Each coefficient
is represented as signed 32 bit integer (`int32_t`). This makes it easier to
identify and use numeric types properly instead of hiding what types are being
used under the hood.

* Since the modulus Q (6984193) defines that the largest integer coefficient can
be 6984192, we know that integer values are at most 23 bits long. We can use
this information in our choice for numeric types.

* Please be aware that in NTRU LPRime one of the multiplicands for the
polynomial multiplications is always small/short, i.e., has only coefficients in
{-1, 0, 1}. We can use this information in our choice for bounds and sizes.

## Benchmarks

The list below details the current implementation's performance. Included
optimizations are:

* The use of Montgomery multiplication (and reduction).
* The use of an NTT based approach for polynomial multiplication.
* Implementing the forward and inverse NTT using ASIMD assembly instructions.
* Minimizing load, store, and move instructions. E.g. by eliminating `mov`
  instructions whenever we can keep values inside a register.
* Merging multiple layers for the forward and inverse NTT transformation.
* Preloading the required roots for layers 1234.
* Eliminate multiplications by 1
* Optimize the merging of layers 8+9 by using LD4. This saves us from
  having to repack the coefficients in between the layer operations.

<br>

`Zx(F) * Zx(G) % (x^512 - 1) % 6984193`

| Fragment             | Cycles         |
| --------             | ------         |
| NTT forward          | med: 5933      |
| Product              | med: 6460      |
| NTT inverse          | med: 6686      |
| Complete             | med: 32309     |

<br>

`Zx(F) * Zx(G) % (x^761 - x - 1) % 4591`

| Fragment             | Cycles         |
| --------             | ------         |
| Zero padding         | med: 854       |
| Good's forward       | med: 5660      |
| NTT forward          | med: 5929      |
| Product              | med: 84286     |
| NTT inverse          | med: 6686      |
| Good's inverse       | med: 5661      |
| Zx % (x^761 - x - 1) | med: 3125      |
| Zx % 6984193         | med: 4588      |
| Zx % 4591            | med: 4588      |
| Complete             | med: 258987    |

More extensive and accurate benchmarking of the cost has been achieved by
warming up the cache and ensuring that it contains valid data. During
performance testing it is important to take the frequency of cache hits / cache
misses into account.
