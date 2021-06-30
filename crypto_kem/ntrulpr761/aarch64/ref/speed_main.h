#ifndef SPEED_MAIN_H
#define SPEED_MAIN_H

/**
 * This header accompanies main.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

#define KAT_SUCCESS 0
#define KAT_FILE_OPEN_ERROR -1
#define KAT_CRYPTO_FAILURE -4

/* Include system header files */

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/* Include user header files */

#include "nist/rng.h"
#include "crypto_kem.h"
#include "speed_util.h"

/* Provide function declarations */

int main(void);

#endif // SPEED_MAIN_H