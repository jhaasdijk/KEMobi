#include "size008.h"

/*
 * Instead of defining a custom type for representing polynomials, each
 * polynomial is represented using an array of its integer coefficients. For
 * instance {1, 2, 3} represents the polynomial 3x^2 + 2x + 1. Each coefficient
 * is represented as a signed 8 bit integer (int8_t). This makes it easier to
 * identify and use numeric types properly instead of hiding what types are
 * being used under the hood.
 * 
 * Since the modulus VAR_Q (17) defines that the largest integer coefficient can
 * be 16, we know that integer values are at most 5 bits long. We can use this
 * information in our choice for numeric types.
 */

/**
 * . per-layer foward | per-layer inverse
 * TODO : What happens when we do int16_t - int8_t (see e.g. forward layers)
 * TODO : Recheck the per-layer functions for proper typing ^
 * TODO : Verify inverse (inverse_layer_3, inverse_layer_2, inverse_layer_1)
 * TODO : Verify forward (forward_layer_1, forward_layer_2, forward_layer_3)
 * 
 * . modulo
 * TODO : what happens when we modulo a int8_t by uint8_t. It might be better to
 * pick one 'signed-ness' and just roll with it
 * 
 * . inverse bundled
 * TODO : fix the call the (unused) reduce_coefficients
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
    for (size_t i = 0; i < VAR_P; i++)
    {
        printf(" %*d", 2, coefficients[i]);
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
 * are going to use is 6984193. We can therefore simply use uint8_t.
 * 
 * @param[in] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void reduce_coefficients(int8_t *coefficients, uint8_t mod)
{
    for (size_t i = 0; i < VAR_P; i++)
    {
        coefficients[i] = modulo(coefficients[i], mod);
    }
}

void forward_layer_1(int8_t *coefficients)
{
    unsigned int length = 4, ridx = 0;
    int16_t temp;

    int8_t zeta = roots[ridx];

    for (size_t i = 0; i < length; i++)
    {
        temp = (int16_t)zeta * coefficients[i + length];
        coefficients[i + length] = coefficients[i] - temp;
        coefficients[i] = coefficients[i] + temp;
    }
}

void forward_layer_2(int8_t *coefficients)
{
    unsigned int length = 2, ridx = 1;
    unsigned int start, idx;
    int16_t temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        int8_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = (int16_t)zeta * coefficients[idx + length];
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void forward_layer_3(int8_t *coefficients)
{
    unsigned int length = 1, ridx = 3;
    unsigned int start, idx;
    int16_t temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        int8_t zeta = roots[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = (int16_t)zeta * coefficients[idx + length];
            // printf("temp : %d\n", temp);
            coefficients[idx + length] = coefficients[idx] - temp;
            coefficients[idx] = coefficients[idx] + temp;
        }
    }
}

void inverse_layer_3(int8_t *coefficients)
{
    unsigned int length = 1, ridx = 0;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        int8_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = coefficients[idx + length] * zeta;
        }
    }
}

void inverse_layer_2(int8_t *coefficients)
{
    unsigned int length = 2, ridx = 4;
    unsigned int start, idx;
    int temp;

    for (start = 0; start < VAR_P; start = idx + length)
    {
        int8_t zeta = roots_inv[ridx];
        ridx = ridx + 1;

        for (idx = start; idx < start + length; idx++)
        {
            temp = coefficients[idx];
            coefficients[idx] = temp + coefficients[idx + length];
            coefficients[idx + length] = temp - coefficients[idx + length];
            coefficients[idx + length] = coefficients[idx + length] * zeta;
        }
    }
}

void inverse_layer_1(int8_t *coefficients)
{
    unsigned int length = 4, ridx = 6;
    int temp;

    int8_t zeta = roots_inv[ridx];

    for (size_t i = 0; i < length; i++)
    {
        temp = coefficients[i];
        coefficients[i] = temp + coefficients[i + length];
        coefficients[i + length] = temp - coefficients[i + length];
        coefficients[i + length] = coefficients[i + length] * zeta;
    }

    /*
     * Multiply the result with the accumulated factor to complete the inverse
     * NTT transform. We can calculate this factor by computing 2^{-lay} mod q,
     * where lay is equal to the number of layers.
     */
    uint8_t factor = 15;
    uint16_t asd = 0;

    for (size_t i = 0; i < VAR_P; i++)
    {
        // TODO : Clear this up
        printf("%d, ", coefficients[i]);
        coefficients[i] = modulo(coefficients[i], VAR_Q);
        asd = (uint16_t)coefficients[i] * factor;
        coefficients[i] = modulo(asd, VAR_Q);
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
 * @param[in] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void forward_ntt(int8_t *coefficients, uint8_t mod)
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
 * @param[in] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void inverse_ntt(int8_t *coefficients, uint8_t mod)
{
    inverse_layer_3(coefficients);
    inverse_layer_2(coefficients);
    inverse_layer_1(coefficients);
    // reduce_coefficients(coefficients, mod);
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
     * Since we are multiplying two 8 bit values we need a temporary 16 bit
     * value to store the intermediate result. We then reduce this back to an 8
     * bit value with VAR_Q
     */

    int16_t temporary;
    int8_t poly_out[VAR_P] = {0, 0, 0, 0, 0, 0, 0, 0};

    for (size_t idx = 0; idx < VAR_P; idx++)
    {
        /* Compute the point-wise multiplication */
        temporary = (int16_t)poly_one[idx] * poly_two[idx];

        /* Reduce the integer coefficients */
        poly_out[idx] = (int8_t)modulo(temporary, VAR_Q);
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
