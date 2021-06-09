#ifndef UTIL_H
#define UTIL_H

/**
 * This header accompanies util.c. It can be used to contain function
 * declarations and macro definitions. As you can see it has been defined as a
 * Once-Only Header to avoid the compiler from processing the contents twice.
 */

/* Include system header files */

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>

/* Include user header files */

#include "params.h"

/* Provide function declarations */

uint64_t counter_read(void);

void print_polynomial(int32_t *coefficients, int16_t size);

void pad(int32_t *padded, int32_t *coefficients);

int32_t modulo(int64_t value, int32_t mod);

int32_t multiply_modulo(int32_t x, int32_t y, int32_t mod);

int32_t montgomery_reduce(int64_t x);

int32_t multiply_reduce(int32_t x, int32_t y);

void reduce_coefficients(int32_t *coefficients, int32_t mod);
extern void __asm_reduce_coefficients(int32_t *coefficients);

void reduce_terms_761(int32_t *coefficients);

#endif
