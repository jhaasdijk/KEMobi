import math
from typing import List
from typing import NoReturn

"""
This file is used to contain various helper functions and classes. It is not
meant to be executed by itself (it will not execute anything) but can be
called from other scripts. It contains shared components which can be reused
throughout the repository. Please refer to the specific class or function for
more details. Every class and function has been documented with an extensive
docstring and annotated with type hints
"""

# Define type alias for coefficient vectors and Good's matrices
Vector = List[int]
Matrix = List[List[int]]


def pad(cvec: Vector, size: int) -> Vector:
    """
    Zero pad a coefficient vector to the specified size
    :param cvec: The coefficient vector
    :param size: The specified size
    :return: Zero padded coefficient vector
    """
    assert len(cvec) <= size
    return cvec + [0 for _ in range(size - len(cvec))]


def reduce_q(cvec: Vector, q: int) -> Vector:
    """
    Reduce the integer coefficients of a coefficient vector with a modulus
    :param cvec: The coefficient vector
    :param q: The modulus
    :return: Coefficient vector with coefficients mod q
    """
    return [_ % q for _ in cvec]


class Goods:
    """
    The class Goods can be used for calculating the forward and inverse
    Good's permutation. Good's permutation allows you to deconstruct a size
    (p0 * p1^k) NTT as a combination of p0 size - p1^k NTTs, with p0 and p1
    being small prime numbers. This explains the variable naming. p0 and p1
    represent the prime numbers, p0p1 represents their multiplication. For
    example when p0=3, p1=2 and k=3, p0p1=24. Usually we use p1^k as p1
    """

    def __init__(self, p0: int, p1: int, p0p1: int) -> NoReturn:
        """ Class constructor used to initialize an instance of the class """
        self.p0, self.p1, self.p0p1 = p0, p1, p0p1

    def forward(self, cvec: Vector) -> Matrix:
        """
        Perform the forward Good's permutation on a size - p0p1 coefficient
        vector to obtain a p0 by p1 matrix
        :param cvec: The size - p0p1 coefficient vector
        :return: Matrix containing p0 size - p1 coefficient vectors
        """
        assert len(cvec) == self.p0p1
        rvec = [[0 for _ in range(self.p1)] for _ in range(self.p0)]

        for idx in range(self.p0p1):
            # Determine in which size - p1 NTT the coefficient ends up
            ntt = idx % self.p0
            # Determine which size - p1 NTT coefficient is used
            coef = idx % self.p1
            rvec[ntt][coef] = cvec[idx]

        return rvec

    def inverse(self, rvec: Matrix) -> Vector:
        """
        Perform the inverse Good's permutation (undo) on a p0 by p1 matrix to
        obtain a size - p0p1 coefficient vector
        :param rvec: Matrix containing p0 size - p1 coefficient vectors
        :return: The size - p0p1 coefficient vector
        """
        assert len(rvec) == self.p0
        assert len(rvec[0]) == self.p1
        cvec = [0 for _ in range(self.p0p1)]

        for idx in range(self.p0p1):
            # Determine in which size - p1 NTT the coefficient has ended up
            ntt = idx % self.p0
            # Determine which size - p1 NTT coefficient was used
            coef = idx % self.p1
            cvec[idx] = rvec[ntt][coef]

        return cvec


