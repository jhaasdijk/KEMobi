#!/usr/bin/env python3

import random
import unittest

from common import Goods
from common import pad

p, q = 11, 17  # Define the original (p, q) parameters
p0, p1, p0p1 = 3, 8, 24  # Define NTT 'suitable' (p0, p1, p0p1) parameters


class TestGoods(unittest.TestCase):
    """ Class for testing the implemented Good's trick """

    @classmethod
    def setUpClass(cls):
        """ setUpClass is used to define objects for the whole class """

        # Define a random polynomial A of size p and zero pad to size p0p1
        cls.A = pad([random.randint(0, q - 1) for _ in range(p)], p0p1)

        # Define an object to interact with the implemented Good's methods
        cls.goods = Goods(p0, p1, p0p1)

    def test_symmetry(self):
        """
        Testing for symmetry. One of the properties of Good's trick is that
        inverse ( forward ( A ) ) should be equal to A.
        """

        # Compute and undo Good's permutation
        result = self.goods.inverse(self.goods.forward(self.A))

        # The result should be equal to the original polynomial
        self.assertEqual(result, self.A)
