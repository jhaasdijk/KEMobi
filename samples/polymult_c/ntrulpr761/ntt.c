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
void ntt_forward(int32_t *coefficients, int32_t mod)
{
    __asm_ntt_setup();
    __asm_ntt_forward_layer(coefficients, MR_top, MR_bot);

    __asm_ntt_forward_layer_8(coefficients, MR_top, MR_bot);
    __asm_ntt_forward_layer_9(coefficients, MR_top, MR_bot);

    reduce_coefficients(coefficients, mod);
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
void ntt_inverse(int32_t *coefficients, int32_t mod)
{
    __asm_ntt_setup();

    __asm_ntt_inverse_layer_9(coefficients, MR_inv_top, MR_inv_bot);
    __asm_ntt_inverse_layer_8(coefficients, MR_inv_top, MR_inv_bot);

    __asm_ntt_inverse_layer_765(coefficients, MR_inv_top, MR_inv_bot);

    /**
     * @brief Ensure that the coefficients stay within their allocated 32 bits
     *
     * Due to how the inverse NTT transformation is calculated, each layer
     * increases the possible bitsize of the integer coefficients by 1.
     * Performing 9 layers increases the possible bitsize of the integer
     * coefficients by 9. To ensure that the integer coefficients stay within
     * their allocated 32 bits we either 1) need to ensure that all values are
     * at most 23 bits at the start of the function or 2) perform an
     * intermediate reduction.
     */

    reduce_coefficients(coefficients, mod);

    __asm_ntt_inverse_layer_4321(coefficients, MR_inv_top, MR_inv_bot);

    reduce_coefficients(coefficients, mod);
}
