# KEMobi

**Jasper Haasdijk**, February 2021.

This repository contains the source code for my Master Thesis Computing Science
at the Digital Security Group, Radboud University, Nijmegen, The Netherlands.

The directory structure currently looks like this:

```
$ tree -dL 1

.
├── enableccnt
└── ntruprime-20201007

2 directories
```

`enableccnt` contains the source for setting up a kernel module to enable
user space access to the `PMCCNTR_EL0` System register. This allows us to
read the `PMCCNTR_EL0` register which holds the value of the processor cycle
counter.

`ntruprime-20201007` contains the NTRU Prime software and supporting
documentation. The `nistpqc` branch contains the original NTRU Prime NISTPQC
full submission package, last updated 7 October 2020.