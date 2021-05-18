#ifndef SIZE008_H
#define SIZE008_H

#include <stdint.h>
#include <stdio.h>

#define VAR_P 8   /* Define the size of the integer coefficient vectors */
#define VAR_Q 17  /* Coefficients are from the ring of integers modulo VAR_Q */
#define INV_Q 241 /* VAR_Q^-1 modulo 2^width , i.e. 17^-1 modulo 2^8 */

/*
 * These are the roots for a size - 8 cyclic NTT, i.e. we are multiplying two
 * polynomials in Z_17 [x] / (x^8 - 1). Remember that the inverse roots have
 * been reordered since we are using an iterative approach.
 */
const int8_t roots[VAR_P - 1] = {1, 1, 4, 1, 4, 2, 8};
const int8_t roots_inv[VAR_P - 1] = {1, 13, 9, 15, 1, 13, 1};

/* Define two polynomials poly_one, poly_two of size VAR_P */
int8_t poly_one[VAR_P] = {2, 0, 0, 7, 2, 0, 0, 7};
int8_t poly_two[VAR_P] = {6, 0, 2, 0, 6, 0, 2, 0};

/*
 * Define the result - we are performing a known value test
 * Computing "poly_one * poly_two % (x^8 - 1) % 17" should produce:
 */
int8_t result[VAR_P] = {7, 11, 8, 16, 7, 11, 8, 16};

#endif
