"""
This script can be used to calculate the roots (also called twiddle factors) for a cyclic or
negacyclic NTT. To do this we need the following ingredients:

*. VAR_Q : int
(Usually) a prime number. Used to bound the ring of integers. We use q to construct Z; a ring of
integers modulo q. We need to choose q such that a nth primitive root of unity (for a cyclic NTT)
and/or a 2nth primitive root of unity (for a negacyclic NTT) exists. If this is the case we also
call q to be NTT-friendly.

*. VAR_P : int
The size of the coefficient vectors used for representing our polynomials. (Usually) a power of
two. Used to determine how many indices we need and how much layers our NTT contains.

For the three size 512 NTTs used in NTRU LPRime (kem/ntrulpr761) these values are:
*. VAR_Q = 6984193
*. VAR_P = 512

Please note that for these values the current script will fail as there exists no 2nth primitive
root of unity (which is needed for the negacyclic NTT), i.e. 6984193 has no 1024th primitive
roof of unity. So please change accordingly
"""

from typing import List

# Define type alias for coefficient vectors
Vector = List[int]

# Global parameters
VAR_Q: int = 17
VAR_P: int = 8

# Construct the ring of integers modulo q
Z = IntegerModRing(VAR_Q)


def bitreverse(numbers: Vector, width: int) -> Vector:
    """
    Bitreverse a vector of values (with a fixed width) and return the result
    :param numbers: A vector containing the values that are to be bitreversed
    :param width: The number of bits a value should have in binary representation
    :return: The bitreversed numbers vector
    """
    # Format string to convert an integer to binary representation with the specified width
    fmt = f"{{0:0{width}b}}"
    # Reverse the binary representation and convert the result back to integer representation
    return [int(fmt.format(_)[::-1], 2) for _ in numbers]


def root_primitive(n: int) -> int:
    """
    Generate a nth primitive root of unity - if one exists
    :param n: This value determines the multiplicative order i.e. the primitive root of unity
    :return: The nth primitive root of unity - or an error if it does not exist
    """
    # Search all possible values in the constructed ring of integers modulo q
    for i in range(1, VAR_Q):
        if Z(i).multiplicative_order() == n:
            return Z(i)
    else:
        raise AssertionError(f"{VAR_Q} has no {n}th primitive root of unity")


def roots_cyclic() -> (Vector, Vector):
    """
    Calculate the (inverse) roots of a size VAR_P cyclic NTT
    :return: A 2 tuple containing the roots, inverse roots
    """
    # Generate a nth primitive root of unity
    psi = root_primitive(VAR_P)
    # Calculate the bitreversed indices
    brv = bitreverse(list(range(int(VAR_P / 2))), log(VAR_P, 2) - 1)

    # Calculate the roots
    roots = []
    values = [psi ^ brv[_] for _ in range(int(VAR_P / 2))]
    for idx in range(log(VAR_P, 2)):
        layer = 2 ^ idx
        roots += values[:layer]

    # Calculate the inverse roots
    roots_inv = [pow(_, -1, VAR_Q) for _ in roots]

    return roots, roots_inv


def roots_negacyclic() -> (Vector, Vector):
    """
    Calculate the (inverse) roots of a size VAR_P negacyclic NTT
    :return: A 2 tuple containing the roots, inverse roots
    """
    # Generate a 2nth primitive root of unity
    psi = root_primitive(2 * VAR_P)
    # Calculate the bitreversed indices
    brv = bitreverse(list(range(VAR_P)), log(VAR_P, 2))

    # Calculate the roots, use range(1, VAR_P) to skip the first element
    roots = [psi ^ brv[_] for _ in range(1, VAR_P)]
    # Calculate the inverse roots
    roots_inv = [pow(_, -1, VAR_Q) for _ in roots]

    return roots, roots_inv


# Calculate the roots for a cyclic NTT
c_roots, c_roots_inv = roots_cyclic()
# Calculate the roots for a negacyclic NTT
n_roots, n_roots_inv = roots_negacyclic()

print(f"The calculated roots for a size {VAR_P} cyclic NTT are:")
print(f"roots     = {c_roots}")
print(f"roots_inv = {c_roots_inv}")
print()

print(f"The calculated roots for a size {VAR_P} negacyclic NTT are:")
print(f"roots     = {n_roots}")
print(f"roots_inv = {n_roots_inv}")
