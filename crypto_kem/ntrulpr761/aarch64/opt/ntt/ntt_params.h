#ifndef NTTPARAMS_H
#define NTTPARAMS_H

/**
 * This header is used to contain the various parameters (constants) that are in
 * use. It explains what they are, what they are used for and how to calculate
 * them. These values are specific to the kem/ntrulpr761 parameter set and need
 * to be updated if another parameter set is used.
 */

/**
 * @brief Define the original parameters for the kem/ntrulpr761 parameter set
 */

#define NTRU_P 761
#define NTRU_Q 4591
#define NTRU_W 250

/**
 * @brief Define the parameters for the Good's permutation
 *
 * We can use Good's trick to deconstruct our 'clunky' NTT into 3 size-512 NTTs
 * after zero-padding our integer arrays (polynomials) to size 1536.
 */

#define GP0 3
#define GP1 512
#define GPR 1536

/**
 * @brief Define the parameters for the NTT transformation
 *
 * These 3 smaller size-512 cyclic NTTs are used to multiply polynomials in
 * Z_6984193 [x] / (x^512 - 1).
 */

#define NTT_P 512     /* Define the size of the integer coefficient vectors */
#define NTT_Q 6984193 /* Define the ring of integers modulo VAR_Q */

/*
 * Since we are using Montgomery reduction to efficiently calculate the modular
 * multiplication of two multiplicands, we need to calculate q^-1 mod 2^32.
 *
 * NTT_Q^-1 modulo 2^width = 6984193^-1 modulo 2^32 = 1926852097
 */

#define NTT_QINV 1926852097

/**
 * @brief Define benchmarking related parameters
 */

#define NTESTS 100 /* Number of program executions in a single test */

#endif
