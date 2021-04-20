import math
from typing import List
from typing import NoReturn

from common import NTT

"""
This script is for testing the forward and inverse NTT transformation. 
Depending on whether its a cyclic or negacyclic NTT the roots need to change.
"""

# Define type alias for coefficient vectors
Vector = List[int]

# We are calculating inplace so we need to make a copy if we somewhere want to
# do something with the original coefficient vector
A = [2, 0, 0, 7, 2, 0, 0, 7]
B = [6, 0, 2, 0, 6, 0, 2, 0]
original_A = A.copy()
original_B = B.copy()

# Define the global parameters
Q, N = 17, 8

# TODO : Uncomment this for a cyclic NTT
#      : Use roots_cyclic.sage to calculate new values
# For a size-8 cyclic NTT, i.e. multiplying in Z_17 [x] / (x^8 - 1):
# roots = [16, 4, 16, 2, 8, 4, 16]  # roots of unity
# roots_inv = [pow(_, -1, Q) for _ in roots]  # inverse roots of unity
# TODO : These roots have been generated
# roots=[1, 1, 4, 1, 4, 2, 8]
# roots_inv=[1, 1, 13, 1, 13, 9, 15]

# TODO : Uncomment this for a negacyclic NTT
#      : Use roots_negacyclic.sage to calculate new values
# For a size-8 negacyclic NTT, i.e. multiplying in Z_17 [x] / (x^8 + 1):
# roots = [4, 2, 8, 6, 10, 5, 3]  # roots of unity
# roots_inv = [13, 9, 15, 3, 12, 7, 6]  # inverse roots of unity
# TODO : These roots have been generated
roots = [13, 9, 15, 3, 5, 10, 11]
roots_inv = [4, 2, 8, 6, 7, 12, 14]


def reduce_q(cvec: Vector, q: int) -> Vector:
    """
    Reduce the integer coefficients of a coefficient vector with a modulus
    :param cvec: The coefficient vector
    :param q: The modulus
    :return: Coefficient vector with coefficients mod q
    """
    return list(map(lambda x: x % q, cvec))


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
These should be applied synchronous to the forward functions. For example 
forward 1, forward 2, forward 3, should be matched with inverse 3, inverse 2,
inverse 1. The result is then to be multiplied with the accumulated 2^-l factor
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


def forward(cvec):
    forward_layer_1(cvec, 0)
    forward_layer_2(cvec, 1)
    forward_layer_3(cvec, 3)
    return reduce_q(cvec, Q)


def inverse(cvec):
    inverse_layer_3(cvec, 3)
    inverse_layer_2(cvec, 1)
    inverse_layer_1(cvec, 0)

    # Calculate the accumulated constant factor: 2^{-lay} mod Q
    # Multiply with this factor and reduce mod Q to obtain the inverse
    lay = int(math.log2(N))  # needs explicit conversion to integer
    factor = pow(2, -lay, Q)  # this only works in Python3.8+
    return [(_ * factor) % Q for _ in cvec]


# Forward NTT transform of A
forward_A = forward(A)
# Forward NTT transform of B
forward_B = forward(B)

# Some debug printing for testing some known values
print("> Forward NTT transformation of A")
print(f"{original_A = }")
print(f"{forward_A  = }")

ntt = NTT(Q, N, roots, roots_inv)
if forward_A == ntt.forward(original_A):
    print("> This is \\ identical \\ to the recursive variant")
else:
    print("> This is \\ different \\ from the recursive variant")

if forward_A == [0, 0, 0, 0, 16, 9, 7, 1]:
    print("> This is the expected result for a size-8 \\ cyclic \\ NTT")
elif forward_A == [5, 15, 7, 13, 4, 1, 5, 0]:
    print("> This is the expected result for a size-8 \\ negacyclic \\ NTT")
else:
    print("> This result was \\ unexpected \\ for the predefined roots")
    print("> Did you perhaps try different roots?")

# Multiplying the elements of A and B into C
forward_C = [(a * b) % Q for a, b in zip(forward_A, forward_B)]

# Testing that the NTT symmetry holds
inverse_A = inverse(forward_A)
print()
print("> Testing symmetry")
print("> Inverse NTT transformation")
print(f"{inverse_A  = }")
print(f"{inverse_A == original_A = }")

# Calculating inverse NTT transform of forward_C
inverse_C = inverse(forward_C)
print()
print("> Multiplying A and B in Z_17 [x] / (x^8 +- 1)")
print(f"Zx({original_A}) * Zx({original_B}) % (x^8 +- 1) % 17")
print(f"Produces {inverse_C = }")

if inverse_C == [7, 11, 8, 16, 7, 11, 8, 16]:
    print("> This is the expected result for a size-8 \\ cyclic \\ NTT")
elif inverse_C == [0, 6, 0, 0, 7, 0, 8, 16]:
    print("> This is the expected result for a size-8 \\ negacyclic \\ NTT")
else:
    print("> This result was \\ unexpected \\")
