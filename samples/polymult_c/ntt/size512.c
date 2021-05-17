#include "size512.h"

/**
 * @brief Perform NTT based polynomial multiplication
 * 
 * @details This source can be used to perform NTT based polynomial
 * multiplication of two polynomials for the NTRU LPRime 'kem/ntrulpr761'
 * parameter set.
 * 
 * @note While 761 is not an NTT friendly prime and the reduction polynomial is
 * not of the form x^n + 1 or x^n - 1, we can use Good's permutation after
 * padding to size 1536 to perform 3 size 512 NTTs instead.  These smaller size
 * 512 cyclic NTTs are used to multiply polynomials in Z_6984193 [x] / (x^512 -
 * 1).
 * 
 * @note Instead of defining a custom type for representing polynomials, each
 * polynomial is represented using an array of its integer coefficients. For
 * instance {1, 2, 3} represents the polynomial 3x^2 + 2x + 1. Each coefficient
 * is represented as signed 32 bit integer (int32_t). This makes it easier to
 * identify and use numeric types properly instead of hiding what types are
 * being used under the hood.
 * 
 * @note Since the modulus Q (6984193) defines that the largest integer
 * coefficient can be 6984192, we know that integer values are at most 23 bits
 * long. We can use this information in our choice for numeric types.
 * 
 * @note Please be aware that in NTRU LPRime one of the multiplicands for the
 * polynomial multiplications is always small/short, i.e., has only coefficients
 * in {-1, 0, 1}. We can use this information in our choice for bounds and
 * sizes.
 */

/**
 * TODO : Move this 512 example into its own place. It's the only one we are
 * considering in the end.
 * 
 * TODO : Extract pieces into other (helper) files to ensure that the source
 * remains readable. E.g. Goods | NTT | Util | ...
 * 
 * TODO : Are there functions that we can de-generalize? While the Python
 * implementation is great as a general approach this C source is used only for
 * the kem/ntrulpr761 parameter set.
 * 
 * TODO : We are working with size 512, 761 and 1536 arrays of integer
 * coefficients. Can we think of something such that we do not need to hardcode
 * this or specify the size at every function call?
 */

/**
 * @brief Zero pad an array of integer coefficients to the specified size.
 * 
 * @details This function can be used to zero pad an array of integer
 * coefficients (i.e. a polynomial) of size 761 to size 1536. This makes it
 * suitable to use in the Good's permutation.
 * 
 * @param[out] padded Zero padded array of integer coefficients of size 1536
 * @param[in] coefficients An array of integer coefficients (i.e. a polynomial).
 */
void pad(int32_t *padded, int32_t *coefficients)
{
    unsigned int idx = 0;

    /* Copy the original values */
    for (; idx < NTRU_P; idx++)
    {
        padded[idx] = coefficients[idx];
    }

    /* Initialize the remaining positions with 0 */
    for (; idx < GPR; idx++)
    {
        padded[idx] = 0;
    }
}

/**
 * @brief Perform the forward Good's permutation.
 * 
 * @details This function can be used to deconstruct an array of integer
 * coefficients into smaller NTT friendly sizes. Currently this function is used
 * to deconstruct a size-GPR array into GP0 size-GP1 NTTs.
 * 
 * @param[out] forward Deconstructed smaller NTT friendly GP0xGP1 matrix.
 * @param[in] coefficients Zero padded array of integer coefficients. 
 */
void goods_forward(int32_t forward[GP0][GP1], int32_t *coefficients)
{
    unsigned int idx = 0, ntt = 0, coef = 0;

    for (idx = 0; idx < GPR; idx++)
    {
        /* Determine in which NTT the coefficient ends up */
        ntt = idx % GP0;

        /* Determine which integer coefficient is used */
        coef = idx % GP1;

        forward[ntt][coef] = coefficients[idx];
    }
}

/**
 * @brief Perform the inverse Good's permutation.
 * 
 * @details This function can be used to construct an array of integer
 * coefficients from a deconstructed smaller NTT friendly matrix. Currently this
 * function is used to construct a size-GPR array from GP0 size-GP1 NTTs.
 * 
 * @param[out] coefficients Zero padded array of integer coefficients. 
 * @param[in] forward Deconstructed smaller NTT friendly GP0xGP1 matrix.
 */
void goods_inverse(int32_t *coefficients, int32_t forward[GP0][GP1])
{
    unsigned int idx = 0, ntt = 0, coef = 0;

    for (idx = 0; idx < GPR; idx++)
    {
        /* Determine in which NTT the coefficient has ended up */
        ntt = idx % GP0;

        /* Determine which integer coefficient was used */
        coef = idx % GP1;

        coefficients[idx] = forward[ntt][coef];
    }
}

/**
 * @brief Print an array of integer coefficients (i.e. a polynomial).
 * 
 * @details This function can be used to print a polynomial that is being
 * represented by an array of its coefficients to stdout. Since the number of
 * elements in the array is not always the same this function expects it as an
 * argument.
 * 
 * @note The largest size array of integer coefficients we expect to be working
 * with is 1536. The numeric type int16_t is therefore sufficient.
 * 
 * @param[in] coefficients An array of integer coefficients (i.e. a polynomial).
 * @param[in] size Number of elements in the array of integer coefficients.
 */
