/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_inverse_layer_7
.global __asm_ntt_inverse_layer_6
.global __asm_ntt_inverse_layer_5
.global __asm_ntt_inverse_layer_4
.global __asm_ntt_inverse_layer_3
.global __asm_ntt_inverse_layer_2
.global __asm_ntt_inverse_layer_1

.type __asm_ntt_inverse_layer_7, %function
.type __asm_ntt_inverse_layer_6, %function
.type __asm_ntt_inverse_layer_5, %function
.type __asm_ntt_inverse_layer_4, %function
.type __asm_ntt_inverse_layer_3, %function
.type __asm_ntt_inverse_layer_2, %function
.type __asm_ntt_inverse_layer_1, %function

/* Provide macro definitions */

/*
    temp = coefficients[idx];
    coefficients[idx] = temp + coefficients[idx + length];
    coefficients[idx + length] = temp - coefficients[idx + length];
 */
.macro _asimd_sub_add q0, q1, q2, v0, v1, v2, addr, offset
    ldr     \q0, [\addr]            // Load coefficients[idx]
    ldr     \q1, [\addr, \offset]   // Load coefficients[idx + length]
    add     \v2, \v0, \v1           // temp + coefficients[idx + length]
    sub     \v1, \v0, \v1           // temp - coefficients[idx + length]
    str     \q2, [\addr]            // Store coefficients[idx]
.endm

/*
    coefficients[idx + length] = multiply_reduce(zeta, coefficients[idx + length]);
 */
.macro _asimd_mul_red q1, v0, v1, v2, v3, addr, offset
    mov     \v0[0], MR_top          // Load precomputed B
    sqdmulh \v2, \v1, \v0[0]        // Mulhi[a, B]
    mov     \v0[0], MR_bot          // Load precomputed B'
    mul     \v3, \v1, \v0[0]        // Mullo[a, B']
    mov     \v0[0], M               // Load constant M
    sqdmulh \v3, \v3, \v0[0]        // Mulhi[M, Mullo[a, B']]
    sub     \v1, \v2, \v3           // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]
    str     \q1, [\addr, \offset]   // Store coefficients[idx + length]
    add     \addr, \addr, #16       // Move to the next chunk
.endm

.macro __asm_ntt_inverse_layer length, ridx, loops
    mov     start, x0                   // Store *coefficients[0]
    add     last, x0, #4 * \length      // Store *coefficients[length]

    /* Store layer specific values  */

    add     x1, x1, #4 * \ridx          // ridx, used for indexing B
    add     x2, x2, #4 * \ridx          // ridx, used for indexing B'
    mov     x3, #1 * \loops             // loops (NTT_P / length / 2)

    ldr     MR_top, [x1], #4            // Load precomputed B
    ldr     MR_bot, [x2], #4            // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for an inverse butterfly */

    _asimd_sub_add q0, q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * \length
    _asimd_mul_red q1, v0.4s v1.4s v2.4s v3.4s, start, #4 * \length

    cmp     last, start                 // Check if we have reached the next chunk
    b.ne    1b

    add     start, last, #4 * \length   // Update pointer to next first coefficient
    add     last, last, #8 * \length    // Update pointer to next last coefficient

    ldr     MR_top, [x1], #4            // Load precomputed B
    ldr     MR_bot, [x2], #4            // Load precomputed B'

    sub     x3, x3, #1                  // Decrement loop counter by 1
    cmp     x3, #0                      // Check wether we are done
    b.ne    1b

    ret     lr
.endm

__asm_ntt_inverse_setup:

    /* Alias registers for a specific purpose (and readability) */

    start   .req x11    // Store pointer to the first integer coefficient
    last    .req x12    // Store pointer to the last integer coefficient

    MR_top  .req w13    // Store the precomputed B value for _asimd_mul_red
    MR_bot  .req w14    // Store the precomputed B' value for _asimd_mul_red
    M       .req w15    // Store the constant value M = 6984193

    /* Initialize constant values. Note that the move instruction is only able
     * to insert 16 bit immediate values into its destination. We therefore need
     * to split it up into a move of the lower 16 bits and a move (with keep) of
     * the upper 7 bits. */

    mov     M, #0x9201  // 6984193 (= M)
    movk    M, #0x6a, lsl #16

    ret lr


/* length = 4, ridx = 384, loops = 64 */
__asm_ntt_inverse_layer_7:
    __asm_ntt_inverse_layer 4, 384, 64


/* length = 8, ridx = 448, loops = 32 */
__asm_ntt_inverse_layer_6:
    __asm_ntt_inverse_layer 8, 448, 32


/* length = 16, ridx = 480, loops = 16 */
__asm_ntt_inverse_layer_5:
    __asm_ntt_inverse_layer 16, 480, 16


/* length = 32, ridx = 496, loops = 8 */
__asm_ntt_inverse_layer_4:
    __asm_ntt_inverse_layer 32, 496, 8


/* length = 64, ridx = 504, loops = 4 */
__asm_ntt_inverse_layer_3:
    __asm_ntt_inverse_layer 64, 504, 4


/* length = 128, ridx = 508, loops = 2 */
__asm_ntt_inverse_layer_2:
    __asm_ntt_inverse_layer 128, 508, 2


/* length = 256, ridx = 510, loops = 1 */
__asm_ntt_inverse_layer_1:
    mov     start, x0           // Store *coefficients[0]
    add     last, x0, #4 * 256  // Store *coefficients[length]

    /* Store layer specific values  */

    add     x1, x1, #4 * 510    // ridx, used for indexing B
    add     x2, x2, #4 * 510    // ridx, used for indexing B'

    ldr     MR_top, [x1], #4    // Load precomputed B
    ldr     MR_bot, [x2], #4    // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a inverse butterfly */

    _asimd_sub_add q0, q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * 256
    _asimd_mul_red q1, v0.4s v1.4s v2.4s v3.4s, start, #4 * 256

    cmp     last, start         // Check if we have reached the next chunk
    b.ne    1b

    /*
     * Multiply the result with the accumulated factor to complete the inverse
     * NTT transformation.
     *
     * 2^{-9} mod 6984193 = 512^-1 mod 6984193 = 6970552
     * B  = 6970552 · R mod M = 4194304
     * B' = B · M' mod R      = 4194304
     */

    mov     start, x0
    add     last, x0, #4 * 512

    mov     MR_top, #0x0000     // 4194304
    movk    MR_top, #0x40, lsl #16

    mov     v3.4s[0], MR_top
    mov     v4.4s[0], M

    /*
        for (size_t idx = 0; idx < NTT_P; idx++)
            coefficients[idx] = multiply_reduce(FACTOR, coefficients[idx]);
     */

    2:

    ldr     q0, [start]             // Load coefficients[idx] 
    sqdmulh v1.4s, v0.4s, v3.4s[0]  // Execute multiply_reduce
    mul     v2.4s, v0.4s, v3.4s[0]
    sqdmulh v2.4s, v2.4s, v4.4s[0]
    sub     v0.4s, v1.4s, v2.4s
    str     q0, [start], #16        // Store coefficients[idx]

    cmp     last, start
    b.ne    2b

    ret lr
