#!/usr/bin/env python3

from lib_common import Goods
from lib_common import NTT
from lib_common import pad
from lib_common import reduce_q

"""
This script can be used to perform NTT based polynomial multiplication of two
polynomials of size 11. While 11 is not necessarily an NTT friendly parameter,
we can use Good's permutation after padding to size - 24 to perform 3 size - 
8 NTTs instead. Throughout this file we are multiplying A and B to produce C.
Variable names are generally named after A,B,C using _<T> notation to
indicate their current format. The main steps of the algorithm have been 
highlighted using " -- " comments
"""

# Define the original (p, q) and NTT 'suitable' (p0, p1, p0p1) parameters
VAR_Q, VAR_P = 17, 11
p0, p1, p0p1 = 3, 8, 24

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

# These are the roots for a size - 8 cyclic NTT, i.e. we are multiplying
# polynomials in Z_17 [x] / (x^8 - 1)
roots = [1, 1, 4, 1, 4, 2, 8]
roots_inv = [1, 1, 13, 1, 13, 9, 15]

# Setup Good's and NTT parameters
goods = Goods(p0, p1, p0p1)
ntt = NTT(VAR_Q, p1, roots, roots_inv)

" -- Define polynomials A, B of size p "
A = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
B = [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

" -- Zero pad polynomials A, B to size p0p1 "
A_PAD = pad(A, p0p1)
B_PAD = pad(B, p0p1)

" -- Perform Good's permutation to obtain p0 size-p1 polynomials each "
A_PAD_G = goods.forward(A_PAD)
B_PAD_G = goods.forward(B_PAD)

" -- Perform p0 size - p1 forward NTTs "
A_PAD_G_F = [ntt.forward_rec(A_PAD_G[_]) for _ in range(p0)]
B_PAD_G_F = [ntt.forward_rec(B_PAD_G[_]) for _ in range(p0)]

" -- Calculate 'point-wise' multiplication of the coefficients "
"""
Note that the 'smaller' polynomial multiplications are not 'normal', as we are
not actually computing the result 'point-wise'. Instead we multiply two degree 
2 polynomials and reduce the result mod (x^3 - 1). E.g.:

( [A[0][0], A[1][0], A[2][0]] * [B[0][0], B[1][0], B[2][0]] ) % (X^3 - 1)
= C[0][0], C[1][0], C[2][0]
"""

# TODO : Move 'naive' multiplication into lib_common as this can then be
#  reused at other places in the directory

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
    accum = reduce_q(accum, VAR_Q)
    C_PAD_G_F[0][i] = accum[0]
    C_PAD_G_F[1][i] = accum[1]
    C_PAD_G_F[2][i] = accum[2]

" -- Inverse the size-8 NTTs "
C_PAD_G = [ntt.inverse_rec(C_PAD_G_F[_]) for _ in range(p0)]

" -- Undo Good's permutation "
C_PAD = goods.inverse(C_PAD_G)

" -- Reduce mod (x^11 - x - 1) "
for i in range(p0p1 - 1, VAR_P - 1, -1):
    if C_PAD[i] > 0:  # x^p is nonzero
        C_PAD[i - VAR_P + 1] += C_PAD[i]  # add x^p into x^1
        C_PAD[i - VAR_P] += C_PAD[i]  # add x^p into x^0
        C_PAD[i] = 0  # zero x^p

" -- Store the result "
C = reduce_q(C_PAD, VAR_Q)[:VAR_P]

# 7x^10 + 7x^9 + 10x^8 + 15x^7 + 4x^6 + 10x^5 + 15x^4 + x^3 + x^2 + 14x + 9
print(f"Calculating : Zx({A}) * Zx({B}) % (x^11 - x - 1) % 17")
print(f"Produces    : {C}")
print(f"The result is {C == [9, 14, 1, 1, 15, 10, 4, 15, 10, 7, 7]}")
