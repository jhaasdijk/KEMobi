#!/usr/bin/env python3

import math

"""
This script can be used for multiplying two polynomials a, b using NTT based 
multiplication. We are multiplying in the ring R_q = Z_17 [x] / (x^4 + 1). 
This means that we have two polynomials with integer coefficients from {0, 1, 
..., 16}. The polynomials are reduced mod (x^4 + 1), i.e. x^4 = -1.
"""

PRIMEP = 4
PRIMEQ = 17
INVLAY = 13  # 2^{-l} mod PRIMEQ = 2^{-2} mod 17 = 4^{-1} mod 17

poly_a = [2, 0, 0, 7]  # 2 + 7x^3
poly_b = [6, 0, 2, 0]  # 6 + 2x^2
poly_p = [None] * PRIMEP

roots = [4, 2, 8]  # nth roots of unity
roots_inv = [13, 9, 15]  # inverse nth roots of unity


def reduce(p):
    """ Reduction of all integer coefficients of p, mod PRIMEQ """
    return list(map(lambda x: x % PRIMEQ, p))


def forward(a, index):
    """ Calculate the forward NTT of polynomial a """
    if len(a) == 1:
        return a
    else:
        half = math.floor(len(a) / 2)
        al, ar = [None] * half, [None] * half

        for idx in range(half):
            al[idx] = a[idx] + roots[index] * a[idx + half]
            ar[idx] = a[idx] - roots[index] * a[idx + half]

        al = reduce(al)
        ar = reduce(ar)

        return forward(al, index + 1) + forward(ar, index + 2)


def inverse(c, index):
    """ Calculate the inverse NTT of polynomial c """
    if len(c) > 2:
        half = math.floor(len(c) / 2)
        return inverse(c[:half], index + 1) + inverse(c[half:], index + 2)
    else:
        cl, cr = [None], [None]
        cl[0] = c[0] + c[1]
        cr[0] = (c[0] - c[1]) * roots_inv[index]
        return reduce(cl) + reduce(cr)


""" Calculate the forward NTT of polynomials a, b """
fa = forward(poly_a, 0)
fb = forward(poly_b, 0)

""" Calculate the point-wise multiplication of fa, fb """
fc = [(a * b) % PRIMEQ for a, b in zip(fa, fb)]

""" Printing intermediate values """
print(f"Polynomial A : {poly_a}")
print(f"Polynomial B : {poly_b}")
print()

print(f"Forward NTT of A : {fa}")
print(f"Forward NTT of B : {fb}")
print()

print(f"Multiplied : {fc}")
print()

""" Calculate the inverse NTT of polynomial fc """
# inverse the inner products
fc = inverse(fc, 0)
# inverse the outer (final) product
bound = math.floor(len(fc) / 2)
for i in range(bound):
    poly_p[i] = fc[i] + fc[i + bound]
    poly_p[i + bound] = (fc[i] - fc[i + bound]) * roots_inv[0]

""" Multiply every coefficient with 2^{-l} """
poly_p = list(map(lambda x: (x * INVLAY) % PRIMEQ, poly_p))
print(f"Result : {poly_p}")
