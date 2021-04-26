#!/usr/bin/env python3

import math
from typing import List
from typing import NoReturn

"""
This script can be used to test the forward and inverse iterative NTT 
transformation. The (inverse) NTT transformation has been separated per layer
which makes it very easy to inspect and debug intermediate results.
"""

# Define type alias for coefficient vectors
Vector = List[int]

# Define the NTT parameters
VAR_Q, VAR_P = 17, 8

# These are the roots for a size-8 cyclic NTT, i.e. we are multiplying
# polynomials A and B in Z_17 [x] / (x^8 - 1). Remember that the inverse
# roots have been reordered
roots = [1, 1, 4, 1, 4, 2, 8]
roots_inv = [1, 13, 9, 15, 1, 13, 1]

# We are calculating inplace so we need to make a copy if we somewhere want to
# do something with the original coefficient vectors
A = [2, 0, 0, 7, 2, 0, 0, 7]
B = [6, 0, 2, 0, 6, 0, 2, 0]
original_A = A.copy()
original_B = B.copy()

"""
The following three functions define the per-layer forward NTT transform.
The final layer includes a reduction of the coefficients mod VAR_Q
"""


def forward_layer_1(cvec: Vector, ridx: int) -> NoReturn:
    length = 4
    zeta = roots[ridx]

    for _ in range(length):
        temp = zeta * cvec[_ + length]
        cvec[_ + length] = cvec[_] - temp  # The right halve
        cvec[_] = cvec[_] + temp  # The left halve


def forward_layer_2(cvec: Vector, ridx: int) -> NoReturn:
    length, start = 2, 0

    while start < VAR_P:
        zeta, ridx = roots[ridx], ridx + 1

        for _ in range(start, start + length):
            temp = zeta * cvec[_ + length]
            cvec[_ + length] = cvec[_] - temp  # The right halve
            cvec[_] = cvec[_] + temp  # The left halve

        start += 2 * length


def forward_layer_3(cvec: Vector, ridx: int) -> NoReturn:
    length, start = 1, 0

    while start < VAR_P:
        zeta, ridx = roots[ridx], ridx + 1

        for _ in range(start, start + length):
            temp = zeta * cvec[_ + length]
            cvec[_ + length] = cvec[_] - temp  # The right halve
            cvec[_] = cvec[_] + temp  # The left halve

        start += 2 * length

    # Reduce the coefficients inplace
    cvec[:] = [_ % VAR_Q for _ in cvec]


"""
The following three functions define the per-layer inverse NTT transform. 
These should be applied asymmetrical to the forward functions. For example 
forward 1, forward 2, forward 3, should be matched with inverse 3, inverse 2,
inverse 1. The final layer includes the multiplication with the accumulated 
2^-l factor
"""


def inverse_layer_3(cvec: Vector, ridx: int) -> NoReturn:
    length, start = 1, 0

    while start < VAR_P:
        zeta, ridx = roots_inv[ridx], ridx + 1

        for _ in range(start, start + length):
            temp = cvec[_]
            cvec[_] = (temp + cvec[_ + length])
            cvec[_ + length] = temp - cvec[_ + length]
            cvec[_ + length] *= zeta

        start += 2 * length


def inverse_layer_2(cvec: Vector, ridx: int) -> NoReturn:
    length, start = 2, 0

    while start < VAR_P:
        zeta, ridx = roots_inv[ridx], ridx + 1

        for _ in range(start, start + length):
            temp = cvec[_]
            cvec[_] = (temp + cvec[_ + length])
            cvec[_ + length] = temp - cvec[_ + length]
            cvec[_ + length] *= zeta

        start += 2 * length


def inverse_layer_1(cvec: Vector, ridx: int) -> NoReturn:
    length = 4
    zeta = roots_inv[ridx]

    for _ in range(length):
        temp = cvec[_]
        cvec[_] = (temp + cvec[_ + length])
        cvec[_ + length] = temp - cvec[_ + length]
        cvec[_ + length] *= zeta

    # Calculate the accumulated constant factor: 2^{-lay} mod q
    # Multiply with this factor and reduce mod q to obtain the result
    lay = int(math.log2(VAR_P))  # Needs explicit conversion to integer
    factor = pow(2, -lay, VAR_Q)  # This only works in Python3.8+
    cvec[:] = [(_ * factor) % VAR_Q for _ in cvec]


# Calculate the forward NTT transform of A
forward_layer_1(A, 0)
forward_layer_2(A, 1)
forward_layer_3(A, 3)

# Calculate the forward NTT transform of B
forward_layer_1(B, 0)
forward_layer_2(B, 1)
forward_layer_3(B, 3)

# Multiplying the elements of A and B into C
C = [(a * b) % VAR_Q for a, b in zip(A, B)]

# Calculate the inverse NTT transform of C
inverse_layer_3(C, 0)
inverse_layer_2(C, 4)
inverse_layer_1(C, 6)

# Print and compare the result
print("Multiplying A and B in Z_17 [x] / (x^8 - 1) produces:")
print(f"{C = }")

if C == [7, 11, 8, 16, 7, 11, 8, 16]:
    print("This is the expected result for a size-8 cyclic NTT")
else:
    print("This result was \\ unexpected \\")
