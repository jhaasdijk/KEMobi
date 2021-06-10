#include "main512.h"

/**
 * This source can be used to perform NTT based polynomial multiplication. We
 * execute a known value test to verify its functionality and correctness. We
 * are computing:
 *
 * poly_one * poly_two % (x^512 - 1) % 6984193
 */

int main()
{
    /* Read the current value of the processor cycle counter */
    uint64_t t0 = counter_read(); // Read the current value of the processor cycle counter

    /* Compute the iterative inplace forward NTTs */
    __asm_ntt_forward(poly_one, MR_top, MR_bot);
    __asm_ntt_forward(poly_two, MR_top, MR_bot);

    /* Compute the point-wise multiplication of the integer coefficients */
    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        poly_one[idx] = multiply_modulo(poly_one[idx], poly_two[idx], NTT_Q);
    }

    /* Compute the iterative inplace inverse NTT */
    __asm_ntt_inverse(poly_one, MR_inv_top, MR_inv_bot);

#ifndef SPEED
    /* Test the result of the computation against the known test values */
    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        if (poly_one[idx] != result[idx])
        {
            printf("%s\n", "This is not correct!");
            printf("%s%ld\n", "Error at index: ", idx);
            return -1;
        }
    }
    printf("%s\n", "This is correct!");
#endif

    /* Read and compare the current value of the processor cycle counter */
    uint64_t t1 = counter_read();
    printf("%ld\n", t1 - t0);

    return 0;
}
