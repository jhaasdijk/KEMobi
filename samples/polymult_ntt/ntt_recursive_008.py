#!/usr/bin/env python3

from lib_common import NTT

"""
This script can be used for multiplying two polynomials using NTT based
multiplication. We are multiplying in the ring R_q = Z_17 [x] / (x^8 + 1). This
means that we have two polynomials with integer coefficients from {0, 1, ...,
16}. The polynomials are reduced mod (x^8 + 1), i.e. x^8 = -1.
"""

PRIMEP, PRIMEQ = 8, 17

# Define polynomials A, B of size 8
A = [2, 0, 0, 7, 2, 0, 0, 7]  # 2 + 7x^3 + 2x^4 + 7x^7
B = [6, 0, 2, 0, 6, 0, 2, 0]  # 6 + 2x^2 + 6x^4 + 2x^6

# Roots when multiplying in Z_17 [x] / (x^8 + 1)
roots = [4, 2, 8, 6, 10, 5, 3]  # nth roots of unity
roots_inv = [13, 9, 15, 3, 12, 7, 6]  # inverse nth roots of unity

# Setup our NTT transform (parameters)
ntt = NTT(PRIMEQ, PRIMEP, roots, roots_inv)

# Calculate the forward NTT of polynomials A, B
A_F = ntt.forward(A)
B_F = ntt.forward(B)

# Calculate the point-wise multiplication of A_F, B_F
# The integer coefficients are reduced Z_q
C_F = [(a * b) % PRIMEQ for a, b in zip(A_F, B_F)]

# Calculate the inverse NTT of polynomial C_F
C = ntt.inverse(C_F)

# 16*x^7 + 8*x^6 + 7*x^4 + 6*x
print(f"Calculating : Zx({A}) * Zx({B}) % (x^8 + 1) % 17")
print(f"Produces    : {C}")
print(f"This result is {C == [0, 6, 0, 0, 7, 0, 8, 16]}")
