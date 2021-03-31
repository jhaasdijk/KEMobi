Some quick notes on using this directory.

* This directory contains everything related to NTT based polynomial
  multiplication (with or without Good's trick).


* Running all tests defined in `./tests` can be done by
  executing `python3 -m unittest discover -s tests`
  from the directory root. This works because `python3 -m unittest discover`
  will search a directory for any files named `test*.py` so as long as we stick
  to this naming convention we are fine. The `-s` flag is used to point the
  discovery to a specific directory, in this case `./tests`, where we keep all
  tests. `unittest` will then run all tests in a single run and write the output
  to `stdout`.


* It is important to run this command from the directory root as we are
  importing `common.py`. If we do not do this the tests will complain that there
  is no module named 'common'.

```bash
  ModuleNotFoundError: No module named 'common'
```