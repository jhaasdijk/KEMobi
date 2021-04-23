import math
from typing import List
from typing import NoReturn

# Define type alias for coefficient vectors and Good's matrices
Vector = List[int]
Matrix = List[List[int]]


def pad(cvec: Vector, p0p1: int) -> Vector:
    """
    Zero pad a coefficient vector to the specified size
    :param cvec: The coefficient vector
    :param p0p1: The specified size
    :return: Zero padded size-p0p1 coefficient vector
    """
    assert len(cvec) <= p0p1
    return cvec + [0 for _ in range(p0p1 - len(cvec))]


def reduce_q(cvec: Vector, q: int) -> Vector:
    """
    Reduce the integer coefficients of a coefficient vector with a modulus
    :param cvec: The coefficient vector
    :param q: The modulus
    :return: Coefficient vector with coefficients mod q
    """
    return list(map(lambda x: x % q, cvec))


class Goods:

    def __init__(self, p0: int, p1: int, p0p1: int) -> NoReturn:
        """ Class constructor used to initialize an instance of the class """
        self.p0, self.p1, self.p0p1 = p0, p1, p0p1

    def forward(self, cvec: Vector) -> Matrix:
        """
        Perform the forward Good's permutation on a size-p0p1 coefficient
        vector to obtain a p0 by p1 matrix
        :param cvec: The size-p0p1 coefficient vector
        :return: Matrix containing p0 size-p1 coefficient vectors
        """
        assert len(cvec) == self.p0p1
        rvec = [[0 for _ in range(self.p1)] for _ in range(self.p0)]

        for idx in range(self.p0p1):
            # determine in which size-p1 NTT the coefficient ends up
            ntt = idx % self.p0
            # determine which size-p1 NTT coefficient is used
            coef = idx % self.p1
            rvec[ntt][coef] = cvec[idx]

        return rvec

    def inverse(self, rvec: Matrix) -> Vector:
        """
        Perform the inverse Good's permutation (undo) on a p0 by p1 matrix to
        obtain a size-p0p1 coefficient vector
        :param rvec: Matrix containing p0 size-p1 coefficient vectors
        :return: The size-p0p1 coefficient vector
        """
        assert len(rvec) == self.p0
        assert len(rvec[0]) == self.p1
        cvec = [0 for _ in range(self.p0p1)]

        for idx in range(self.p0p1):
            # determine in which size-p1 NTT the coefficient has ended up
            ntt = idx % self.p0
            # determine which size-p1 NTT coefficient was used
            coef = idx % self.p1
            cvec[idx] = rvec[ntt][coef]

        return cvec


class NTT:

    def __init__(self, q: int, p1: int, roots: Vector,
                 roots_inv: Vector) -> NoReturn:
        """ Class constructor used to initialize an instance of the class """
        self.q, self.p1, self.roots, self.roots_inv = q, p1, roots, roots_inv

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

            for idx in range(half):
                cvec_l[idx] = cvec[idx] + self.roots[ridx] * cvec[idx + half]
                cvec_r[idx] = cvec[idx] - self.roots[ridx] * cvec[idx + half]

            cvec_l = reduce_q(cvec_l, self.q)
            cvec_r = reduce_q(cvec_r, self.q)

            return self.forward_rec(cvec_l, ridx * 2 + 1) \
                   + self.forward_rec(cvec_r, ridx * 2 + 2)

    def inverse_butterfly(self, cvec: Vector, ridx: int = 0) -> Vector:
        """
        Calculate and return the inverse NTT butterfly of a polynomial
        represented by its coefficient vector
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

            rvec = [0 for _ in range(self.p1)]
            for idx in range(half):
                rvec[idx] = cvec_l[idx] + cvec_r[idx]
                rvec[idx + half] = (cvec_l[idx] - cvec_r[idx]) \
                                   * self.roots_inv[ridx]

            return rvec

    def inverse_rec(self, cvec: Vector) -> Vector:
        """
        Calculate and return the inverse NTT of a polynomial represented by
        its coefficient vector, recursively
        :param cvec: The coefficient vector
        :return: The complete inverse NTT transform
        """

        # Calculate the accumulated constant factor: 2^{-lay} mod q
        lay = int(math.log2(self.p1))  # needs explicit conversion to integer
        factor = pow(2, -lay, self.q)  # this only works in Python3.8+

        inverse_butterfly = self.inverse_butterfly(cvec)
        rvec = [(_ * factor) % self.q for _ in inverse_butterfly]

        return rvec

    def forward_iti(self, cvec: Vector, k: int = 0) -> NoReturn:
        """
        Calculate and return the forward NTT of a polynomial represented by
        its coefficient vector, iteratively - inplace
        :param cvec: The coefficient vector
        :param k: Index used to point to the root of unity, default 0
        :return: The forward NTT transform
        """

        # This needs an explicit cast to int as we are going to use the
        # variable length as an index
        len = int(self.p1 / 2)

        # Loop as long as there are layers - chunks to split
        while len >= 1:

            start = 0
            while start < self.p1:

                zeta, k = self.roots[k], k + 1
                j = start

                # Loop over the split chunks
                # The variable len defines the size / layer we are at
                while j < (start + len):
                    t = zeta * cvec[j + len]
                    # Don't swap around the order of the next two instructions
                    cvec[j + len] = cvec[j] - t  # the upper half
                    cvec[j] = cvec[j] + t  # the lower half
                    j += 1

                start = j + len

            # This needs an explicit cast to int as we are using the variable
            # length as an index
            len = int(len / 2)

        # Reduce the integer coefficients inplace
        for _ in range(self.p1):
            cvec[_] %= self.q

    def inverse_iti(self, cvec: Vector, k: int = 0) -> NoReturn:
        """
        Calculate and return the forward NTT of a polynomial represented by its
        coefficient vector, iteratively - inplace
        :param cvec: The coefficient vector
        :param k: Index used to point to the root of unity, default 0
        :return: The forward NTT transform
        """

        # This needs an explicit cast to int as we are going to use the
        # variable length as an index
        len = 1

        # TODO : This has been updated in calc_roots.sage - reorder
        #  Please update the roots accordingly. Use k: int = 0 in the
        #  function header and iterate over k -> k+1 -> k+2 similarly as how
        #  this is done in forward_iti()

        # TODO : Since this function now also does the factor multiply we
        #  need to remove this bit from everywhere we called this separately
        #  before

        # FIXED: It might be better to reorder the roots_inv vector than it
        #  is to jump through it here, essentially doing the reordering step
        #  here. It's easier to reorder it externally. So instead of having
        #  the roots with indices [0, 1, 2, 3, 4, 5, 6] we would want them to
        #  be [3, 4, 5, 6, 1, 2, 0]

        # Loop as long as there are layers - chunks to split
        while len <= int(self.p1 / 2):

            start = 0
            while start < self.p1:

                idx, zeta, k = start, self.roots_inv[k], k + 1

                while idx < (start + len):
                    temp = cvec[idx]
                    cvec[idx] = (temp + cvec[idx + len])
                    cvec[idx + len] = temp - cvec[idx + len]
                    cvec[idx + len] *= zeta

                    idx += 1

                start = idx + len

            len = len * 2

        # Calculate the accumulated constant factor: 2^{-lay} mod Q
        # Multiply with this factor and reduce mod Q to obtain the inverse
        lay = int(math.log2(self.p1))  # needs explicit conversion to integer
        factor = pow(2, -lay, self.q)  # this only works in Python3.8+
        for _ in range(self.p1):
            cvec[_] = (cvec[_] * factor) % self.q
