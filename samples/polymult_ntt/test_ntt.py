#!/usr/bin/env python3

from common import NTT

# Define the original (q) and NTT 'suitable' (p0, p1, p0p1) parameters
q, p0, p1, p0p1 = 17, 3, 8, 24

# Define roots when multiplying in Z_17 [x] / (x^8 - 1)
roots = [16, 4, 16, 2, 8, 4, 16]  # nth roots of unity
roots_inv = [16, 13, 16, 9, 15, 13, 16]  # inverse nth roots of unity

ntt = NTT(q, p1, roots, roots_inv)

# Define polynomials A, B of size 8 (size P1)
A = [1, 2, 3, 4, 5, 6, 7, 8]
B = [11, 10, 9, 8, 7, 6, 5, 4]

# Calculate the forward NTT
FA = ntt.forward(A)
FB = ntt.forward(B)

# Calculate the inverse NTT
IFA = ntt.inverse(FA)
IFB = ntt.inverse(FB)

print(f"invert_ntt ( forward_ntt ( A ) ) = A : {IFA == A}")
print(f"invert_ntt ( forward_ntt ( B ) ) = B : {IFB == B}")
