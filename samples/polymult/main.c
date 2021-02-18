#include "main.h"

/* Declare and define the prime inputs p and q */
/* p determines the degree of the polynomials */
/* q determines the modulus of the integer coefficients */

const uint32_t p = 5;
const uint32_t q = 7;

/**
 * The function convolution can be used to multiply two polynomials (A, B)
 * within the polynomial field (Z/q) [x] / (x^p - x - 1), i.e. R/q. This prints
 * the result of ( A * B ) % ( x^p - x - 1 ).
 *
 * @param uint32_t *A   p-length array representing an element in R/q
 * @param uint32_t *B   p-length array representing an element in R/q
 */

void convolution(uint32_t *A, uint32_t *B)
{
    polyPrint(A); /* print polynomial A */
    polyPrint(B); /* print polynomial B */

    uint32_t pdeg = 2 * (p - 1);      /* maximum degree of (A * B) */
    uint32_t P[pdeg];                 /* declare a 'result' polynomial P */
    for (size_t i = 0; i < pdeg; i++) /* and zero its content */
    {
        P[i] = 0;
    }

    polyMult(A, B, P); /* multiply polynomials A and B, i.e. P = (A * B) */
    polyRedterm(P);    /* reduce polynomial P % ( x^p - x - 1 ) */
    polyRedcoef(P);    /* reduce polynomial P's integer coefficients */

    polyPrint(P); /* print 'result' polynomial P */
}

/**
 * The function polyPrint can be used to print polynomials. It takes a
 * polynomial and prints it to stdout.
 * 
 * @param uint32_t *A   p-length array representing a polynomial
 */
void polyPrint(uint32_t *A)
{
    /* Skip over empty terms - terms with integer coefficient 0 */

    size_t i = 0;
    while (A[i] == 0)
    {
        i += 1;
    }

    /* Print first nonzero element */

    printf("%d", A[i]);
    printf("x^%ld", i);
    i += 1;

    /* Print the rest of the nonzero elements */

    for (; i < p; i++)
    {
        if (A[i] == 0)
        {
            continue;
        }

        printf(" + ");
        printf("%d", A[i]);
        printf("x^%ld", i);
    }

    printf("\n");
}

/**
 * The function polyMult can be used to multiply two polynomials with a very
 * naive approach. It uses a double for-loop in which it multiplies every term
 * from A with every term from B, adding the result into P.
 * 
 * @param uint32_t *A   p-length array representing polynomial A
 * @param uint32_t *B   p-length array representing polynomial B
 * @param uint32_t *P   array representing polynomial P; product of A * B
 */
void polyMult(uint32_t *A, uint32_t *B, uint32_t *P)
{
    for (size_t i = 0; i < p; i++)
    {
        for (size_t j = 0; j < p; j++)
        {
            P[i + j] += A[i] * B[j];
        }
    }
}

/**
 * The function polyRedterm can be used to reduce a polynomial P % ( x^p - x -
 * 1 ) , i.e. x^p = x^1 + x^0. Together with the function polyRedcoef this can
 * be used to bring a polynomial back into R/q.
 * 
 * @param uint32_t *P   array representing polynomial P
 */
void polyRedterm(uint32_t *P)
{
    for (size_t i = p; i < (2 * (p - 1)); i++)
    {
        if (P[i] > 0)
        {                           /* x^p is nonzero */
            P[i - (p - 1)] += P[i]; /* add x^p into x^1 */
            P[i - p] += P[i];       /* add x^p into x^0 */
            P[i] = 0;               /* zero x^p */
        }
    }
}

/**
 * The function polyRedcoef can be used to reduce a polynomial's integer
 * coefficients % q. This brings them back into Z/q. Together with the function
 * polyRedterm this can be used to bring a polynomial back into R/q.
 * 
 * @param uint32_t *P   array representing polynomial P
 */
void polyRedcoef(uint32_t *P)
{
    for (size_t i = 0; i < p; i++)
    {
        P[i] = P[i] % q;
    }
}

int main()
{
    /* Declare and define two polynomials A and B */

    uint32_t A[] = {0, 0, 0, 0, 1}; /* Representing x^4 */
    uint32_t B[] = {0, 0, 1, 0, 0}; /* Representing x^2 */

    /* Multiply polynomials A and B within R/q and print the result */

    convolution(A, B);

    return 0;
}