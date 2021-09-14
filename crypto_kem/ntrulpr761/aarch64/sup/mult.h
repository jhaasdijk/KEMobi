#ifndef MULT_H
#define MULT_H

/**
 * This header accompanies main761.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

/* Include user header files */

#include "ntt.h"
#include "goods.h"
#include "ntt_params.h"
#include "util.h"

/* Provide function declarations */

void ntt761(int16_t *fg, int16_t *f, int8_t *g);

#endif // MAIN761_H
