#include <stdint.h>
#include <stdio.h>

#define VAR_P 8
#define VAR_Q 17

/*
 * TODO : Make sure that numeric types are large enough to contain the result
 *
 * TODO : ^ Check this for the point wise multiplication, and any other
 *  multiplications that occur during the NTT transformation
 *
 * TODO : Recheck and possibly rewrite (or explain) why we have a custom mod
 *  function
 *
 * TODO : Maybe we can force a specific width when printing numeric values
 *  such that when comparing them top of each other its easier
 *
 * TODO : Rethink whether we want to work with struct polynomial. It might be
 *  simpler to just work with arrays everywhere
 */

/**
 * Define a custom struct for representing polynomials. Each polynomial is
 * represented using a vector of its coefficients, e.g. {1, 2, 3} represents
 * the polynomial 3x^2 + 2x + 1. Each coefficient is represented by an
 * unsigned 32 bit integer.
 */
struct polynomial
{
    uint32_t coefficients[VAR_P];
};

/**
 * These are the roots for a size - 8 cyclic NTT, i.e. we are multiplying two
 * polynomials in Z_17 [x] / (x^8 - 1). Remember that the inverse roots have
 * been reordered since we are using an iterative approach.
 */
const uint32_t roots[] = {1, 1, 4, 1, 4, 2, 8};
const uint32_t roots_inv[] = {1, 13, 9, 15, 1, 13, 1};

/**
 * Define a custom modulo operator that calculates the remainder after
 * Euclidean division. This snippet has been taken from
 * https://stackoverflow.com/questions/11720656/
 */
int mod(int a, int b)
{
    int m = a % b;
    if (m < 0)
    {
        m = (b < 0) ? m - b : m + b;
    }
    return m;
}

/**
 * This function can be used to print a polynomial that is represented by a
 * vector of its coefficients to stdout.
 *
 * @param polynomial The polynomial to be printed
 */
void print_polynomial(struct polynomial polynomial)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        printf("%d ", polynomial.coefficients[i]);
    }
    printf("\n");
}

/**
 * This function can be used to reduce a polynomial's integer coefficients
 * mod q. This brings them back into Z_q.
 *
 * TODO : Update this function to not hardcode VAR_Q inside, but instead
 *  introduce a parameter for the modulus
 *
 * @param coefficients The integer coefficients
 */
void reduce_coefficients(uint32_t *coefficients)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        coefficients[i] = mod(coefficients[i], VAR_Q);
    }
}

/**
 * This function can be used to perform point - wise multiplication of the
 * integer coefficients of two polynomials and store the result.
 *
 * TODO : Verify that the result of uint32_t * uint32_t fits inside out
 *
 * @param poly_o The output polynomial, this is where the result is stored
 * @param poly_a The first input polynomial
 * @param poly_b The second input polynomial
 */
void multiplication(uint32_t *poly_o, uint32_t *poly_a, uint32_t *poly_b)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        poly_o[i] = poly_a[i] * poly_b[i];
    }

    reduce_coefficients(poly_o);
}

void forward_layer_1(uint32_t *coefficients)
{
    unsigned int length = 4, ridx = 0;
    int temp;

    uint32_t zeta = roots[ridx];

    for (size_t i = 0; i < length; i++)
    {
        temp = zeta * coefficients[i + length];
        coefficients[i + length] = coefficients[i] - temp;
        coefficients[i] = coefficients[i] + temp;
    }
}

void forward_layer_2(uint32_t *coefficients)
{
    unsigned int length = 2, ridx = 1;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        uint32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = zeta * coefficients[idx + length];
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }

    }
}

void forward_layer_3(uint32_t *coefficients)
{
    unsigned int length = 1, ridx = 3;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        uint32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = zeta * coefficients[idx + length];
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void inverse_layer_3(uint32_t *coefficients)
{
    unsigned int length = 1, ridx = 0;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        uint32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] *= zeta;
        }
    }
}

void inverse_layer_2(uint32_t *coefficients)
{
    unsigned int length = 2, ridx = 4;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        uint32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] *= zeta;
        }
    }
}

void inverse_layer_1(uint32_t *coefficients)
{
    unsigned int length = 4, ridx = 6;
    int temp;

    uint32_t zeta = roots_inv[ridx];

    for (size_t i = 0; i < length; i++)
    {
        temp = coefficients[i];
        coefficients[i] = temp + coefficients[i + length];
        coefficients[i + length] = temp - coefficients[i + length];
        coefficients[i + length] *= zeta;
    }

    /*
     * Multiply the result with the accumulated factor to complete the
     * inverse NTT transform. We can calculate this factor by computing
     * 2^{-lay} mod q, where lay is equal to the number of layers. Multiply
     * and reduce mod q to obtain the result
     */
    unsigned int factor = 15;

    for (size_t i = 0; i < VAR_P; i++)
    {
        coefficients[i] = coefficients[i] * factor;
        coefficients[i] = mod(coefficients[i], VAR_Q);
    }
}

int main()
{
    /* Define two polynomials A, B of size VAR_P */
    struct polynomial A = {2, 0, 0, 7, 2, 0, 0, 7};
    struct polynomial B = {6, 0, 2, 0, 6, 0, 2, 0};

    /* Print the original values */
    printf("%s\n", "The original values are:");
    print_polynomial(A);
    print_polynomial(B);
    printf("\n");

    /* Compute the iterative inplace forward NTT of polynomials A, B */
    forward_layer_1(A.coefficients);
    forward_layer_2(A.coefficients);
    forward_layer_3(A.coefficients);
    reduce_coefficients(A.coefficients);

    forward_layer_1(B.coefficients);
    forward_layer_2(B.coefficients);
    forward_layer_3(B.coefficients);
    reduce_coefficients(B.coefficients);

    /* Print the forward NTT values */
    printf("%s\n", "The forward values are:");
    print_polynomial(A);
    print_polynomial(B);
    printf("\n");

    /* Compute the point-wise multiplication of the integer coefficients */
    struct polynomial C;
    multiplication(C.coefficients, A.coefficients, B.coefficients);

    printf("%s\n", "The values after the point-wise multiplication");
    print_polynomial(C);
    printf("\n");

    /* Compute the iterative inplace inverse NTT of polynomial C */
    inverse_layer_3(C.coefficients);
    inverse_layer_2(C.coefficients);
    inverse_layer_1(C.coefficients);

    printf("%s\n", "The inverse values are:");
    print_polynomial(C);
    printf("\n");

    return 0;
}
