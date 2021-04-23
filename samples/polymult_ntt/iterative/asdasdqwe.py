import math
from typing import List
from typing import NoReturn

from common import NTT
from common import reduce_q

"""
This script can be used to test the forward and inverse NTT transformation. 
The (inverse) NTT transformation has been separated per layer which makes it 
very easy to inspect and debug intermediate results.
"""

# Define type alias for coefficient vectors
Vector = List[int]

# We are calculating inplace so we need to make a copy if we somewhere want to
# do something with the original coefficient vectors
A = [2, 0, 0, 7, 2, 0, 0, 7]
B = [6, 0, 2, 0, 6, 0, 2, 0]
original_A = A.copy()
original_B = B.copy()

# Define the NTT parameters
Q, N = 17, 8

# These are the roots for a size-8 cyclic NTT, i.e. we are multiplying
# polynomials A and B in Z_17 [x] / (x^8 - 1). Remember that the inverse
# roots have been reordered
roots = [1, 1, 4, 1, 4, 2, 8]
roots_inv = [1, 13, 9, 15, 1, 13, 1]

# TODO include the actual roots

# TODO This file contains the only example with separated layers. Create a
#  special example from this in ../


"""
The following three functions define the per-layer forward NTT transform.
"""


def forward_layer_1(cvec: Vector, k: int) -> NoReturn:
    length = 4
    idx, zeta = 0, roots[k]

    for idx in range(length):
        temp = zeta * cvec[idx + length]
        cvec[idx + length] = cvec[idx] - temp  # The right halve
        cvec[idx] = cvec[idx] + temp  # The left halve


def forward_layer_2(cvec: Vector, k: int) -> NoReturn:
    length, start = 2, 0

    while start < N:
        idx, zeta, k = start, roots[k], k + 1

        while idx < (start + length):
            temp = zeta * cvec[idx + length]
            cvec[idx + length] = cvec[idx] - temp  # The right halve
            cvec[idx] = cvec[idx] + temp  # The left halve

            idx += 1

        start = idx + length


def forward_layer_3(cvec: Vector, k: int) -> NoReturn:
    length, start = 1, 0

    while start < N:
        idx, zeta, k = start, roots[k], k + 1

        while idx < (start + length):
            temp = zeta * cvec[idx + length]
            cvec[idx + length] = cvec[idx] - temp  # The right halve
            cvec[idx] = cvec[idx] + temp  # The left halve

            idx += 1

        start = idx + length


"""
The following three functions define the per-layer inverse NTT transform. 
These should be applied asymmetrical to the forward functions. For example 
forward 1, forward 2, forward 3, should be matched with inverse 3, inverse 2,
inverse 1. The final layer includes the multiplication with the accumulated 
2^-l factor
"""


def inverse_layer_3(cvec: Vector, k: int) -> NoReturn:
    length, start = 1, 0

    while start < N:
        idx, zeta, k = start, roots_inv[k], k + 1

        while idx < (start + length):
            temp = cvec[idx]
            cvec[idx] = (temp + cvec[idx + length])
            cvec[idx + length] = temp - cvec[idx + length]
            cvec[idx + length] *= zeta

            idx += 1

        start = idx + length


def inverse_layer_2(cvec: Vector, k: int) -> NoReturn:
    length, start = 2, 0

    while start < N:
        idx, zeta, k = start, roots_inv[k], k + 1

        while idx < (start + length):
            temp = cvec[idx]
            cvec[idx] = (temp + cvec[idx + length])
            cvec[idx + length] = temp - cvec[idx + length]
            cvec[idx + length] *= zeta

            idx += 1

        start = idx + length


def inverse_layer_1(cvec: Vector, k: int) -> NoReturn:
    length = 4
    idx, zeta = 0, roots_inv[k]

    for idx in range(length):
        temp = cvec[idx]
        cvec[idx] = (temp + cvec[idx + length])
        cvec[idx + length] = temp - cvec[idx + length]
        cvec[idx + length] *= zeta

        idx += 1

    # Calculate the accumulated constant factor: 2^{-lay} mod Q
    # Multiply with this factor and reduce mod Q to obtain the inverse
    lay = int(math.log2(N))  # needs explicit conversion to integer
    factor = pow(2, -lay, Q)  # this only works in Python3.8+

    for _ in range(N):
        cvec[_] = (cvec[_] * factor) % Q


# Calculate the forward NTT transform of A
forward_layer_1(A, 0)
forward_layer_2(A, 1)
forward_layer_3(A, 3)
A = reduce_q(A, Q)

# Calculate the forward NTT transform of B
forward_layer_1(B, 0)
forward_layer_2(B, 1)
forward_layer_3(B, 3)
B = reduce_q(B, Q)

ntt = NTT(Q, N, roots, roots_inv)
if A == ntt.forward_rec(original_A):
    print("> This is \\ identical \\ to the recursive variant")
else:
    print("> This is \\ different \\ from the recursive variant")

if A == [0, 0, 0, 0, 16, 9, 7, 1]:
    print("> This is the expected result for a size-8 \\ cyclic \\ NTT")
elif A == [5, 15, 7, 13, 4, 1, 5, 0]:
    print("> This is the expected result for a size-8 \\ negacyclic \\ NTT")
else:
    print("> This result was \\ unexpected \\ for the predefined roots")
    print("> Did you perhaps try different roots?")

# Multiplying the elements of A and B into C
C = [(a * b) % Q for a, b in zip(A, B)]

# Calculate the inverse NTT transform of C
inverse_layer_3(C, 0)
inverse_layer_2(C, 1)
inverse_layer_1(C, 3)

print()
print("> Multiplying A and B in Z_17 [x] / (x^8 - 1)")
print(f"Zx({original_A}) * Zx({original_B}) % (x^8 +- 1) % 17")
print(f"Produces {C = }")

if C == [7, 11, 8, 16, 7, 11, 8, 16]:
    print("> This is the expected result for a size-8 \\ cyclic \\ NTT")
elif C == [0, 6, 0, 0, 7, 0, 8, 16]:
    print("> This is the expected result for a size-8 \\ negacyclic \\ NTT")
else:
    print("> This result was \\ unexpected \\")
