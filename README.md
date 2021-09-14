# KEMobi

**Jasper Haasdijk**, September 2021.

This repository contains the source code for my Master Thesis Computing Science
at the Digital Security Group, Radboud University, Nijmegen, The Netherlands.

The directory structure currently looks like this:

```
$ tree -dL 1

.
├── crypto_kem
├── enableccnt
├── mk
└── samples

4 directories
```

- `crypto_kem` contains both the reference and our optimized NTRU Prime software
implementation (`ntrulpr761`). This has been taken and modified from the
original NTRU Prime NISTPQC full submission package, last updated 7 October
2020, which is made available through their
[webpage](https://ntruprime.cr.yp.to/).

- `enableccnt` contains the source code for setting up a kernel module to enable
user space access to the `PMCCNTR_EL0` System register. This allows us to read
the `PMCCNTR_EL0` system register which holds the value of the processor cycle
counter.

- `mk` contains shared Makefile components which can be reused throughout the
repository.

- `samples` contains various directories that change every now and again. Its
main use is to provide a structured space for prototyping and developing sources
related to this thesis. Please refer to the directory specific documentation for
more information. Keep in mind however, _"Here be dragons"_.

## Installation

The software has been tested with the following platform, package and version
information.

```
uname -srom         Linux 5.10.60-v8+ aarch64 GNU/Linux
make --version      GNU Make 4.2.1
gcc --version       gcc (Debian 8.3.0-6) 8.3.0
```

## Disclaimer

This repository contains unreviewed software. Therefore its security cannot be
relied upon. Please use at your own risk.
