#!/usr/bin/env python3

from lib_common import NTT

"""
This script can be used for multiplying two polynomials using NTT based
multiplication. We are multiplying in the ring R_q = Z_17 [x] / (x^4 + 1). This
means that we have two polynomials with integer coefficients from {0, 1, ...,
16}. The polynomials are reduced mod (x^4 + 1), i.e. x^4 = -1.
"""

PRIMEP, PRIMEQ = 4, 17

# Define polynomials A, B of size 4
A = [2, 0, 0, 7]  # 2 + 7x^3
B = [6, 0, 2, 0]  # 6 + 2x^2

# Roots when multiplying in Z_17 [x] / (x^4 + 1)
roots = [4, 2, 8]  # nth roots of unity
roots_inv = [13, 9, 15]  # inverse nth roots of unity

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

print(f"Calculating : Zx({A}) * Zx({B}) % (x^4 + 1) % 17")
print(f"Produces    : {C}")
