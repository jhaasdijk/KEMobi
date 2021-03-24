#!/usr/bin/env python3

import math

# FIXME :: Does not yet work as expected.

"""
This script can be used to perform NTT based polynomial multiplication of two
polynomials of size 11. Throughout this file we are multiplying A and B to 
produce C. Variable names are generally named after A,B,C using _<T> notation to
indicate their current format. The required steps are:

1. Pad polynomials A, B to size 24 (with zeros at the start)
2. Perform Good's permutation of A and B to obtain 3 size-8 polynomials each
3. Perform 3 size-8 forward NTTs
4. Calculate point-wise multiplication of the coefficients
5. Inverse the size-8 NTTs of the result
6. Undo Good's permutation
7. Reduce mod (x^11 - x - 1)
"""

# Define the original (P, Q) and NTT 'suitable' (P0, P1, P0P1) parameters
P, Q, P0, P1, P0P1 = 11, 17, 3, 8, 24

# We have polynomials A, B of size 11 (size P)
A = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
B = [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

# FIXME :: When multiplying in the smaller NTTs we need a new Q' != 17
#       :: This Q' needs to be at least (2 * P - 1) * (Q / 2) * 2
#       :: This requires a different roots and roots_inv

# roots when multiplying in Z_17 [x] / (x^8 - 1)
roots = [16, 4, 16, 2, 8, 4, 16]  # nth roots of unity
roots_inv = [16, 13, 16, 9, 15, 13, 16]  # inverse nth roots of unity

# 2^{-LAY} mod Q = 2^{-3} mod 17 = 8^{-1} mod 17 = 15
LAY = int(math.log2(P1))  # needs explicit conversion to integer
LAY_INV = pow(2, -LAY, Q)  # this only works in Python3.8+


# FIXME :: When reducing in the smaller NTTs we need to reduce mod Q'
#       :: When reducing outside of the NTTs we need to reduce mod Q
def reduce_q(cvec):
    """ Reduction of all integer coefficients mod Q """
    return list(map(lambda x: x % Q, cvec))


def forward(cvec, ridx=0):
    """
    Calculate forward NTT of a polynomial represented by its coefficient vector
    :param cvec: Polynomial represented by its coefficient vector
    :param ridx: Index used to point to the root of unity, default 0
    :return: The forward NTT transform (of the left and right halves)
    """
    if len(cvec) == 1:
        return cvec
    else:
        half = math.floor(len(cvec) / 2)
        cvec_l, cvec_r = [0] * half, [0] * half

        for idx in range(half):
            cvec_l[idx] = cvec[idx] + roots[ridx] * cvec[idx + half]
            cvec_r[idx] = cvec[idx] - roots[ridx] * cvec[idx + half]

        cvec_l = reduce_q(cvec_l)
        cvec_r = reduce_q(cvec_r)

        return forward(cvec_l, ridx * 2 + 1) + forward(cvec_r, ridx * 2 + 2)


def invert(cvec, ridx=0):
    """
    Calculate inverse NTT of a polynomial represented by its coefficient vector
    :param cvec: Polynomial represented by its coefficient vector
    :param ridx: Index used to point to the inverse root of unity, default 0
    :return: The inverse NTT transform
    """
    if len(cvec) == 1:
        return cvec
    else:
        half = math.floor(len(cvec) / 2)
        cvec_l = invert(cvec[:half], ridx * 2 + 1)
        cvec_r = invert(cvec[half:], ridx * 2 + 2)

        rvec = [0] * P1  # storing the result, we do not overwrite cvec
        for idx in range(half):
            rvec[idx] = cvec_l[idx] + cvec_r[idx]
            rvec[idx + half] = (cvec_l[idx] - cvec_r[idx]) * roots_inv[ridx]

        return rvec


# Zero pad polynomials A, B to size 24
A_PAD = A + [0] * (P0P1 - len(A))
B_PAD = B + [0] * (P0P1 - len(B))

# Perform Good's permutation to obtain 3 size-8 polynomials each
A_PAD_G = [[0] * P1, [0] * P1, [0] * P1]
B_PAD_G = [[0] * P1, [0] * P1, [0] * P1]

for i in range(P0P1):
    lane = i % P0  # determines in which NTT 'lane' the coefficient ends up
    coef = i % P1  # determines which 'lane' coefficient is used
    A_PAD_G[lane][coef] = A_PAD[i]
    B_PAD_G[lane][coef] = B_PAD[i]

# Perform 3 size-8 forward NTTs each
A_PAD_G_F = [forward(A_PAD_G[0]), forward(A_PAD_G[1]), forward(A_PAD_G[2])]
B_PAD_G_F = [forward(B_PAD_G[0]), forward(B_PAD_G[1]), forward(B_PAD_G[2])]

# FIXME :: What kind of multiplication are we doing exactly?
#       :: Why are the 'smaller' polynomial multiplications not 'normal' ?

# Perform the point-wise multiplication of the coefficients
C_PAD_G_F = [[0] * P1, [0] * P1, [0] * P1]

# option 1 : c[0][0] = a[0][0]*b[0][0] + a[0][0]*b[1][0] + a[0][0]*b[2][0]
for i in range(P0):
    for j in range(P1):
        for k in range(P0):
            C_PAD_G_F[i][j] += A_PAD_G_F[i][j] * B_PAD_G_F[k][j]

# option 2 : c[0][0] = a[0][0]*b[0][0]
# for i in range(P0):
#     # CPAD_G_F[i] = [(a * b) % Q for a, b in zip(APAD_G_F[i], BPAD_G_F[i])]
#     CPAD_G_F[i] = [(a * b) for a, b in zip(APAD_G_F[i], BPAD_G_F[i])]

# Inverse the size-8 NTTs
C_PAD_G = [invert(C_PAD_G_F[0]), invert(C_PAD_G_F[1]), invert(C_PAD_G_F[2])]
for i in range(P0):
    # CPAD_G[i] = list(map(lambda x: (x * INVLAY) % Q, CPAD_G[i]))
    C_PAD_G[i] = list(map(lambda x: (x * LAY_INV), C_PAD_G[i]))

# Undo Good's permutation
C_PAD = [0] * P0P1
for i in range(P0P1):
    lane = i % P0  # determines in which NTT 'lane' the coefficient ends up
    coef = i % P1  # determines which 'lane' coefficient is used
    C_PAD[i] = C_PAD_G[lane][coef]

# Reduce all integer coefficients mod Q
C_PAD = reduce_q(C_PAD)

# Reduce mod (x^11 - x - 1)
for i in range(P0P1 - 1, P - 1, -1):
    if C_PAD[i] > 0:  # x^p is nonzero
        C_PAD[i - (P - 1)] += C_PAD[i]  # add x^p into x^1
        C_PAD[i - P] += C_PAD[i]  # add x^p into x^0
        C_PAD[i] = 0  # zero x^p

C = reduce_q(C_PAD)[:P]

# Printing intermediate values
print(f"A:         {A}")
print(f"B:         {B}")
print(f"A_PAD:     {A_PAD}")
print(f"B_PAD:     {B_PAD}")
print(f"A_PAD_G:   {A_PAD_G}")
print(f"B_PAD_G:   {B_PAD_G}")
print(f"A_PAD_G_F: {A_PAD_G_F}")
print(f"B_PAD_G_F: {B_PAD_G_F}")
print(f"C_PAD_G_F: {C_PAD_G_F}")
print(f"C_PAD_G:   {C_PAD_G}")
print(f"C_PAD:     {C_PAD}")
print(f"C:         {C}")
