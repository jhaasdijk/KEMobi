#include "size008.h"

/*
 * Instead of defining a custom type for representing polynomials, each
 * polynomial is represented using an array of its integer coefficients. For
 * instance {1, 2, 3} represents the polynomial 3x^2 + 2x + 1. Each coefficient
 * is represented as a signed 8 bit integer (int8_t). This makes it easier to
 * identify and use numeric types properly instead of hiding what types are
 * being used under the hood.
 * 
 * Since the modulus Q (17) defines that the largest integer coefficient can be
 * 16, we know that integer values are at most 5 bits long. We can use this
 * information in our choice for numeric types.
 */

/**
 * @brief Print an array of integer coefficients (i.e. a polynomial).
 * 
 * @details This function can be used to print a polynomial that is being
 * represented by an array of its coefficients to stdout. Numeric values are
 * printed with a specified column width of 2. This makes it easier to compare
 * output of different runs.
 * 
 * @param[in] coefficients An array of integer coefficients (i.e. a polynomial).
 */
void print_polynomial(int8_t *coefficients)
{
    for (size_t idx = 0; idx < VAR_P; idx++)
    {
        printf(" %*d", 2, coefficients[idx]);
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
int modulo(int value, int mod)
{
    int remainder = value % mod;
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
 * are going to use is 17. We can therefore simply use int8_t.
 * 
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void reduce_coefficients(int8_t *coefficients, int8_t mod)
{
    for (size_t idx = 0; idx < VAR_P; idx++)
    {
        coefficients[idx] = modulo(coefficients[idx], mod);
    }
}

/**
 * @brief Montgomery reduction of the input.
 * 
 * @details Given a 16 bit integer this function can be used to compute an 8 bit
 * integer congruent to x * 256^-1 modulo VAR_Q.
 * 
 * @note A cool side effect of our choice for VAR_Q (17) is that we can use the
 * Montgomery reduction without having to explicitly change our values into the
 * Montgomery domain. Normally when using the Montgomery reduction we would need
 * to bring our value into the Montgomery domain by multiplying it with 2^8 % 17
 * to ensure that x * (2^8)^-1 modulo VAR_Q computes the correct result. However
 * since 2^8 % 17 is equal to 1, updating values into the Montgomery domain
 * would be the same as multiplying them by 1. We can therefore use this 'for
 * free'.
 * 
 * @param[in] x The input integer value that needs to be reduced
 * 
 * @return Integer in {-Q + 1, ..., Q - 1} congruent to x * 256^-1 modulo VAR_Q.
 */
int8_t montgomery_reduce(int16_t x)
{
    int8_t out;
    out = (int8_t)x * INV_Q;
    out = (x - (int16_t)out * VAR_Q) >> 8;
    return out;
}

/**
 * @brief Multiply the inputs and reduce the result using Montgomery reduction.
 * 
 * @details This function can be used to multiply two inputs x and y and reduce
 * the result using Montgomery reduction. 
 * 
 * @param[in] x The first input factor
 * @param[in] y The second input factor
 * 
 * @return Integer congruent to x * y * 256^-1 modulo VAR_Q
 */
int8_t multiply_reduce(int8_t x, int8_t y)
{
    return montgomery_reduce((int16_t)x * y);
}

void forward_layer_1(int8_t *coefficients)
{
    unsigned int length = 4, ridx = 0;
    unsigned int idx;
    int8_t temp, zeta;

    zeta = roots[ridx];

    for (idx = 0; idx < length; idx++)
    {
        temp = multiply_reduce(zeta, coefficients[idx + length]);
        coefficients[idx + length] = coefficients[idx] - temp;
        coefficients[idx] = coefficients[idx] + temp;
    }
}

void forward_layer_2(int8_t *coefficients)
{
    unsigned int length = 2, ridx = 1;
    unsigned int start, idx;
    int8_t temp, zeta;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_3(int8_t *coefficients)
{
    unsigned int length = 1, ridx = 3;
    unsigned int start, idx;
    int8_t temp, zeta;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = multiply_reduce(zeta, coefficients[idx + length]);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void inverse_layer_3(int8_t *coefficients)
{
    unsigned int length = 1, ridx = 0;
    unsigned int start, idx;
    int8_t temp, zeta;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        zeta = roots_inv[ridx];
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

void inverse_layer_2(int8_t *coefficients)
{
    unsigned int length = 2, ridx = 4;
    unsigned int start, idx;
    int8_t temp, zeta;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        zeta = roots_inv[ridx];
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

void inverse_layer_1(int8_t *coefficients)
{
    unsigned int length = 4, ridx = 6;
    int8_t temp, zeta;

    zeta = roots_inv[ridx];

    for (size_t idx = 0; idx < length; idx++)
    {
        temp = coefficients[idx];
        coefficients[idx] = temp + coefficients[idx + length];
        coefficients[idx + length] = temp - coefficients[idx + length];
        coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
    }

    /*
     * Multiply the result with the accumulated factor to complete the inverse
     * NTT transform. We can calculate this factor by computing 2^{-lay} mod q,
     * where lay is equal to the number of layers. 2^-3 = 8^-1 mod 17 = 15
     */
    int8_t factor = 15;

    for (size_t idx = 0; idx < VAR_P; idx++)
    {
        coefficients[idx] = multiply_reduce(coefficients[idx], factor);
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
void forward_ntt(int8_t *coefficients, int8_t mod)
{
    forward_layer_1(coefficients);
    forward_layer_2(coefficients);
    forward_layer_3(coefficients);
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
void inverse_ntt(int8_t *coefficients, int8_t mod)
{
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

    forward_ntt(poly_one, VAR_Q);
    forward_ntt(poly_two, VAR_Q);

    /**
     * @brief Compute the point-wise multiplication of the integer coefficients
     * 
     * The following is used to perform the point-wise multiplication of the
     * integer coefficients of two polynomials and store the (reduced) result.
     * Please note that we did not have to declare a new array, we could have
     * simply reused either poly_one or poly_two. To improve readability
     * however, a new array poly_out is introduced.
     */

    int8_t poly_out[VAR_P];

    for (size_t idx = 0; idx < VAR_P; idx++)
    {
        poly_out[idx] = multiply_reduce(poly_one[idx], poly_two[idx]);
    }

    /**
     * @brief Compute the iterative inplace inverse NTT of poly_out
     */

    inverse_ntt(poly_out, VAR_Q);

    /**
     * @brief Test the result of the computation against the known test values
     */

    for (size_t idx = 0; idx < VAR_P; idx++)
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
