# Number Theoretic Transform (NTT)

This directory contains the **C** sources for performing NTT based polynomial
multiplication. It contains a complete implementation with which you can compare
and review how NTT based polynomial multiplication works, in C. Please refer to
the specific function or value for more details. Every function and constant
value has been documented extensively.

Please note that this directory has been optimized for **readability**, not for
speed. While we could certainly de-generalize some functions and hardcode
certain values, I feel like the current implementation strikes a nice balance
between clarity and speed for a future reader to learn from.

It's important to be aware that this directory (the `ntt_iterative_761` example
in particular) is basically an older version of the **ntrulpr761** directory. If
something seems to be outdated or buggy it might be worth verifying this with
the updated sources first.
