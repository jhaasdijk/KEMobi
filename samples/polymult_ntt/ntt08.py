#!/usr/bin/env python3

import math

"""
This script can be used for multiplying two polynomials using NTT based
multiplication. We are multiplying in the ring R_q = Z_17 [x] / (x^8 + 1). This
means that we have two polynomials with integer coefficients from {0, 1, ...,
16}. The polynomials are reduced mod (x^8 + 1), i.e. x^8 = -1.
"""

PRIMEP = 8
PRIMEQ = 17

# 2^{-LAY} mod PRIMEQ = 2^{-3} mod 17 = 8^{-1} mod 17 = 15
LAY = int(math.log2(PRIMEP))  # needs explicit conversion to integer
INVLAY = pow(2, -LAY, PRIMEQ)  # this only works in Python3.8+

poly_a = [2, 0, 0, 7, 2, 0, 0, 7]  # 2 + 7x^3 + 2x^4 + 7x^7
poly_b = [6, 0, 2, 0, 6, 0, 2, 0]  # 6 + 2x^2 + 6x^4 + 2x^6

roots = [4, 2, 8, 6, 10, 5, 3]  # nth roots of unity
roots_inv = [13, 9, 15, 3, 12, 7, 6]  # inverse nth roots of unity


def reduce(cvec):
    """ Reduction of all integer coefficients mod PRIMEQ """
    return list(map(lambda x: x % PRIMEQ, cvec))


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

        cvec_l = reduce(cvec_l)
        cvec_r = reduce(cvec_r)

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

        rvec = [0] * PRIMEP  # storing the result, we do not overwrite cvec
        for idx in range(half):
            rvec[idx] = cvec_l[idx] + cvec_r[idx]
            rvec[idx + half] = (cvec_l[idx] - cvec_r[idx]) * roots_inv[ridx]

        return rvec


# Calculate the forward NTT of polynomials fa, fb
fa = forward(poly_a)
fb = forward(poly_b)

# Calculate the point-wise multiplication of fa, fb
# The integer coefficients are reduced Z_q
fc = [(a * b) % PRIMEQ for a, b in zip(fa, fb)]

# Calculate the inverse NTT of polynomial fc
poly_p = invert(fc)

# Multiply every coefficient with 2^{-l}
poly_p = list(map(lambda x: (x * INVLAY) % PRIMEQ, poly_p))

# Print (intermediate) values
print(f"Polynomial A : {poly_a}")
print(f"Polynomial B : {poly_b}")
print()
print(f"Forward NTT of A : {fa}")
print(f"Forward NTT of B : {fb}")
print()
print(f"Multiplied : {fc}")
print()
print(f"Result : {poly_p}")
