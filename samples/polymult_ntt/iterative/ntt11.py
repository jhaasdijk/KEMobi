#!/usr/bin/env python3

import math
from typing import List
from typing import NoReturn

from common import Goods
from common import NTT
from common import pad
from common import reduce_q

# Define type alias for coefficient vectors
Vector = List[int]

"""
This script can be used to perform NTT based polynomial multiplication of two
polynomials of size 11. Throughout this file we are multiplying A and B to 
produce C. Variable names are generally named after A,B,C using _<T> notation to
indicate their current format. The main steps of the algorithm have been 
highlighted using " -- " comments
"""

# Define the original (p, q) and NTT 'suitable' (p0, p1, p0p1) parameters
p, q = 11, 17
p0, p1, p0p1 = 3, 8, 24
Q, N = 17, 8

# FIXED :: When multiplying in the smaller NTTs we need a new Q' != 17
#       :: This Q' needs to be at least (2 * P - 1) * (Q / 2) * 2
#       :: How do we determine this Q' ?
#       :: This requires different roots and roots_inv
#
# When multiplying in the smaller NTTs we DO NOT need a new Q' per se. We
# only need a new Q' when our original Q does not provide us with the roots
# of unity. Since Q = 17 DOES provide us with the required roots, there is no
# need to construct a new Q'.

# FIXED :: Are we reducing mod (x^8 - 1) or mod (x^8 + 1) in the smaller NTTs?
#       :: This changes what roots of unity we are multiplying with
#
# We are reducing mod (x^8 - 1)

# Roots when multiplying in Z_17 [x] / (x^8 - 1)
# roots = [16, 4, 16, 2, 8, 4, 16]  # roots of unity
# roots_inv = [pow(_, -1, q) for _ in roots]  # inverse roots of unity

roots = [1, 1, 4, 1, 4, 2, 8]
roots_inv = [1, 1, 13, 1, 13, 9, 15]

# Setup Good's and NTT parameters
goods = Goods(p0, p1, p0p1)
ntt = NTT(q, p1, roots, roots_inv)

" ------------------------------ "


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


" ------------------------------ "

" -- Define polynomials A, B of size p "
A = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
B = [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

" -- Zero pad polynomials A, B to size p0p1 "
A_PAD = pad(A, p0p1)
B_PAD = pad(B, p0p1)

" -- Perform Good's permutation to obtain p0 size-p1 polynomials each "
A_PAD_G = goods.forward(A_PAD)
B_PAD_G = goods.forward(B_PAD)

" -- Perform p0 size-p1 forward NTTs "
A_PAD_G_F = [
    forward(A_PAD_G[0]),
    forward(A_PAD_G[1]),
    forward(A_PAD_G[2])
]
B_PAD_G_F = [
    forward(B_PAD_G[0]),
    forward(B_PAD_G[1]),
    forward(B_PAD_G[2])
]

" -- Calculate 'point-wise' multiplication of the coefficients "
"""
Note that the 'smaller' polynomial multiplications are not 'normal', as we are
not actually computing the result 'point-wise'. Instead we multiply two degree 
2 polynomials and reduce the result mod (x^3 - 1). E.g.:

( [A[0][0], A[1][0], A[2][0]] * [B[0][0], B[1][0], B[2][0]] ) % (X^3 - 1)
= C[0][0], C[1][0], C[2][0]
"""

# define variable for storing the result of the computation
C_PAD_G_F = [[0 for _ in range(p1)] for _ in range(p0)]

for i in range(p1):

    # define an accumulator to store temporary values
    accum = [0 for _ in range(2 * p0)]

    # obtain two degree 2 polynomials from A, B
    poly_a = [A_PAD_G_F[0][i], A_PAD_G_F[1][i], A_PAD_G_F[2][i]]
    poly_b = [B_PAD_G_F[0][i], B_PAD_G_F[1][i], B_PAD_G_F[2][i]]

    # multiply the two polynomials naively
    for n in range(p0):
        for m in range(p0):
            accum[n + m] += poly_a[n] * poly_b[m]

    # reduce mod (x^3 - 1)
    for ix in range(2 * p0 - 1, p0 - 1, -1):
        if accum[ix] > 0:  # x^p is nonzero
            accum[ix - p0] += accum[ix]  # add x^p into x^0
            accum[ix] = 0  # zero x^p

    # store the result
    accum = reduce_q(accum, q)
    C_PAD_G_F[0][i] = accum[0]
    C_PAD_G_F[1][i] = accum[1]
    C_PAD_G_F[2][i] = accum[2]

" -- Inverse the size-8 NTTs "
C_PAD_G = [
    inverse(C_PAD_G_F[0]),
    inverse(C_PAD_G_F[1]),
    inverse(C_PAD_G_F[2])
]

" -- Undo Good's permutation "
C_PAD = goods.inverse(C_PAD_G)

" -- Reduce mod (x^11 - x - 1) "
for i in range(p0p1 - 1, p - 1, -1):
    if C_PAD[i] > 0:  # x^p is nonzero
        C_PAD[i - p + 1] += C_PAD[i]  # add x^p into x^1
        C_PAD[i - p] += C_PAD[i]  # add x^p into x^0
        C_PAD[i] = 0  # zero x^p

" -- Store the result "
C = reduce_q(C_PAD, q)[:p]

# 7x^10 + 7x^9 + 10x^8 + 15x^7 + 4x^6 + 10x^5 + 15x^4 + x^3 + x^2 + 14x + 9
print(f"Calculating : Zx({A}) * Zx({B}) % (x^11 - x - 1) % 17")
print(f"Produces    : {C}")
print(f"The result is {C == [9, 14, 1, 1, 15, 10, 4, 15, 10, 7, 7]}")
