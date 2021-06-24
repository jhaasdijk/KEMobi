
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
compile the sources and run the execution 1000 times, taking the median of the
reported CPU cycle counts. This can be done by executing the following
instructions:

```shell
$ make
$ for number in {1..1000}; do ./ntt761.out; done \
    | sort \
    | awk '{ count[NR + 1] = $1; } END { print count[NR / 2]; }'

$ make ntt
$ for number in {1..1000}; do ./ntt512.out; done \
    | sort \
    | awk '{ count[NR + 1] = $1; } END { print count[NR / 2]; }'
```

The list below roughly keeps track of our progress.

* `20/05`

    | scheme     | implementation | Cycles       |
    | ------     | -------------- | ------       |
    | ntrulpr761 | 761 NTT        | med: 600.767 |

    This value can be used as a baseline for future implementations. No real
    optimizations have been implemented apart from the Montgomery reduction and
    the NTT based approach for polynomial multiplication in itself. Simple
    things like removing print statements and merging (or unrolling) for loops
    have not been done.

* `09/06`

    | scheme     | implementation | Cycles       |
    | ------     | -------------- | ------       |
    | ntrulpr761 | 761 NTT        | med: 457.216 |

    This value has been achieved after completely implementing the forward and
    inverse NTT transformations (including `reduce_coefficients`) inside
    assembly.

* `10/06`

    | scheme     | implementation | Cycles       |
    | ------     | -------------- | ------       |
    | ntrulpr761 | 512 NTT        | med:  83.093 |
    |            | 761 NTT        | med: 300.418 |

    Further reductions of the cost have been achieved by implementing a '`#define
    SPEED`' switch to easily toggle between enabling or suppressing printing
    debug information. The cycle counts are of course calculated _without_
    printing debug information.

    A separate entry has been added for keeping track of a single size 512 NTT
    application. '512 NTT' keeps track of the cost of performing `Zx(F) * Zx(G)
    % (x^512 - 1) % 6984193`. Please refer to `main512.c` for the
    implementation.

* `11/06`

    | scheme     | implementation | Cycles       |
    | ------     | -------------- | ------       |
    | ntrulpr761 | 512 NTT        | med:  69.034 |
    |            | 761 NTT        | med: 267.428 |

    Further reductions of the cost have been achieved by minimizing load, store
    and move instructions. This is mostly achieved by eliminating mov
    instructions in `_asimd_mul_red` and merging layers 1 and 2 in
    `asm_ntt_forward.s`. For more information please refer to cdc05d9 and
    5856c4a.

* `22/06`

```terminal
Zx(F) * Zx(G) % (x^512 - 1) % 6984193
| NTT forward          | med: 9466      |
| Product              | med: 6863      |
| NTT inverse          | med: 13813     |
| Complete             | med: 44287     |

Zx(F) * Zx(G) % (x^761 - x - 1) % 4591
| Zero padding         | med: 856       |
| Good's forward       | med: 5660      |
| NTT forward          | med: 9467      |
| Product              | med: 102947    |
| NTT inverse          | med: 13813     |
| Good's inverse       | med: 5661      |
| Zx % (x^761 - x - 1) | med: 3125      |
| Zx % 6984193         | med: 4588      |
| Zx % 4591            | med: 4588      |
| Complete             | med: 258518    |
```

More extensive and accurate benchmarking of the cost has been achieved by
warming up the cache and ensuring that it contains valid data. During
performance testing it is important to take the frequency of cache hits / cache
misses into account.

* `24/06`

```terminal
Zx(F) * Zx(G) % (x^512 - 1) % 6984193
| NTT forward          | med: 7946      |
| Product              | med: 6706      |
| NTT inverse          | med: 11659     |
| Complete             | med: 39132     |

Zx(F) * Zx(G) % (x^761 - x - 1) % 4591
| Zero padding         | med: 854       |
| Good's forward       | med: 5660      |
| NTT forward          | med: 7941      |
| Product              | med: 101500    |
| NTT inverse          | med: 11641     |
| Good's inverse       | med: 5661      |
| Zx % (x^761 - x - 1) | med: 3125      |
| Zx % 6984193         | med: 4588      |
| Zx % 4591            | med: 4588      |
| Complete             | med: 244226    |
```

Further reductions in the cycle count for 'NTT forward, NTT inverse' has been
achieved by minimizing load, store operations by merging multiple layers
together (1234, 567, 89) and preloading the required roots for 1234.

