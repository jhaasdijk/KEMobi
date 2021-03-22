#!/usr/bin/env python3

import math

"""
This script can be used for multiplying two polynomials using NTT based
multiplication. We are multiplying in the ring R_q = Z_17 [x] / (x^4 + 1). This
means that we have two polynomials with integer coefficients from {0, 1, ...,
16}. The polynomials are reduced mod (x^4 + 1), i.e. x^4 = -1.
"""

PRIMEP = 4
PRIMEQ = 17

# 2^{-LAY} mod PRIMEQ = 2^{-2} mod 17 = 4^{-1} mod 17 = 13
LAY = int(math.log2(PRIMEP))  # needs explicit conversion to integer
INVLAY = pow(2, -LAY, PRIMEQ)  # this only works in Python3.8+

poly_a = [2, 0, 0, 7]  # 2 + 7x^3
poly_b = [6, 0, 2, 0]  # 6 + 2x^2

roots = [4, 2, 8]  # nth roots of unity
roots_inv = [13, 9, 15]  # inverse nth roots of unity


def reduce(cvec):
    """ Reduction of all integer coefficients mod PRIMEQ """
    return list(map(lambda x: x % PRIMEQ, cvec))


def forward(cvec, ridx=0):
    """ Calculate the forward NTT of polynomial cvec """
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


# Calculate the forward NTT of polynomials a, b
fa = forward(poly_a)
fb = forward(poly_b)

# Calculate the point-wise multiplication of fa, fb
# The integer coefficients are reduced Z_q
fc = [(a * b) % PRIMEQ for a, b in zip(fa, fb)]

# Calculate the inverse NTT of polynomial fc
# Unrolled loop - Layer 1
im = [0] * PRIMEP
im[0] = fc[0] + fc[1]
im[1] = (fc[0] - fc[1]) * roots_inv[1]
im[2] = fc[2] + fc[3]
im[3] = (fc[2] - fc[3]) * roots_inv[2]

# Unrolled loop - Layer 2
poly_p = [0] * PRIMEP
poly_p[0] = im[0] + im[2]
poly_p[1] = im[1] + im[3]
poly_p[2] = (im[0] - im[2]) * roots_inv[0]
poly_p[3] = (im[1] - im[3]) * roots_inv[0]

# Multiply every coefficient with 2^{-l}
poly_p = list(map(lambda x: (x * INVLAY) % PRIMEQ, poly_p))

# Print intermediate values
print(f"Polynomial A : {poly_a}")
print(f"Polynomial B : {poly_b}")
print()
print(f"Forward NTT of A : {fa}")
print(f"Forward NTT of B : {fb}")
print()
print(f"Multiplied : {fc}")
print()
print(f"Result : {poly_p}")
