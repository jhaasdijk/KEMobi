#ifndef NTT_H
#define NTT_H

/**
 * This header accompanies ntt.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stddef.h>
#include <stdint.h>

/* Include user header files */

#include "params.h"
#include "util.h"

/* Provide function declarations */

void forward_layer_1(int32_t *coefficients);

void forward_layer_2(int32_t *coefficients);

void forward_layer_3(int32_t *coefficients);

void forward_layer_4(int32_t *coefficients);

void forward_layer_5(int32_t *coefficients);

void forward_layer_6(int32_t *coefficients);

void forward_layer_7(int32_t *coefficients);

void forward_layer_8(int32_t *coefficients);

void forward_layer_9(int32_t *coefficients);

void inverse_layer_9(int32_t *coefficients);

void inverse_layer_8(int32_t *coefficients);

void inverse_layer_7(int32_t *coefficients);

void inverse_layer_6(int32_t *coefficients);

void inverse_layer_5(int32_t *coefficients);

void inverse_layer_4(int32_t *coefficients);

void inverse_layer_3(int32_t *coefficients);

void inverse_layer_2(int32_t *coefficients);

void inverse_layer_1(int32_t *coefficients);

void ntt_forward(int32_t *coefficients, int32_t mod);

void ntt_inverse(int32_t *coefficients, int32_t mod);

#endif
