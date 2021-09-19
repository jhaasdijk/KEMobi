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
which you can execute to get speed numbers.

Execute `make clean` to clean the directory.

# benchmarks

The current benchmark for the performance of the reference implementation is:

| Operation      | Cycles     |
| -------------- | ---------- |
| Key Generation | 37 537 806 |
| Encapsulation  | 60 747 989 |
| Decapsulation  | 90 930 810 |

The current benchmark for the performance of the optimized implementation is:

| Operation      | Cycles    |
| -------------- | --------- |
| Key Generation |   775 472 |
| Encapsulation  | 1 150 294 |
| Decapsulation  | 1 417 394 |

Similar results can be obtained using the SUPERCOP toolkit for benchmarking
cryptographic software. 

**In total** this means that the performance cost for the key generation,
encapsulation, and decapsulation of the reference implementation is reduced by
by 97.93%, 98.11%, and 98.44%, respectively in our optimized implementation.
