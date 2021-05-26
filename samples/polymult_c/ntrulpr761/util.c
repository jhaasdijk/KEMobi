#include "util.h"

/**
 * This source can be used to contain various helpers functions that are called
 * throughout the implementation.
 */

/**
 * @brief Read the current value from the PMCCNTR_EL0 System register.
 *
 * @details For benchmarking purposes we are interested in the CPU cycle count
 * as a performance metric. This function can be used to read from the
 * PMCCNTR_EL0 System register and return the current value of the processor
 * cycle counter.
 *
 * @note We use the inline keyword to ask the compiler to attempt to embed the
 * function's content into the calling code instead of executing a function
 * call. There are no guarantees as to whether this actually happpens though.
 * The compiler may choose to ignore it.
 *
 * @return The current value of the processor cycle counter.
 */
inline uint64_t counter_read(void)
{
    uint64_t counter = 0;
    asm volatile("MRS %0, PMCCNTR_EL0"
                 : "=r"(counter));
    return counter;
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
        printf(" %d,", coefficients[idx]);
    }
    printf("\n");
}

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
    int32_t remainder = (int32_t)(value % mod);
    if (remainder < 0)
    {
        remainder = (mod < 0) ? remainder - mod : remainder + mod;
    }
    return remainder;
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
    out = (int32_t)((x - (int64_t)out * NTT_Q) >> 32);
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
 * @brief Reduce a polynomial mod (x^761 - x - 1).
 *
 * @details This function can be used to reduce a polynomial. It takes an array
 * of integer coefficients of size 1536 and reduces this mod (x^761 - x - 1),
 * i.e. x^761 = x + 1. This is done by adding coefficients[idx] into
 * coefficients[1] and coefficients[0] whenever coefficients[idx] is nonzero.
 *
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 */
void reduce_terms_761(int32_t *coefficients)
{
    for (size_t idx = GPR - 1; idx >= NTRU_P; idx--)
    {
        if (coefficients[idx] > 0)
        {                                                        /* x^p is nonzero */
            coefficients[idx - NTRU_P + 1] += coefficients[idx]; /* add x^p into x^1 */
            coefficients[idx - NTRU_P] += coefficients[idx];     /* add x^p into x^0 */
            coefficients[idx] = 0;                               /* zero x^p */
        }
    }
}
