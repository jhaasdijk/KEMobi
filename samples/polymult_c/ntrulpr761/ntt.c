#include "ntt.h"

/**
 * This source can be used to perform the forward and inverse iterative inplace
 * NTT transformations. While the per-layer transformations have been defined in
 * external assembly files, this source defines easy to use wrappers for both
 * the forward and inverse NTT.
 */

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
void ntt_forward(int32_t *coefficients)
{
    __asm_ntt_forward(coefficients, MR_top, MR_bot);
}

/**
 * @brief Compute the iterative inplace inverse NTT of a polynomial.
 *
 * @details This function can be used to compute the iterative inplace inverse
 * NTT of a polynomial represented by its integer coefficients. It wraps the
 * earlier defined per-layer inverse transformations into a single, easy to use
 * function.
 *
 * @param[in, out] coefficients An array of integer coefficients (i.e. a polynomial)
 * @param[in] mod The modulo used to reduce each integer value
 */
void ntt_inverse(int32_t *coefficients)
{
    __asm_ntt_inverse(coefficients, MR_inv_top, MR_inv_bot);
}
