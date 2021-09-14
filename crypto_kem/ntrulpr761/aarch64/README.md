# ntrulpr761

This directory contains the reference (`./ref`) and our optimized (`./opt`)
implementation for `ntrulpr761`. Furthermore the `./sup` directory contains our
optimized implementation, packaged for easy benchmarking with SUPERCOP. Please
ensure that the OpenSSL development package has been installed when attempting
to compile the source. You can do this by executing:

```bash
sudo apt update
sudo apt install libssl-dev
```

When compiling the source to verify correctness, simply execute `make`. This
will build the sources into an executable, compile the KAT generator, and
subsequently test the executable by running the KAT generator.

When compiling the source to benchmark the performance, simply execute `make
speed`. This will build the sources into an executable called `benchmark.out`
which you can execute to get speed numbers. The more preferred approach
however, is to use the SUPERCOP toolkit for benchmarking cryptographic
software. This toolkit includes various implementations for cryptographic
primitives such as generating random bytes which produces a more representative
benchmark when comparing with other key-encapsulation mechanisms.

Execute `make clean` to clean the directory.

# benchmarks

The current benchmark for the performance of the reference implementation is:

| Operation      | Cycles     |
| -------------- | ---------- |
| Key Generation | 37 537 806 |
| Encapsulation  | 60 747 989 |
| Decapsulation  | 90 930 810 |

The current benchmark for the performance of our optimized implementation, using
the SUPERCOP toolkit for benchmarking cryptographic software, is:

| Operation      | Cycles    |
| -------------- | --------- |
| Key Generation |   744 579 |
| Encapsulation  | 1 145 390 |
| Decapsulation  | 1 423 435 |

**In total** this means that the performance cost for the key generation,
encapsulation, and decapsulation of the reference implementation is reduced by
by 98.02%, 98.11%, and 98.43% respectively in our optimized implementation.
