#!/usr/bin/env python3

from common import Goods
from common import pad

# Define NTT 'suitable' (p0, p1, p0p1) parameters
p0, p1, p0p1 = 3, 8, 24
goods = Goods(p0, p1, p0p1)

# Define polynomials A, B of size 11 (size p1)
A = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
B = [11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

# Zero pad polynomials A, B to size 24
A_PAD = pad(A, p0p1)
B_PAD = pad(B, p0p1)

# Compute Good's permutation
A_PAD_G = goods.forward(A_PAD)
B_PAD_G = goods.forward(B_PAD)

# Undo Good's permutation
C_PAD = goods.inverse(A_PAD_G)
D_PAD = goods.inverse(B_PAD_G)

print(f"invert_goods ( goods ( A ) ) = A : {C_PAD == A_PAD}")
print(f"invert_goods ( goods ( B ) ) = B : {D_PAD == B_PAD}")
