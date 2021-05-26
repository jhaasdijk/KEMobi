#include "goods.h"

/**
 * This source can be used to perform the forward and inverse Good's
 * permutation. This is a trick that you can use to deconstruct an array of
 * integer coefficients into smaller NTT friendly sizes.
 */

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
