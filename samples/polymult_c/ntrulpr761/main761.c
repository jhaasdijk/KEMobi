#include "main761.h"

/**
 * This source can be used to perform NTT based polynomial multiplication. We
 * execute a known value test to verify its functionality and correctness. We
 * are computing:
 *
 * poly_one * poly_two % (x^761 - x - 1) % 4591
 */

/* Function for computing poly_one * poly_two % (x^761 - x - 1) % 4591 */
void ntt761(int32_t *fg, int32_t *f, int32_t *g)
{
    /**
     * @brief Zero pad the input polynomials to size 1536.
     */

    int32_t A_vec[GPR], B_vec[GPR];

    pad(A_vec, f);
    pad(B_vec, g);

    /**
     * @brief Compute the forward Good's permutation.
     *
     * This deconstructs the 'clunky' zero padded arrays of integer coefficients
     * into 3 size-512 NTTs.
     */

    int32_t A_mat[GP0][GP1], B_mat[GP0][GP1];

    goods_forward(A_mat, A_vec);
    goods_forward(B_mat, B_vec);

    /**
     * @brief Compute the iterative inplace forward NTTs.
     *
     * This computes the forward NTT transformation of our size-512 polynomials.
     */

    for (size_t idx = 0; idx < GP0; idx++)
    {
        __asm_ntt_forward(A_mat[idx], MR_top, MR_bot);
        __asm_ntt_forward(B_mat[idx], MR_top, MR_bot);
    }

    /**
     * @brief Compute the point-wise multiplication of the integer coefficients.
     *
     * Be careful with these smaller polynomial multiplications. We are not
     * actually computing the result 'point-wise'. Instead we multiply two
     * degree 2 polynomials and reduce the result mod (x^3 - 1). E.g.:
     *
     * (
     *   { F[0][0], F[1][0], F[2][0] } *
     *   { G[0][0], G[1][0], G[2][0] }
     * ) % (X^3 - 1)
     *
     * = C[0][0], C[1][0], C[2][0]
     */

    int32_t C_mat[GP0][GP1];

    for (size_t idx = 0; idx < GP1; idx++)
    {
        /* Define an accumulator to store temporary values. It is important that
         * we (re)initialize this with zeros at each iteration of the loop */
        int32_t accum[2 * GP0 - 1] = {0, 0, 0, 0, 0};

        /* Obtain two degree 2 polynomials from A_mat, B_mat */
        int32_t F[GP0] = {A_mat[0][idx], A_mat[1][idx], A_mat[2][idx]};
        int32_t G[GP0] = {B_mat[0][idx], B_mat[1][idx], B_mat[2][idx]};

        /* Multiply the two polynomials naively */
        for (size_t n = 0; n < GP0; n++)
        {
            for (size_t m = 0; m < GP0; m++)
            {
                accum[n + m] += multiply_modulo(F[n], G[m], NTT_Q);
            }
        }

        /* Reduce the result mod (x^3 - 1) */
        for (size_t p = 2 * GP0 - 2; p >= GP0; p--)
        {
            if (accum[p] > 0)
            {                               /* x^p is nonzero */
                accum[p - GP0] += accum[p]; /* add x^p into x^0 */
                accum[p] = 0;               /* zero x^p */
            }
        }

        /* Store the result */
        C_mat[0][idx] = accum[0];
        C_mat[1][idx] = accum[1];
        C_mat[2][idx] = accum[2];
    }

    /**
     * @brief Compute the iterative inplace inverse NTT.
     *
     * This computes the inverse NTT transformation of our size-512 polynomials.
     */

    for (size_t idx = 0; idx < GP0; idx++)
    {
        __asm_ntt_inverse(C_mat[idx], MR_inv_top, MR_inv_bot);
    }

    /**
     * @brief Compute the inverse Good's permutation.
     *
     * This undoes the forward Good's permutation and constructs an array of
     * integer coefficients from the deconstructed smaller NTT friendly matrix.
     */

    int32_t C_vec[GPR];

    goods_inverse(C_vec, C_mat);

    /**
     * @brief Reduce the result of the multiplication mod (x^761 - x - 1).
     */

    reduce_terms_761(C_vec);

    /**
     * @brief Ensure the result is correct in the integer domain.
     *
     * Before we can further reduce the integer coefficients we need to ensure
     * that the result is correct in the integer domain. We therefore reduce all
     * 761 integer coefficients mod 6984193.
     */

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        C_vec[idx] = modulo(C_vec[idx], NTT_Q);
    }

    /**
     * @brief Reduce the integer coefficients mod 4591 and store the result.
     *
     * This loop iterates over the first 761 integer coefficients, reduces them
     * mod 4591 and stores them. This removes the zero padding.
     */

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        fg[idx] = modulo(C_vec[idx], NTRU_Q);
    }
}

