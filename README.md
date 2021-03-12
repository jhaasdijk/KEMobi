# KEMobi

**Jasper Haasdijk**, March 2021.

This repository contains the source code for my Master Thesis Computing Science
at the Digital Security Group, Radboud University, Nijmegen, The Netherlands.

The directory structure currently looks like this:

```
$ tree -dL 2

.
├── enableccnt
├── ntruprime-20201007
│   ├── KAT
│   ├── Optimized_Implementation
│   ├── Reference_Implementation
│   └── Supporting_Documentation
└── samples
    ├── common
    ├── polyadd
    └── polymult
```

- `enableccnt` contains the source for setting up a kernel module to enable
user space access to the `PMCCNTR_EL0` System register. This allows us to
read the `PMCCNTR_EL0` register which holds the value of the processor cycle
counter.

- `ntruprime-20201007` contains the NTRU Prime software and supporting
documentation. This has been taken from the original NTRU Prime NISTPQC full
submission package, last updated 7 October 2020. All of this (and more) is
made available through their [web page](https://ntruprime.cr.yp.to/).

- `samples` contains three directories: `common`, `polyadd` and `polymult`.
The `common` directory is used for sharing components (C sources, Makefile)
which can be reused throughout the repository. The `polyadd` directory is
used to contain an initial assembler implementation of polynomial addition.
This directory is used to get familiar with the A64 instruction set,
specifically the A64 SIMD instructions. The `polymult` directory is used to
contain an initial implementation of cyclic convolution which can be used to
multiply two polynomials within the polynomial field `(Z/q) [x] / (x^p - x -
1)`.

## Installation

The software has been tested with the following platform, package and version
information.

```
uname -srom         Linux 5.10.17-v8+ aarch64 GNU/Linux
make --version      GNU Make 4.2.1
gcc --version       gcc (Debian 8.3.0-6) 8.3.0
```