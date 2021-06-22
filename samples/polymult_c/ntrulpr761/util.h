#ifndef UTIL_H
#define UTIL_H

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

/* Include user header files */

#include "params.h"

/* ANSI escape codes */

#define CYAN "\033[36m"
#define RESET "\033[0m"

/* Provide function declarations */

uint64_t counter_read(void);

void sort(uint64_t *arr);

uint64_t median(uint64_t *arr);

void benchmark(uint64_t *arr, char *preface);

void print_polynomial(int32_t *coefficients, int16_t size);

void pad(int32_t *padded, int32_t *coefficients);

int32_t modulo(int64_t value, int32_t mod);

int32_t multiply_modulo(int32_t x, int32_t y, int32_t mod);

void reduce_terms_761(int32_t *coefficients);

#endif
