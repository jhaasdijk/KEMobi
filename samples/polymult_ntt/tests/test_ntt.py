#!/usr/bin/env python3

import random
import unittest

from common import NTT

p, q = 11, 17  # Define the original (p, q) parameters
p0, p1, p0p1 = 3, 8, 24  # Define NTT 'suitable' (p0, p1, p0p1) parameters

# Define roots when multiplying in Z_17 [x] / (x^8 - 1)
roots = [16, 4, 16, 2, 8, 4, 16]  # nth roots of unity
roots_inv = [16, 13, 16, 9, 15, 13, 16]  # inverse nth roots of unity


class TestNTT(unittest.TestCase):
    """ Class for testing the implemented Number Theoretic Transform """

    @classmethod
    def setUpClass(cls):
        """ setUpClass is used to define objects for the whole class """

        # Define a random polynomial A of size p1
        cls.A = [random.randint(0, q - 1) for _ in range(p1)]

        # Define an object to interact with the implemented NTT methods
        cls.ntt = NTT(q, p1, roots, roots_inv)

    def test_symmetry(self):
        """
        Testing for symmetry. One of the properties of NTT is that inverse (
        forward ( A ) ) should be equal to A.
        """

        # Compute the forward and inverse NTT
        result = self.ntt.inverse(self.ntt.forward(self.A))

        # The result should be equal to the original polynomial
        self.assertEqual(result, self.A)
