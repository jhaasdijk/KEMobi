#include "ntt.h"

/**
 * This source can be used to perform the forward and inverse iterative inplace
 * NTT transformations. It defines per-layer transformations as well as an easy
 * to use wrapper for both the forward and inverse NTT.
 */

void forward_layer_8(int32_t *coefficients)
{
    unsigned int ridx = 127;

    for (size_t idx = 0; idx < 512; idx = idx + 8)
    {
        /* Load the required (precomputed) roots */

        int32_t zeta64 = roots[ridx++];
        int32_t zeta128 = roots[ridx++];

        /* Execute 4 multiply_reduce operations */

        int32_t temp_32 = multiply_reduce(zeta64, coefficients[idx + 2]);
        int32_t temp_64 = multiply_reduce(zeta64, coefficients[idx + 3]);
        int32_t temp_96 = multiply_reduce(zeta128, coefficients[idx + 6]);
        int32_t temp_128 = multiply_reduce(zeta128, coefficients[idx + 7]);

        /* Execute 4 subtractions and 4 additions */

        coefficients[idx + 2] = coefficients[idx + 0] - temp_32;
        coefficients[idx + 3] = coefficients[idx + 1] - temp_64;
        coefficients[idx + 6] = coefficients[idx + 4] - temp_96;
        coefficients[idx + 7] = coefficients[idx + 5] - temp_128;

        coefficients[idx + 0] = coefficients[idx + 0] + temp_32;
        coefficients[idx + 1] = coefficients[idx + 1] + temp_64;
        coefficients[idx + 4] = coefficients[idx + 4] + temp_96;
        coefficients[idx + 5] = coefficients[idx + 5] + temp_128;
    }
}

void forward_layer_9(int32_t *coefficients)
{
    unsigned int ridx = 255;

    for (size_t idx = 0; idx < 512; idx = idx + 8)
    {
        /* Load the required (precomputed) roots */

        int32_t zeta_32 = roots[ridx++];
        int32_t zeta_64 = roots[ridx++];
        int32_t zeta_96 = roots[ridx++];
        int32_t zeta_128 = roots[ridx++];

        /* Execute 4 multiply_reduce operations */

        int32_t temp_32 = multiply_reduce(zeta_32, coefficients[idx + 1]);
        int32_t temp_64 = multiply_reduce(zeta_64, coefficients[idx + 3]);
        int32_t temp_96 = multiply_reduce(zeta_96, coefficients[idx + 5]);
        int32_t temp_128 = multiply_reduce(zeta_128, coefficients[idx + 7]);

        /* Execute 4 subtractions and 4 additions */

        coefficients[idx + 1] = coefficients[idx + 0] - temp_32;
        coefficients[idx + 3] = coefficients[idx + 2] - temp_64;
        coefficients[idx + 5] = coefficients[idx + 4] - temp_96;
        coefficients[idx + 7] = coefficients[idx + 6] - temp_128;

        coefficients[idx + 0] = coefficients[idx + 0] + temp_32;
        coefficients[idx + 2] = coefficients[idx + 2] + temp_64;
        coefficients[idx + 4] = coefficients[idx + 4] + temp_96;
        coefficients[idx + 6] = coefficients[idx + 6] + temp_128;
    }
}

void inverse_layer_9(int32_t *coefficients)
{
    unsigned int ridx = 0;

    for (size_t idx = 0; idx < 512; idx = idx + 8)
    {
        /* Load the required (precomputed) roots */

        int32_t zeta_32 = roots_inv[ridx++];
        int32_t zeta_64 = roots_inv[ridx++];
        int32_t zeta_96 = roots_inv[ridx++];
        int32_t zeta_128 = roots_inv[ridx++];

        int32_t temp_32 = coefficients[idx + 0];
        int32_t temp_64 = coefficients[idx + 2];
        int32_t temp_96 = coefficients[idx + 4];
        int32_t temp_128 = coefficients[idx + 6];

        /* Execute 4 additions and 4 subtractions */

        coefficients[idx + 0] = temp_32 + coefficients[idx + 1];
        coefficients[idx + 2] = temp_64 + coefficients[idx + 3];
        coefficients[idx + 4] = temp_96 + coefficients[idx + 5];
        coefficients[idx + 6] = temp_128 + coefficients[idx + 7];

        coefficients[idx + 1] = temp_32 - coefficients[idx + 1];
        coefficients[idx + 3] = temp_64 - coefficients[idx + 3];
        coefficients[idx + 5] = temp_96 - coefficients[idx + 5];
        coefficients[idx + 7] = temp_128 - coefficients[idx + 7];

        /* Execute 4 multiply_reduce operations */

        coefficients[idx + 1] = multiply_reduce(zeta_32, coefficients[idx + 1]);
        coefficients[idx + 3] = multiply_reduce(zeta_64, coefficients[idx + 3]);
        coefficients[idx + 5] = multiply_reduce(zeta_96, coefficients[idx + 5]);
        coefficients[idx + 7] = multiply_reduce(zeta_128, coefficients[idx + 7]);
    }
}

void inverse_layer_8(int32_t *coefficients)
{
    unsigned int ridx = 256;

    for (size_t idx = 0; idx < 512; idx = idx + 8)
    {
        /* Load the required (precomputed) roots */

        int32_t zeta_32 = roots_inv[ridx++];
        int32_t zeta_64 = roots_inv[ridx++];

        int32_t temp_32 = coefficients[idx + 0];
        int32_t temp_64 = coefficients[idx + 1];
        int32_t temp_96 = coefficients[idx + 4];
        int32_t temp_128 = coefficients[idx + 5];

        /* Execute 4 additions and 4 subtractions */

        coefficients[idx + 0] = temp_32 + coefficients[idx + 2];
        coefficients[idx + 1] = temp_64 + coefficients[idx + 3];
        coefficients[idx + 4] = temp_96 + coefficients[idx + 6];
        coefficients[idx + 5] = temp_128 + coefficients[idx + 7];

        coefficients[idx + 2] = temp_32 - coefficients[idx + 2];
        coefficients[idx + 3] = temp_64 - coefficients[idx + 3];
        coefficients[idx + 6] = temp_96 - coefficients[idx + 6];
        coefficients[idx + 7] = temp_128 - coefficients[idx + 7];

        /* Execute 4 multiply_reduce operations */

        coefficients[idx + 2] = multiply_reduce(zeta_32, coefficients[idx + 2]);
        coefficients[idx + 3] = multiply_reduce(zeta_32, coefficients[idx + 3]);
        coefficients[idx + 6] = multiply_reduce(zeta_64, coefficients[idx + 6]);
        coefficients[idx + 7] = multiply_reduce(zeta_64, coefficients[idx + 7]);
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
    __asm_ntt_forward_setup();

    __asm_ntt_forward_layer_1(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_2(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_3(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_4(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_5(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_6(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_7(coefficients, MR_top, MR_bot);
    // __asm_ntt_forward_layer_8(coefficients, MR_top, MR_bot);
    // __asm_ntt_forward_layer_9(coefficients, MR_top, MR_bot);
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
