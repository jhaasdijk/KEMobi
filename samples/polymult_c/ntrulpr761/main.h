#ifndef MAIN_H
#define MAIN_H

/**
 * This header accompanies main.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

/* Include user header files */

#include "goods.h"
#include "ntt.h"
#include "params.h"
#include "util.h"

/* Provide function declarations */

int main(void);

#endif
