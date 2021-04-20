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

    def forward(self, cvec: Vector, ridx: int = 0) -> Vector:
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

            return self.forward(cvec_l, ridx * 2 + 1) \
                   + self.forward(cvec_r, ridx * 2 + 2)

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

    def inverse(self, cvec: Vector) -> Vector:
        """
        Calculate and return the inverse NTT of a polynomial represented by
        its coefficient vector
        :param cvec: The coefficient vector
        :return: The complete inverse NTT transform
        """

        # Calculate the accumulated constant factor: 2^{-lay} mod q
        lay = int(math.log2(self.p1))  # needs explicit conversion to integer
        factor = pow(2, -lay, self.q)  # this only works in Python3.8+

        inverse_butterfly = self.inverse_butterfly(cvec)
        rvec = list(map(lambda x: (x * factor) % self.q, inverse_butterfly))

        return rvec

    # def i_forward(self, cvec: Vector, k: int = 0) -> Vector:
    #     """
    #     Calculate and return the forward NTT of a polynomial represented by its
    #     coefficient vector, iteratively
    #     :param cvec: The coefficient vector
    #     :param k: Index used to point to the root of unity, default 0
    #     :return: The forward NTT transform
    #     """
    #
    #     print("Forward:")
    #
    #     # Make sure to return a shallow copy of the list instead of referring
    #     # to the same object! We do not want to calculate the values in-place
    #     r = cvec.copy()
    #
    #     # This needs an explicit cast to int as we are going to use the
    #     # variable length as an index
    #     len = int(self.p1 / 2)
    #
    #     # Loop as long as there are layers - chunks to split
    #     while len >= 1:
    #
    #         print(f"{len=}")
    #
    #         start = 0
    #         while start < self.p1:
    #
    #             print(f"{ start=}")
    #
    #             zeta, k = self.roots[k], k + 1
    #             j = start
    #
    #             print(f"{ zeta=}, { k=}")
    #
    #             # Loop over the split chunks
    #             # The variable len defines the size / layer we are at
    #             # FIXME: This temp=r.copy() shit needs to go
    #             #   At the moment we need this because otherwise we would be
    #             #   overwriting our intermediate output
    #             while j < (start + len):
    #                 temp = r.copy()  # TODO
    #                 t = zeta * temp[j + len]
    #                 r[j] = temp[j] + t  # called aL
    #                 r[j + len] = temp[j] - t  # called aR
    #                 print(f"{  j=}, {  t=}")
    #                 j += 1
    #
    #             start = j + len
    #
    #         # This needs an explicit cast to int as we are using the
    #         # variable length as an index
    #         len = int(len / 2)
    #
    #     return reduce_q(r, self.q)

    def i_forward(self, cvec: Vector, k: int = 0) -> Vector:
        """
        Calculate and return the forward NTT of a polynomial represented by its
        coefficient vector, iteratively
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
                    # FIXME : This in place works, but we should NOT swap
                    #   around the order of the next two instructions
                    cvec[j + len] = cvec[j] - t  # called aR
                    cvec[j] = cvec[j] + t  # called aL
                    j += 1

                start = j + len

            # This needs an explicit cast to int as we are using the
            # variable length as an index
            len = int(len / 2)

        return reduce_q(cvec, self.q)

    # def i_inverse(self, cvec: Vector) -> Vector:
    #     """
    #     Calculate and return the inverse NTT of a polynomial represented by its
    #     coefficient vector, iteratively
    #     :param cvec: The coefficient vector
    #     :return: The inverse NTT transform
    #     """
    #
    #     r = cvec.copy()
    #     k = 0
    #
    #     len = 1
    #     while len <= int(self.p1 / 2):
    #
    #         start = 0
    #         while start < self.p1:
    #
    #             zeta = self.roots_inv[k]
    #             k += 1
    #
    #             j = start
    #             while j < (start + len):
    #                 t = r[j]
    #                 r[j] = (t + r[j + len]) % self.q
    #                 r[j + len] -= t
    #                 r[j + len] *= zeta
    #
    #                 j += 1
    #
    #             start = j + len
    #
    #         len = len * 2
    #
    #     return reduce_q(r, self.q)

    def i_inverse(self, cvec: Vector) -> Vector:
        """
        Calculate and return the forward NTT of a polynomial represented by its
        coefficient vector, iteratively
        :param cvec: The coefficient vector
        :param k: Index used to point to the root of unity, default 0
        :return: The forward NTT transform
        """

        # This needs an explicit cast to int as we are going to use the
        # variable length as an index
        len = 1

        # FIXME: It might be better to reoder the roots_inv vector than it is to jump through it
        #  here, essentially doing the reordering step here. It's easier to reorder it externally

        layer = math.log2(self.p1) - 1  # FIXME

        # Loop as long as there are layers - chunks to split
        while len <= int(self.p1 / 2):
            k = int(2 ** layer - 1)  # FIXME

            # print(f"{len = }")
            # print(f" starting at : {k   = }")

            start = 0

            while start < self.p1:

                # print(f"{  start = }")

                idx, zeta, = start, self.roots_inv[k]

                while idx < (start + len):
                    temp = cvec[idx]
                    cvec[idx] = (temp + cvec[idx + len])
                    cvec[idx + len] = temp - cvec[idx + len]
                    cvec[idx + len] *= zeta

                    idx += 1

                start = idx + len
                # print(f"iterating k : {k}")
                k += 1  # FIXME
            # This needs an explicit cast to int as we are using the
            # variable length as an index
            len = len * 2
            layer -= 1

        return reduce_q(cvec, self.q)

# the forward recursive works and verifies with handexample
# the forward iterative (with temp) as well
# the forward iterative in place does something i cannot explain

# the inverse recursive works and verifies with handexample
# the inverse iterative does not work
