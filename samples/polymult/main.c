#include "main.h"

/**
 * The function polyPrint can be used to print polynomials. It takes a
 * polynomial and its size, and prints the polynomial to stdout.
 * 
 * @param uint64_t *A       array representing the polynomial to be printed
 * @param uint64_t size     the length of the array / polynomial
 */
void polyPrint(uint64_t *A, uint64_t size)
{
    for (uint64_t i = 0; i < size; i++)
    {
        printf("%ld", A[i]);
        printf("x^%ld", i);
        if (i != size - 1)
        {
            printf(" + ");
        }
    }
    printf("\n");
}

/**
 * The function polyMult can be used to multiply two polynomials with a very
 * naive approach. It uses a double for-loop in which it multiplies every term
 * from A with every term from B, adding the result into P.
 * 
 * @param uint64_t *A       array representing polynomial A
 * @param uint64_t *B       array representing polynomial B
 * @param uint64_t lenA     the length of the array / polynomial A
 * @param uint64_t lenB     the length of the array / polynomial B
 * @param uint64_t *P       array representing polynomial P; product of A * B
 */
void polyMult(uint64_t *A, uint64_t *B, uint64_t lenA, uint64_t lenB, uint64_t *P)
{
    for (uint64_t i = 0; i < lenA; i++)
    {
        for (uint64_t j = 0; j < lenB; j++)
        {
            P[i + j] += A[i] * B[j];
        }
    }
}

int main()
{
    /* Declare, define and print two polynomials A and B */

    uint64_t A[] = {4, 2, 2, 4, 3};
    uint64_t B[] = {0, 7, 3, 4};

    uint64_t lenA = sizeof(A) / sizeof(A[0]);
    uint64_t lenB = sizeof(B) / sizeof(B[0]);

    polyPrint(A, lenA);
    polyPrint(B, lenB);

    /* Declare a 'product' polynomial P and zero its content */

    uint64_t lenP = lenA + lenB - 1;
    uint64_t P[lenP];
    for (uint64_t i = 0; i < lenP; i++)
    {
        P[i] = 0;
    }

    /* Multiply polynomials A and B and put the result in P */

    polyMult(A, B, lenA, lenB, P);
    polyPrint(P, lenP);

    return 0;
}