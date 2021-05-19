#ifndef GOODS_H
#define GOODS_H

/**
 * This header accompanies goods.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stdint.h>

/* Include user header files */

#include "params.h"

/* Provide function declarations */

void goods_forward(int32_t forward[GP0][GP1], int32_t *coefficients);

void goods_inverse(int32_t *coefficients, int32_t forward[GP0][GP1]);

#endif
