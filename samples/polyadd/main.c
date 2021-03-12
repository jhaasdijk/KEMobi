#include "main.h"

const uint32_t PRIMEP = 6; /* p, determines the degree of the polynomials A and B */
const uint32_t PRIMEQ = 7; /* q, determines the modulus of the integer coefficients */

extern void polyAddAsm(uint32_t *A, uint32_t *B, uint32_t *P);

/**
 * The function polyAdd can be used to add two polynomials with a very naive
 * approach. It uses a simple for-loop in which it adds equivalent terms from A
 * to B, adding the result into P.
 * 
 * @param uint32_t *A   p-length array representing polynomial A
 * @param uint32_t *B   p-length array representing polynomial B
 * @param uint32_t *P   array representing polynomial P; product of A + B
 */
void polyAdd(uint32_t *A, uint32_t *B, uint32_t *P)
{
    for (size_t i = 0; i < PRIMEP; i++)
    {
        P[i] = A[i] + B[i];
    }
}

/**
 * The function polyRedcoef can be used to reduce a polynomial's integer
 * coefficients mod q. This brings them back into Z/q.
 * 
 * @param uint32_t *P   p-length array representing a polynomial
 */
void polyRedcoef(uint32_t *P)
{
    for (size_t i = 0; i < PRIMEP; i++)
    {
        P[i] = P[i] % PRIMEQ;
    }
}

/**
 * The function polyPrint can be used to print polynomials. It takes a
 * polynomial and prints it to stdout.
 * 
 * @param uint32_t *P   p-length array representing a polynomial
 */
void polyPrint(uint32_t *P)
{
    /* Skip over empty terms - terms with integer coefficient 0 */

    size_t i = 0;
    while (P[i] == 0 && i < PRIMEP - 1)
    {
        i += 1;
    }

    /* Print first nonzero element */

    printf("%d", P[i]);
    printf("x^%ld", i);
    i += 1;

    /* Print the rest of the nonzero elements */

    for (; i < PRIMEP; i++)
    {
        if (P[i] == 0)
        {
            continue;
        }

        printf(" + ");
        printf("%d", P[i]);
        printf("x^%ld", i);
    }

    printf("\n");
}

int main()
{
    /* Declare and define two polynomials A and B */

    uint32_t A[] = {1, 2, 3, 4, 5, 6}; /* Representing x^4 */
    uint32_t B[] = {1, 2, 3, 4, 5, 6}; /* Representing x^2 */

    /* Add polynomials A and B within R/q and print the result */

    uint32_t P[] = {0, 0, 0, 0, 0, 0};
    polyAdd(A, B, P);
    polyRedcoef(P);
    polyPrint(P);

    /* Add polynomials A and B within R/q and print the result - assembly */

    uint32_t Q[] = {0, 0, 0, 0, 0, 0};
    polyAddAsm(A, B, Q);
    polyRedcoef(Q);
    polyPrint(Q);

    return 0;
}