/* Function for benchmarking the zero padding */
void test_zpad(char *preface)
{
    uint64_t t0[NTESTS];

    int32_t v[GPR];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        pad(v, poly_one);
    }

    benchmark(t0, preface);
}

/* Function for benchmarking the forward Good's permutation */
void test_goods_forward(char *preface)
{
    uint64_t t0[NTESTS];

    int32_t v[GPR], m[GP0][GP1];
    pad(v, poly_one);

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        goods_forward(m, v);
    }

    benchmark(t0, preface);
}

/* Function for benchmarking the forward NTT transformation */
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

    int32_t v[GPR], w[GPR];
    int32_t m[GP0][GP1], n[GP0][GP1];

    pad(v, poly_one);
    pad(w, poly_two);

    goods_forward(m, v);
    goods_forward(n, w);

    for (size_t idx = 0; idx < GP0; idx++)
    {
        __asm_ntt_forward(m[idx], MR_top, MR_bot);
        __asm_ntt_forward(n[idx], MR_top, MR_bot);
    }

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();

        for (size_t j = 0; j < GP1; j++)
        {
            int32_t accum[2 * GP0 - 1] = {0, 0, 0, 0, 0};
            int32_t F[GP0] = {m[0][j], m[1][j], m[2][j]};
            int32_t G[GP0] = {n[0][j], n[1][j], n[2][j]};

            for (size_t k = 0; k < GP0; k++)
                for (size_t l = 0; l < GP0; l++)
                    accum[k + l] += multiply_modulo(F[k], G[l], NTT_Q);

            for (size_t p = 2 * GP0 - 2; p >= GP0; p--)
            {
                if (accum[p] > 0)
                {
                    accum[p - GP0] += accum[p];
                    accum[p] = 0;
                }
            }
        }
    }

    benchmark(t0, preface);
}

/* Function for benchmarking the inverse NTT transformation */
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

/* Function for benchmarking the inverse Good's permutation */
void test_goods_inverse(char *preface)
{
    uint64_t t0[NTESTS];

    int32_t v[GPR], m[GP0][GP1];
    pad(v, poly_one);
    goods_forward(m, v);

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        goods_inverse(v, m);
    }

    benchmark(t0, preface);
}

/* Function for benchmarking Zx % (x^761 - x - 1)*/
void test_red(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        reduce_terms_761(poly_one);
    }

    benchmark(t0, preface);
}

/* Function for benchmarking Zx % 6984193 */
void test_ntt_mod(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        for (size_t idx = 0; idx < NTRU_P; idx++)
        {
            poly_one[idx] = modulo(poly_one[idx], NTT_Q);
        }
    }

    benchmark(t0, preface);
}

/* Function for benchmarking Zx % 4591 */
void test_mod(char *preface)
{
    uint64_t t0[NTESTS];

    for (size_t i = 0; i < NTESTS; i++)
    {
        t0[i] = counter_read();
        for (size_t idx = 0; idx < NTRU_P; idx++)
        {
            poly_one[idx] = modulo(poly_one[idx], NTRU_Q);
        }
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
        ntt761(poly_one, poly_one, poly_two);
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

    ntt761(poly_one, poly_one, poly_two);

    for (size_t idx = 0; idx < NTRU_P; idx++)
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

    printf("%s\n", "Zx(F) * Zx(G) % (x^761 - x - 1) % 4591");

    test_zpad("Zero padding");
    test_goods_forward("Good's forward");
    test_ntt_forward("NTT forward");
    test_ntt_mult("Product");
    test_ntt_inverse("NTT inverse");
    test_goods_inverse("Good's inverse");
    test_red("Zx % (x^761 - x - 1)");
    test_ntt_mod("Zx % 6984193");
    test_mod("Zx % 4591");
    test_complete("Complete");

    return 0;
}