void print_polynomial(int32_t *coefficients, int16_t size)
{
    for (int idx = 0; idx < size; idx++)
    {
        printf(" %d", coefficients[idx]);
    }
    printf("\n");
}

/**
 * @brief Modulo operator that calculates the remainder after Euclidean division
 * 
 * @details This snippet has been adapted from the following Stack Overflow
 * answer: https://stackoverflow.com/a/52529440
 * 
 * @param[in] value Integer value that needs to be reduced
 * @param[in] mod The modulus with which to reduce the integer value
 * 
 * @return The remainder after Euclidean division
 */
int32_t modulo(int64_t value, int32_t mod)
{
    int32_t remainder = value % mod;
    if (remainder < 0)
    {
        remainder = (mod < 0) ? remainder - mod : remainder + mod;
    }
    return remainder;
}

/**
 * @brief Reduce a polynomial's integer coefficients.
 * 
 * @details This function can be used to reduce a polynomial's integer
 * coefficients. The modulus will always be positive and the largest value we
 * are going to use is 6984193. We can therefore simply use int32_t.
 * 
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void reduce_coefficients(int32_t *coefficients, int32_t mod)
{
    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        coefficients[idx] = modulo(coefficients[idx], mod);
    }
}

/**
 * @brief Montgomery reduction of the input.
 * 
 * @details Given a 64 bit integer this function can be used to compute a 32 bit
 * integer congruent to x * (2^32)^-1 modulo NTT_Q.
 * 
 * @param[in] x The input integer value that needs to be reduced
 * 
 * @return Integer in {-Q + 1, ..., Q - 1} congruent to x * (2^32)^-1 modulo NTT_Q.
 */
int32_t montgomery_reduce(int64_t x)
{
    int32_t out;
    out = (int32_t)x * NTT_QINV;
    out = (x - (int64_t)out * NTT_Q) >> 32;
    return out;
}

/**
 * @brief Multiply the inputs and reduce the result using Montgomery reduction.
 * 
 * @details This function can be used to multiply two inputs x and y and reduce
 * the result using Montgomery reduction. Note that this does require that one
 * of the multiplicands is in the Montgomery domain.
 * 
 * @param[in] x The first input factor
 * @param[in] y The second input factor
 * 
 * @return Integer congruent to x * y * (2^32)^-1 modulo NTT_Q
 */
int32_t multiply_reduce(int32_t x, int32_t y)
{
    return montgomery_reduce((int64_t)x * y);
}

/**
 * @brief Multiply the inputs and reduce the result using modular reduction.
 * 
 * @details This function can be used to perform modular multiplication of two
 * inputs x and y. The result is reduced using the remainder after Euclidean
 * division (modulo).
 * 
 * @param[in] x The first input factor
 * @param[in] y The second input factor
 * @param[in] mod The modulo used to reduce the result
 * 
 * @return The result of (x * y) % mod
 */
int32_t multiply_modulo(int32_t x, int32_t y, int32_t mod)
{
    int64_t value = (int64_t)x * y;
    int32_t out = modulo(value, mod);
    return out;
}

void forward_layer_1(int32_t *coefficients)
{
    unsigned int length = 256, ridx = 0;
    int temp;

    int32_t zeta = roots[ridx];

    for (size_t idx = 0; idx < length; idx++)
    {
        temp = multiply_reduce(zeta, coefficients[idx + length]);
        coefficients[idx + length] = coefficients[idx] - temp;
        coefficients[idx] = coefficients[idx] + temp;
    }
}

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
 * eaerlier defined per-layer inverse transformations into a single, easy to use
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
    inverse_layer_4(coefficients);
    inverse_layer_3(coefficients);
    inverse_layer_2(coefficients);
    inverse_layer_1(coefficients);
    reduce_coefficients(coefficients, mod);
}

int main()
{
    /**
     * @brief Compute the iterative inplace forward NTT of poly_one, poly_two
     */

    ntt_forward(poly_one, NTT_Q);
    ntt_forward(poly_two, NTT_Q);

    /**
     * @brief Compute the point-wise multiplication of the integer coefficients
     * 
     * The following is used to perform the point-wise multiplication of the
     * integer coefficients of two polynomials and store the (reduced) result.
     * Please note that we did not have to declare a new array, we could have
     * simply reused either poly_one or poly_two. To improve readability
     * however, a new array poly_out is introduced.
     */

    int32_t poly_out[NTT_P];

    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        poly_out[idx] = multiply_modulo(poly_one[idx], poly_two[idx], NTT_Q);
    }

    /**
     * @brief Compute the iterative inplace inverse NTT of poly_out
     */

    ntt_inverse(poly_out, NTT_Q);

    /**
     * @brief Test the result of the computation against the known test values
     */

    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        if (poly_out[idx] != result[idx])
        {
            printf("%s\n", "This is not correct!");
            printf("%s%ld\n", "Error at index: ", idx);
            return -1;
        }
    }

    printf("%s\n", "This is correct!");
    return 0;
}
