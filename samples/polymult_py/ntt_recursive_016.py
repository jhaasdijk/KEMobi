#!/usr/bin/env python3

"""
This script can be used to perform NTT based polynomial multiplication of
two polynomials within Z_16 [ ] / (x^11 - x - 1).

While 16 is not (an NTT friendly) prime and the reduction polynomial is not
of the form x^n + 1 or x^n - 1, we can use Good's permutation after padding
to size 24 to perform 3 size 8 NTTs instead. These smaller size - 8 cyclic
NTTs are used to multiply polynomials in Z_2833 [x] / (x^8 - 1).

Why 2833 you might ask. Since 16 does not provide us with the required roots
of unity we need a new modulus that does. The idea is to perform our
calculations in the integers instead and reduce back to 16 at the very end.
For this we need a new modulus (q') that is at least n * q * q = 2816 (larger
than the result could possibly be when multiplying our integer coefficients).
We can then do arithmetic with this new q' and ensure that the result is
correct in the integers, which we can then reduce mod q at the end to obtain
the final result.
"""

import random

from lib_common import Goods
from lib_common import NTT
from lib_common import pad
from lib_common import reduce_q

# Define the original and NTT 'suitable' parameters. The value of NEW_Q needs
# to be at least VAR_P * VAR_Q * VAR_Q = 2816, and provide us with the
# required roots of unity. The first prime for which the 8th (p1) roots of
# unity exist is 2833
VAR_Q, VAR_P, NEW_Q = 16, 11, 2833
P_0, P_1, P0P1 = 3, 8, 24

# These are the roots for a size - 8 cyclic NTT, i.e. we are multiplying
# polynomials in Z_2833 [x] / (x^8 - 1)
roots = [1, 1, 1357, 1, 1357, 450, 1555]
roots_inv = [1, 1, 1476, 1, 1476, 1278, 2383]

# Define objects to interact with the implemented Good's and NTT methods
goods = Goods(P_0, P_1, P0P1)
ntt = NTT(NEW_Q, P_1, roots, roots_inv)

# Generate two random polynomials A, B
A = [random.randint(0, VAR_Q - 1) for _ in range(VAR_P)]
B = [random.randint(0, VAR_Q - 1) for _ in range(VAR_P)]

"-- Zero pad polynomials A, B to size P0P1 "
A_PAD = pad(A, P0P1)
B_PAD = pad(B, P0P1)

" -- Perform Good's permutation to obtain P_0 size - P_1 polynomials each "
A_PAD_G = goods.forward(A_PAD)
B_PAD_G = goods.forward(B_PAD)

" -- Perform P_0 size - P_1 forward NTTs "
A_PAD_G_F = [ntt.forward_rec(A_PAD_G[_]) for _ in range(P_0)]
B_PAD_G_F = [ntt.forward_rec(B_PAD_G[_]) for _ in range(P_0)]

" -- Calculate 'point-wise' multiplication of the coefficients "
"""
Note that the 'smaller' polynomial multiplications are not 'normal', as we are
not actually computing the result 'point-wise'. Instead we multiply two degree 
2 polynomials and reduce the result mod (x^3 - 1). E.g.:

( [A[0][0], A[1][0], A[2][0]] * [B[0][0], B[1][0], B[2][0]] ) % (X^3 - 1)
= C[0][0], C[1][0], C[2][0]
"""

# Define variable for storing the result of the computation
C_PAD_G_F = [[0 for _ in range(P_1)] for _ in range(P_0)]

for i in range(P_1):

    # Define an accumulator to store temporary values
    accum = [0 for _ in range(2 * P_0 - 1)]

    # Obtain two degree 2 polynomials from A, B
    poly_a = [A_PAD_G_F[0][i], A_PAD_G_F[1][i], A_PAD_G_F[2][i]]
    poly_b = [B_PAD_G_F[0][i], B_PAD_G_F[1][i], B_PAD_G_F[2][i]]

    # Multiply the two polynomials naively
    for n in range(P_0):
        for m in range(P_0):
            accum[n + m] += poly_a[n] * poly_b[m]

    # Reduce mod (x^3 - 1)
    for ix in range(2 * P_0 - 2, P_0 - 1, -1):
        if accum[ix] > 0:  # x^p is nonzero
            accum[ix - P_0] += accum[ix]  # add x^p into x^0
            accum[ix] = 0  # zero x^p

    # Store the result
    C_PAD_G_F[0][i] = accum[0]
    C_PAD_G_F[1][i] = accum[1]
    C_PAD_G_F[2][i] = accum[2]

" -- Inverse the P_0 size - P_1 NTTs "
C_PAD_G = [ntt.inverse_rec(C_PAD_G_F[_]) for _ in range(P_0)]

" -- Undo Good's permutation "
C_PAD = goods.inverse(C_PAD_G)

" -- Reduce mod (x^11 - x - 1) "
for i in range(P0P1 - 1, VAR_P - 1, -1):
    if C_PAD[i] > 0:  # x^p is nonzero
        C_PAD[i - VAR_P + 1] += C_PAD[i]  # add x^p into x^1
        C_PAD[i - VAR_P] += C_PAD[i]  # add x^p into x^0
        C_PAD[i] = 0  # zero x^p

" -- Store the result "
C = reduce_q(C_PAD, VAR_Q)[:VAR_P]

# Print what is being calculated, we can check the result in Sage
print(f"Zx({A}) * Zx({B}) % (x^{VAR_P} - x - 1) % {VAR_Q} == Zx({C})")
