#include "main512.h"

/**
 * This source can be used to perform NTT based polynomial multiplication. We
 * execute a known value test to verify its functionality and correctness. We
 * are computing:
 *
 * poly_one * poly_two % (x^512 - 1) % 6984193
 */

/* Function for computing poly_one * poly_two % (x^512 - 1) % 6984193 */
void ntt512(int32_t *fg, int32_t *f, int32_t *g)
{
    /* Compute the iterative inplace forward NTT */
    __asm_ntt_forward(f, MR_top, MR_bot);
    __asm_ntt_forward(g, MR_top, MR_bot);

    /* Compute the point-wise multiplication of the integer coefficients */
    for (size_t idx = 0; idx < NTT_P; idx++)
    {
        fg[idx] = multiply_modulo(f[idx], g[idx], NTT_Q);
    }

    /* Compute the iterative inplace inverse NTT */
    __asm_ntt_inverse(fg, MR_inv_top, MR_inv_bot);

    __asm_reduce_coefficients(fg);
}

/* Function for benchmarking the forward NTT */
void test_ntt_forward(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        __asm_ntt_forward(poly_one, MR_top, MR_bot);
    }

    benchmark(t0, preface);
}

/* Function for benchmarking the point-wise multiplication */
void test_ntt_mult(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        for (size_t idx = 0; idx < NTT_P; idx++)
        {
            poly_one[idx] = multiply_modulo(poly_one[idx], poly_two[idx], NTT_Q);
        }
    }

    benchmark(t0, preface);
}

/* Function for benchmarking the inverse NTT */
void test_ntt_inverse(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        __asm_ntt_inverse(poly_one, MR_top, MR_bot);
    }

    benchmark(t0, preface);
}

/* Function for benchmarking the complete calculation */
void test_complete(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        ntt512(poly_one, poly_one, poly_two);
    }

    benchmark(t0, preface);
}

int main()
{
    /**
     * @brief Verify that the result is still correct.
     *
     * We test the result of the computation against the known test values.
     */

    ntt512(poly_one, poly_one, poly_two);

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

    /**
     * @brief Benchmark the performance of the individual fragments.
     *
     * We do this by looping the operations NTESTS time. This is better than a
     * 'one shot' test since we need to warm up the cache and ensure that it
     * contains valid data. During performance testing it is important to take
     * the frequency of cache hits / cache misses into account.
     */

    printf("%s\n", "Zx(F) * Zx(G) % (x^512 - 1) % 6984193");

    test_ntt_forward("NTT forward");
    test_ntt_mult("Product");
    test_ntt_inverse("NTT inverse");
    test_complete("Complete");

    return 0;
}
