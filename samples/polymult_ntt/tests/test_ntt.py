#!/usr/bin/env python3
import random
import unittest

from lib_common import NTT

# Define the NTT 'suitable' parameters
VAR_Q, VAR_P = 17, 8

# Define roots when multiplying in Z_17 [x] / (x^8 - 1)
roots = [1, 1, 4, 1, 4, 2, 8]  # roots of unity
roots_inv = [1, 1, 13, 1, 13, 9, 15]  # inverse roots of unity
roots_inv_r = [1, 13, 9, 15, 1, 13, 1]  # reordered inverse roots of unity


class TestNTT(unittest.TestCase):
    """ Class for testing the implemented Number Theoretic Transform """

    @classmethod
    def setUpClass(cls):
        """ setUpClass is used to define objects for the whole class """

        # Define a random polynomial A of size VAR_P
        cls.A = [random.randint(0, VAR_Q - 1) for _ in range(VAR_P)]

    def test_symmetry_rec(self):
        """
        Testing for symmetry. One of the properties of NTT is that inverse (
        forward ( A ) ) should be equal to A. This test uses the recursive
        NTT methods, which is why we need roots_inv
        """

        # Define an object to interact with the implemented NTT methods
        self.ntt = NTT(VAR_Q, VAR_P, roots, roots_inv)

        # Compute the forward and inverse NTT
        result = self.ntt.inverse_rec(self.ntt.forward_rec(self.A))

        # The result should be equal to the original polynomial
        self.assertEqual(result, self.A)

    def test_symmetry_iti(self):
        """
        Testing for symmetry. One of the properties of NTT is that inverse (
        forward ( A ) ) should be equal to A. This test uses the iterative
        inplace NTT methods, which is why we need roots_inv_r
        """

        # Define an object to interact with the implemented NTT methods
        self.ntt = NTT(VAR_Q, VAR_P, roots, roots_inv_r)

        # Since we are calculating inplace we need to make a copy
        original = self.A.copy()

        # Compute the forward and inverse NTT
        self.ntt.forward_iti(self.A)
        self.ntt.inverse_iti(self.A)

        # The result should be equal to the original polynomial
        self.assertEqual(original, self.A)
