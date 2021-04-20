import math
from typing import List

from common import NTT
from common import reduce_q

Vector = List[int]

A = [1, 2, 3, 4, 5, 6, 7, 8]

Q, N = 17, 8
roots = [1, 1, 4, 1, 4, 2, 8]
roots_inv = [1, 1, 13, 1, 13, 9, 15]

# roots     = [13, 9, 15, 3, 5, 10, 11]
# roots_inv = [4, 2, 8, 6, 7, 12, 14]

ntt = NTT(Q, N, roots, roots_inv)

original = A.copy()

print(f"Original {A = }")

ntt.i_forward(A)
A = reduce_q(A, Q)
print(f"Forward: {A = }")

ntt.i_inverse(A)
A = reduce_q(A, Q)

# Calculate the accumulated constant factor: 2^{-lay} mod q
lay = int(math.log2(N))  # needs explicit conversion to integer
factor = pow(2, -lay, Q)  # this only works in Python3.8+
A = list(map(lambda _: (_ * factor) % Q, A))

print(f"Inverse: {A = }")
print(f"{original  == A = }")
