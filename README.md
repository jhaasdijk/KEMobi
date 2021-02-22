# KEMobi

**Jasper Haasdijk**, February 2021.

This repository contains the source code for my Master Thesis Computing Science
at the Digital Security Group, Radboud University, Nijmegen, The Netherlands.

The directory structure currently looks like this:

```
$ tree -dL 1

.
├── enableccnt
├── ntruprime-20201007
└── samples
    ├── common
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

- `samples` contains two directories; `common` and `polymult`. The `common`
directory is used for sharing components (C sources, Makefile) which can be
reused throughout the repository. The `polymult` directory is used to contain
an initial implementation of cyclic convolution which can be used to multiply
two polynomials within the polynomial field
![(Z/q) [x] / (x^p - x - 1)](https://latex.codecogs.com/svg.latex?%28%5Cmathbb%7BZ%7D%2Fq%29%5C%20%5Bx%5D%5C%20%2F%5C%20%28x%5Ep%20-%20x%20-%201%29)
, i.e. ![R/q](https://latex.codecogs.com/svg.latex?%5Cmathcal%7BR%7D%2Fq).