class NTT:
    """
    The class NTT can be used to calculate the forward and inverse Number
    Theoretic Transform (NTT) on polynomials represented by their coefficient
    vector. Use the _rec or _iti postfix functions for either a recursive or
    iterative inplace variant respectively. We need four ingredients in this
    calculation. The modulus of the ring of integers (q), the size of a
    coefficient vector (n), the roots of unity (roots) and the inverse roots
    of unity (roots_inv). The roots are also sometimes referred to as twiddle
    factors. Please refer to lib_roots.sage for more information regarding
    the roots, inverse roots and their assumed order
    """

    def __init__(self, q: int, n: int, roots: Vector,
                 roots_inv: Vector) -> NoReturn:
        """ Class constructor used to initialize an instance of the class """
        self.q, self.n, self.roots, self.roots_inv = q, n, roots, roots_inv

    def forward_rec(self, cvec: Vector, ridx: int = 0) -> Vector:
        """
        Calculate and return the forward NTT of a polynomial represented by its
        coefficient vector, recursively
        :param cvec: The coefficient vector
        :param ridx: Index used to point to the root of unity, default 0
        :return: The forward NTT transform (of the left and right halves)
        """
        if len(cvec) == 1:
            return cvec
        else:
            half = math.floor(len(cvec) / 2)
            cvec_l, cvec_r = [0 for _ in range(half)], [0 for _ in range(half)]

            for _ in range(half):
                mul = self.roots[ridx] * cvec[_ + half]
                cvec_l[_] = cvec[_] + mul
                cvec_r[_] = cvec[_] - mul

            cvec_l = reduce_q(cvec_l, self.q)
            cvec_r = reduce_q(cvec_r, self.q)

            return self.forward_rec(cvec_l, ridx * 2 + 1) \
                   + self.forward_rec(cvec_r, ridx * 2 + 2)

    def inverse_butterfly(self, cvec: Vector, ridx: int = 0) -> Vector:
        """
        Calculate and return the inverse NTT butterfly of a polynomial
        represented by its coefficient vector, recursively
        :param cvec: The coefficient vector
        :param ridx: Index used to point to the inverse root of unity, default 0
        :return: The (butterfly) inverse NTT transform
        """
        if len(cvec) == 1:
            return cvec
        else:
            half = math.floor(len(cvec) / 2)
            cvec_l = self.inverse_butterfly(cvec[:half], ridx * 2 + 1)
            cvec_r = self.inverse_butterfly(cvec[half:], ridx * 2 + 2)

            rvec = [0 for _ in range(self.n)]
            for _ in range(half):
                rvec[_] = cvec_l[_] + cvec_r[_]
                rvec[_ + half] = (cvec_l[_] - cvec_r[_]) * self.roots_inv[ridx]

            return rvec

    def inverse_rec(self, cvec: Vector) -> Vector:
        """
        Calculate and return the inverse NTT of a polynomial represented by
        its coefficient vector, recursively
        :param cvec: The coefficient vector
        :return: The complete inverse NTT transform
        """
        # Calculate the accumulated constant factor: 2^{-lay} mod q
        lay = int(math.log2(self.n))  # Needs explicit conversion to integer
        factor = pow(2, -lay, self.q)  # This only works in Python3.8+

        # Calculate inverse butterfly and multiply with the accumulated factor
        rvec = self.inverse_butterfly(cvec)
        return [(_ * factor) % self.q for _ in rvec]

    def forward_iti(self, cvec: Vector, ridx: int = 0) -> NoReturn:
        """
        Calculate and return the forward NTT of a polynomial represented by
        its coefficient vector, iteratively - inplace
        :param cvec: The coefficient vector
        :param ridx: Index used to point to the root of unity, default 0
        """
        # This needs an explicit cast to int as we are going to use the
        # variable length as an index. The variable length defines the size
        # of the polynomials, and thus the layer we are currently at
        length = int(self.n / 2)

        # Loop as long as there are layers - polynomials to split
        while length >= 1:

            # Define a variable for keeping the offset for the (next) chunk.
            # Start is used to jump to the various smaller parts within the
            # coefficient vector
            start = 0

            # Loop as long as there are polynomials in the current layer
            while start < self.n:

                # Obtain the root(s) for the current layer
                zeta, ridx = self.roots[ridx], ridx + 1

                # Start reading from the current offset. Read and split the
                # polynomial, i.e. perform the forward butterfly
                for _ in range(start, start + length):
                    temp = zeta * cvec[_ + length]
                    # Don't swap around the order of the next two instructions
                    cvec[_ + length] = cvec[_] - temp  # the upper half
                    cvec[_] = cvec[_] + temp  # the lower half

                start += 2 * length

            # This needs an explicit cast to int as we are using the variable
            # length as an index
            length = int(length / 2)

        # Reduce the integer coefficients inplace. This (mis)uses the Python
        # slicing operator ':' to overwrite the entire list '[:]' with a list
        # comprehension in which every element is reduced mod q
        cvec[:] = [_ % self.q for _ in cvec]

    def inverse_iti(self, cvec: Vector, ridx: int = 0) -> NoReturn:
        """
        Calculate and return the inverse NTT of a polynomial represented by its
        coefficient vector, iteratively - inplace. Please be aware that while
        the recursive inverse transformation elegantly jumps over the inverse
        roots, this iterative inverse transformation assumes the inverse
        roots have been reordered. Please refer to lib_roots.sage for details
        :param cvec: The coefficient vector
        :param ridx: Index used to point to the root of unity, default 0
        """
        # The variable length defines the size of the polynomials, and thus the
        # layer we are currently at
        length = 1

        # Loop as long as there are layers - polynomials to combine
        while length <= int(self.n / 2):

            # Define a variable for keeping the offset for the (next) chunk.
            # Start is used to jump to the various smaller parts within the
            # coefficient vector
            start = 0

            # Loop as long as there are polynomials in the current layer
            while start < self.n:

                # Obtain the root(s) for the current layer
                zeta, ridx = self.roots_inv[ridx], ridx + 1

                # Start reading from the current offset. Read and combine the
                # polynomial, i.e. perform the inverse butterfly
                for _ in range(start, start + length):
                    temp = cvec[_]
                    cvec[_] = (temp + cvec[_ + length])
                    cvec[_ + length] = temp - cvec[_ + length]
                    cvec[_ + length] *= zeta

                start += 2 * length

            length = length * 2

        # Calculate the accumulated constant factor: 2^{-lay} mod q
        # Multiply with this factor and reduce mod q to obtain the result
        lay = int(math.log2(self.n))  # Needs explicit conversion to integer
        factor = pow(2, -lay, self.q)  # This only works in Python3.8+
        cvec[:] = [(_ * factor) % self.q for _ in cvec]
