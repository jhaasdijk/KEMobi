#ifndef SPEED_UTIL_H
#define SPEED_UTIL_H

/**
 * This header accompanies util.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

#define NTESTS 100

/* ANSI escape codes */

#define CYAN "\033[36m"
#define RESET "\033[0m"

/* Provide function declarations */

uint64_t counter_read(void);

void sort(uint64_t *arr);

uint64_t median(uint64_t *arr);

void benchmark(uint64_t *arr, char *preface);

#endif
