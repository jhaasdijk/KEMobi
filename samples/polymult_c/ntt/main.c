#include "main.h"

/*
 * Instead of defining a custom type for representing polynomials, each
 * polynomial is represented using an array of its integer coefficients. For
 * instance {1, 2, 3} represents the polynomial 3x^2 + 2x + 1. Each
 * coefficient is represented as an unsigned 32 bit integer (uint32_t). This
 * makes it easier to identify and use numeric types properly instead of
 * hiding what types are being used under the hood.
 */

/*
 * TODO : Make sure that numeric types are large enough to contain the result
 */

/**
 * This function can be used to print a polynomial that is represented by a
 * array of its coefficients to stdout. Numeric values are printed with a
 * specified column width of 2. This makes it easier to compare output of
 * different runs.
 *
 * @param coefficients An array of integer coefficients (i.e. a polynomial)
 */
void print_polynomial(uint32_t *coefficients)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        printf(" %*d", 2, coefficients[i]);
    }
    printf("\n");
}

/**
 * Define a custom modulo operator that calculates the remainder after
 * Euclidean division. This snippet has been taken from
 * https://stackoverflow.com/a/52529440
 */
int modulo(int a, int b)
{
    int m = a % b;
    if (m < 0)
    {
        m = (b < 0) ? m - b : m + b;
    }
    return m;
}

/**
 * This function can be used to reduce a polynomial's integer coefficients.
 * The modulo will always be positive and the largest value we are going to
 * use is 6984193. We can therefore simply use uint32_t.
 *
 * @param coefficients An array of integer coefficients (i.e. a polynomial)
 * @param mod The modulo used to reduce each integer value
 */
void reduce_coefficients(uint32_t *coefficients, uint32_t mod)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        coefficients[i] = modulo(coefficients[i], mod);
    }
}

/**
 * This function can be used to perform point - wise multiplication of the
 * integer coefficients of two polynomials and store the (reduced) result.
 *
 * FIXME : Ensure that the result of uint32_t * uint32_t fits inside output
 *
 * @param output An array of integer coefficients for storing the result
 * @param x An array of integer coefficients, the first input
 * @param y An array of integer coefficients, the second input
 * @param mod The modulo used to reduce each integer value of the result
 */
void multiplication(uint32_t *output, uint32_t *x, uint32_t *y, uint32_t mod)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        output[i] = x[i] * y[i];
    }

    reduce_coefficients(output, mod);
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
     * 2^{-lay} mod q, where lay is equal to the number of layers.
     */
    unsigned int factor = 15;

    for (size_t i = 0; i < VAR_P; i++)
    {
        coefficients[i] = coefficients[i] * factor;
    }
}

/**
 * This function can be used to compute the iterative inplace forward NTT of
 * a polynomial represented by its integer coefficients. It wraps the earlier
 * defined per-layer forward transformations into a single, easy to use
 * function.
 *
 * FIXME : Ensure that the result of 'temp = zeta * coefficients[i + length];'
 *  fits in the used numeric type
 *
 * @param coefficients An array of integer coefficients (i.e. a polynomial)
 * @param mod The modulo used to reduce each integer value
 */
void forward_ntt(uint32_t *coefficients, uint32_t mod)
{
    forward_layer_1(coefficients);
    forward_layer_2(coefficients);
    forward_layer_3(coefficients);
    reduce_coefficients(coefficients, mod);
}

/**
 * This function can be used to compute the iterative inplace inverse NTT of
 * a polynomial represented by its integer coefficients. It wraps the earlier
 * defined per-layer inverse transformations into a single, easy to use
 * function.
 *
 * FIXME : Ensure that the result of 'coefficients[i + length] *= zeta;' fits
 *  it the used numeric type
 *
 * @param coefficients An array of integer coefficients (i.e. a polynomial)
 * @param mod The modulo used to reduce each integer value
 */
void inverse_ntt(uint32_t *coefficients, uint32_t mod)
{
    inverse_layer_3(coefficients);
    inverse_layer_2(coefficients);
    inverse_layer_1(coefficients);
    reduce_coefficients(coefficients, mod);
}

int main()
{
    /* Compute the iterative inplace forward NTT of poly_one, poly_two */
    forward_ntt(poly_one, VAR_Q);
    forward_ntt(poly_two, VAR_Q);

    /* Print the forward NTT values */
    printf("%s\n", "The forward values are:");
    print_polynomial(poly_one);
    print_polynomial(poly_two);
    printf("\n");

    /* Compute the point-wise multiplication of the integer coefficients */
    /* Note that we are using poly_one to store the result */
    /* FIXME : Make sure the result fits inside uint32_t */
    multiplication(poly_one, poly_one, poly_two, VAR_Q);

    /* Print the point-wise multiplied values */
    printf("%s\n", "The point-wise multiplied values are:");
    print_polynomial(poly_one);
    printf("\n");

    /* Compute the iterative inplace inverse NTT of poly_one */
    inverse_ntt(poly_one, VAR_Q);

    /* Print the inverse NTT values, i.e. the result */
    printf("%s\n", "The inverse values, i.e. the result, are:");
    print_polynomial(poly_one);
    printf("\n");

    return 0;
}
