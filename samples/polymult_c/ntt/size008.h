#ifndef SIZE008_H
#define SIZE008_H

#include <stdint.h>
#include <stdio.h>

#define VAR_P 8 /* Define the size of the integer coefficient vectors */
#define VAR_Q 17 /* Coefficients are from the ring of integers modulo VAR_Q */

/*
 * These are the roots for a size - 8 cyclic NTT, i.e. we are multiplying two
 * polynomials in Z_17 [x] / (x^8 - 1). Remember that the inverse roots have
 * been reordered since we are using an iterative approach.
 */
const uint32_t roots[] = {1, 1, 4, 1, 4, 2, 8};
const uint32_t roots_inv[] = {1, 13, 9, 15, 1, 13, 1};

/* Define two polynomials poly_one, poly_two of size VAR_P */
uint32_t poly_one[VAR_P] = {2, 0, 0, 7, 2, 0, 0, 7};
uint32_t poly_two[VAR_P] = {6, 0, 2, 0, 6, 0, 2, 0};

#endif
