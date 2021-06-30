#include "speed_util.h"

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

    printf("| " CYAN "%-41s" RESET "| ", preface);
    printf("med: %ld   \t|\n", median(arr));
    // printf("| " CYAN "%-28s" RESET "| ", preface);
    // printf("min: %ld | ", arr[0]);
    // printf("max: %ld | ", arr[NTESTS - 2]);
    // printf("med: %ld |\n", median(arr));
}
