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
 * @brief Sort an array of 64 bit unsigned integers.
 *
 * @details This function can be used to sort an array of 64 bit unsigned
 * integers. It's used to get easy access to the MIN, MAX, MED values in our
 * benchmarking.
 *
 * @note This is not the fastest method of sorting, but that's okay.
 *
 * @param[in] arr An unsorted array of 64 bit unsigned integers.
 */
void sort(uint64_t *arr)
{
    uint64_t temp;

    for (size_t i = 0; i < NTESTS; i++)
    {
        for (size_t j = 0; j < NTESTS - 1; j++)
        {
            if (arr[j] > arr[j + 1])
            {
                temp = arr[j];
                arr[j] = arr[j + 1];
                arr[j + 1] = temp;
            }
        }
    }
}

/**
 * @brief Compute the median from a sorted array of 64 bit unsigned integers.
 *
 * @details To compute the median we simply have to take the 'middle' value.
 * When the number of elements is odd there is only one such element. When the
 * number of elements is even there are two middle elements, thus we take their
 * sum and divide by two.
 *
 * @param[in] arr A sorted array of 64 bit unsigned integers.
 *
 * @return The computed median.
 */
uint64_t median(uint64_t *arr)
{
    if (NTESTS % 2 == 0)
    {
        double median = (double)(arr[NTESTS / 2] + arr[(NTESTS - 1) / 2]) / 2;
        return (uint64_t)ceil(median); // No such thing as half a cycle ..
    }
    else
    {
        return arr[NTESTS / 2];
    }
}

/**
 * @brief Compute and print benchmark related information.
 *
 * @details This function can be used to compute and print the MIN, MAX, MED
 * cycle counts of the performed tests.
 *
 * @param[in] arr The 'raw' list of values read from the processor cycle
 * counter.
 */
void benchmark(uint64_t *arr, char *preface)
{
    for (size_t i = 0; i < NTESTS - 1; i++)
    {
        arr[i] = arr[i + 1] - arr[i];
    }

    sort(arr);

    printf("| " CYAN "%-21s" RESET "| ", preface);
    // printf("min: %ld \t| ", arr[0]);
    // printf("max: %ld \t| ", arr[NTESTS - 2]);
    printf("med: %ld \t|\n", median(arr));
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
 * @param[out] padded Zero padded array of integer coefficients of size 1536.
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
 * @brief Modulo operator that calculates the remainder after Euclidean
 * division.
 *
 * @details This snippet has been adapted from the following Stack Overflow
 * answer: https://stackoverflow.com/a/52529440.
 *
 * @param[in] value Integer value that needs to be reduced.
 * @param[in] mod The modulus with which to reduce the integer value.
 *
 * @return The remainder after Euclidean division.
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
 * @param[in] x The first input factor.
 * @param[in] y The second input factor.
 * @param[in] mod The modulo used to reduce the result.
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
 * @brief Reduce a polynomial mod (x^761 - x - 1).
 *
 * @details This function can be used to reduce a polynomial. It takes an array
 * of integer coefficients of size 1536 and reduces this mod (x^761 - x - 1),
 * i.e. x^761 = x + 1. This is done by adding coefficients[idx] into
 * coefficients[1] and coefficients[0] whenever coefficients[idx] is nonzero.
 *
 * @param[in, out] coefficients An array of integer coefficients (i.e. a
 * polynomial).
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
