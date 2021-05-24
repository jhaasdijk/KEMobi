#include "ntt.h"

/**
 * This source can be used to perform the forward and inverse iterative inplace
 * NTT transformations. It defines per-layer transformations as well as an easy
 * to use wrapper for both the forward and inverse NTT.
 */

void forward_layer_2(int32_t *coefficients)
{
    unsigned int length = 128, ridx = 1;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_3(int32_t *coefficients)
{
    unsigned int length = 64, ridx = 3;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_4(int32_t *coefficients)
{
    unsigned int length = 32, ridx = 7;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_5(int32_t *coefficients)
{
    unsigned int length = 16, ridx = 15;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_6(int32_t *coefficients)
{
    unsigned int length = 8, ridx = 31;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_7(int32_t *coefficients)
{
    unsigned int length = 4, ridx = 63;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_8(int32_t *coefficients)
{
    unsigned int length = 2, ridx = 127;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_9(int32_t *coefficients)
{
    unsigned int length = 1, ridx = 255;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void inverse_layer_9(int32_t *coefficients)
{
    unsigned int length = 1, ridx = 0;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_8(int32_t *coefficients)
{
    unsigned int length = 2, ridx = 256;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_7(int32_t *coefficients)
{
    unsigned int length = 4, ridx = 384;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_6(int32_t *coefficients)
{
    unsigned int length = 8, ridx = 448;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_5(int32_t *coefficients)
{
    unsigned int length = 16, ridx = 480;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_4(int32_t *coefficients)
{
    unsigned int length = 32, ridx = 496;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_3(int32_t *coefficients)
{
    unsigned int length = 64, ridx = 504;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_2(int32_t *coefficients)
{
    unsigned int length = 128, ridx = 508;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < NTT_P; start = idx + length)
    {
        int32_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
        }
    }
}

void inverse_layer_1(int32_t *coefficients)
{
    unsigned int length = 256, ridx = 510;
    int temp;

    int32_t zeta = roots_inv[ridx];

    for (size_t idx = 0; idx < length; idx++)
    {
        temp = coefficients[idx];
        coefficients[idx] = temp + coefficients[idx + length];
        coefficients[idx + length] = temp - coefficients[idx + length];
        coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
    }

    /*
     * Multiply the result with the accumulated factor to complete the inverse
     * NTT transformation
     */

    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        coefficients[idx] = multiply_reduce(FACTOR, coefficients[idx]);
    }
}

/**
 * @brief Compute the iterative inplace forward NTT of a polynomial.
 * 
 * @details This function can be used to compute the iterative inplace forward
 * NTT of a polynomial represented by its integer coefficients. It wraps the
 * earlier defined per-layer forward transformations into a single, easy to use
 * function.
 * 
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void ntt_forward(int32_t *coefficients, int32_t mod)
{
    forward_layer_1(coefficients);
    forward_layer_2(coefficients);
    forward_layer_3(coefficients);
    forward_layer_4(coefficients);
    forward_layer_5(coefficients);
    forward_layer_6(coefficients);
    forward_layer_7(coefficients);
    forward_layer_8(coefficients);
    forward_layer_9(coefficients);
    reduce_coefficients(coefficients, mod);
}

/**
 * @brief Compute the iterative inplace inverse NTT of a polynomial.
 * 
 * @details This function can be used to compute the iterative inplace inverse
 * NTT of a polynomial represented by its integer coefficients. It wraps the
 * earlier defined per-layer inverse transformations into a single, easy to use
 * function.
 * 
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void ntt_inverse(int32_t *coefficients, int32_t mod)
{
    inverse_layer_9(coefficients);
    inverse_layer_8(coefficients);
    inverse_layer_7(coefficients);
    inverse_layer_6(coefficients);
    inverse_layer_5(coefficients);

    /**
     * @brief Ensure that the coefficients stay within their allocated 32 bits
     * 
     * Due to how the inverse NTT transformation is calculated, each layer
     * increases the possible bitsize of the integer coefficients by 1.
     * Performing 9 layers increases the possible bitsize of the integer
     * coefficients by 9. To ensure that the integer coefficients stay within
     * their allocated 32 bits we either 1) need to ensure that all values are
     * at most 23 bits at the start of the function or 2) perform an
     * intermediate reduction.
     */

    reduce_coefficients(coefficients, mod);

    inverse_layer_4(coefficients);
    inverse_layer_3(coefficients);
    inverse_layer_2(coefficients);
    inverse_layer_1(coefficients);
    reduce_coefficients(coefficients, mod);
}
