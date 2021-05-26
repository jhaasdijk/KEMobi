#include "main.h"

/**
 * This source can be used to perform NTT based polynomial multiplication. We
 * execute a known value test to verify its functionality and correctness. We
 * are computing:
 *
 * poly_one * poly_two % (x^761 - x - 1) % 4591
 */

int main()
{
    /**
     * @brief Read the current value of the processor cycle counter (before).
     */

    uint64_t t0 = counter_read();

    /**
     * @brief Zero pad the input polynomials to size 1536.
     */

    int32_t A_vec[GPR], B_vec[GPR];

    pad(A_vec, poly_one);
    pad(B_vec, poly_two);

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
        ntt_forward(A_mat[idx], NTT_Q);
        ntt_forward(B_mat[idx], NTT_Q);
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
        ntt_inverse(C_mat[idx], NTT_Q);
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

    int32_t poly_out[NTRU_P];

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        poly_out[idx] = modulo(C_vec[idx], NTRU_Q);
    }

    /**
     * @brief Test the result of the computation against the known test values
     */

    for (size_t idx = 0; idx < NTRU_P; idx++)
    {
        if (poly_out[idx] != result[idx])
        {
            printf("%s\n", "This is not correct!");
            printf("%s%ld\n", "Error at index: ", idx);
            return -1;
        }
    }

    printf("%s\n", "This is correct!");

    /**
     * @brief Read the current value of the processor cycle counter (after).
     *
     * This value is compared to the (before) value to compute the performance
     * of the current implemenatation considering CPU cycle count.
     */

    uint64_t t1 = counter_read();
    printf("%ld\n", t1 - t0);

    return 0;
}
