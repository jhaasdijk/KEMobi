# Number Theoretic Transform (NTT)

This directory contains the **Python** sources for performing NTT based
polynomial multiplication. It contains a complete implementation with which you
can compare and review how NTT based polynomial multiplication works. Please
refer to the specific class or function for more details. Every class and
function has been documented with an extensive docstring and annotated with type
hints as much as possible.

File are prepended with either `lib_`, `ntt_` or `test_` referring to their
supposed use.

* Files prepended with `lib_` contain helper classes and functions which can be
  reused and called from other scripts.

* Files prepended with `ntt_` implement examples, either recursively or
  iteratively, with differing sizes, with or without applying Good's trick.

* Files prepended with `test_` implement unit tests. They can be found in the
  `./tests` directory.

## Testing

Running all tests defined in `./tests` can be done by executing `python3 -m
unittest discover -s tests` from the directory root. This works because `python3
-m unittest discover` will search a directory for any files named `test*.py` so
as long as we stick to this naming convention we are fine. The `-s` flag is used
to point the discovery to a specific directory, in this case `./tests`, where we
keep all tests. `unittest` will then run all tests in a single run and write the
output to `stdout`.

It is important to run this command from the directory root as the tests import
functionality from `lib_common.py`. If we do not do this the tests will complain
that there is no module named 'lib_common'.

```bash
  ModuleNotFoundError: No module named 'lib_common'
```

## TODO

- [ ] It would be cleaner to package the Python sources in this directory as a
  standalone module. We could then improve readability by moving the sources
  into three separate folders (`lib`, `tests` and `ntt`).

- [ ] It would be better to move some of the `ntt_` examples as a test under
  `./tests` and only keep the ones that showcase a different approach in `ntt_`.
  This would greatly de-clutter the repository while simultaneously improving
  its reliability.

