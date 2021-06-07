/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_inverse_layer_9
.global __asm_ntt_inverse_layer_8
.global __asm_ntt_inverse_layer_765
.global __asm_ntt_inverse_layer_4321

.type __asm_ntt_inverse_layer_9, %function
.type __asm_ntt_inverse_layer_8, %function
.type __asm_ntt_inverse_layer_765, %function
.type __asm_ntt_inverse_layer_4321, %function

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

    add     x3, x1, #4 * \ridx          // ridx, used for indexing B
    add     x4, x2, #4 * \ridx          // ridx, used for indexing B'
    mov     x5, #1 * \loops             // loops (NTT_P / length / 2)

    ldr     MR_top, [x3], #4            // Load precomputed B
    ldr     MR_bot, [x4], #4            // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for an inverse butterfly */

    _asimd_sub_add q0, q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * \length
    _asimd_mul_red q1, v0.4s v1.4s v2.4s v3.4s, start, #4 * \length

    cmp     last, start                 // Check if we have reached the next chunk
    b.ne    1b

    add     start, last, #4 * \length   // Update pointer to next first coefficient
    add     last, last, #8 * \length    // Update pointer to next last coefficient

    ldr     MR_top, [x3], #4            // Load precomputed B
    ldr     MR_bot, [x4], #4            // Load precomputed B'

    sub     x5, x5, #1                  // Decrement loop counter by 1
    cmp     x5, #0                      // Check wether we are done
    b.ne    1b
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


/* length = 1, ridx = 0 */
__asm_ntt_inverse_layer_9:
    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x1, x1, #4 * 0          // ridx, used for indexing B
    add     x2, x2, #4 * 0          // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    /* Load the precomputed roots */

    ldr q7, [x1], #16
    ldr q8, [x2], #16

    /* Load the coefficients */

    ld1     {v1.s}[0], [start_l], #4
    ld1     {v0.s}[0], [start_l], #4
    ld1     {v1.s}[1], [start_l], #4
    ld1     {v0.s}[1], [start_l], #4
    ld1     {v1.s}[2], [start_l], #4
    ld1     {v0.s}[2], [start_l], #4
    ld1     {v1.s}[3], [start_l], #4
    ld1     {v0.s}[3], [start_l], #4

    // q0 contains coefficients [1, 3, 5, 7]
    // q1 contains coefficients [0, 2, 4, 6]

    /* Execute _asimd_sub_add */

    add     v2.4s, v1.4s, v0.4s
    sub     v0.4s, v1.4s, v0.4s

    /* Execute _asimd_mul_red */

    sqdmulh v1.4s, v0.4s, v7.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v8.4s     // Mullo[a, B']
    mov     v7.4s[0], M             // Load constant M
    sqdmulh v3.4s, v3.4s, v7.4s[0]  // Mulhi[M, Mullo[a, B']]
    sub     v1.4s, v1.4s, v3.4s     // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]

    // q2 contains coefficients [0, 2, 4, 6]
    // q1 contains coefficients [1, 3, 5, 7]

    /* Store the result */

    st1     {v2.s}[0], [start_s], #4
    st1     {v1.s}[0], [start_s], #4
    st1     {v2.s}[1], [start_s], #4
    st1     {v1.s}[1], [start_s], #4
    st1     {v2.s}[2], [start_s], #4
    st1     {v1.s}[2], [start_s], #4
    st1     {v2.s}[3], [start_s], #4
    st1     {v1.s}[3], [start_s], #4

    sub     x3, x3, #1              // Decrement loop counter by 1
    cmp     x3, #0                  // Check wether we are done
    b.ne    1b

    ret     lr


/* length = 2, ridx = 256 */
__asm_ntt_inverse_layer_8:

    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x1, x1, #4 * 256        // ridx, used for indexing B
    add     x2, x2, #4 * 256        // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    /* Load the precomputed roots */

    ldr     MR_top, [x1], #4        // B[0]
    mov     v7.4s[0], MR_top
    mov     v7.4s[1], MR_top

    ldr     MR_bot, [x2], #4        // B'[0]
    mov     v8.4s[0], MR_bot
    mov     v8.4s[1], MR_bot

    ldr     MR_top, [x1], #4        // B[1]
    mov     v7.4s[2], MR_top
    mov     v7.4s[3], MR_top

    ldr     MR_bot, [x2], #4        // B'[1]
    mov     v8.4s[2], MR_bot
    mov     v8.4s[3], MR_bot

    /* Load the coefficients */

    ld1     {v1.s}[0], [start_l], #4
    ld1     {v1.s}[1], [start_l], #4
    ld1     {v0.s}[0], [start_l], #4
    ld1     {v0.s}[1], [start_l], #4
    ld1     {v1.s}[2], [start_l], #4
    ld1     {v1.s}[3], [start_l], #4
    ld1     {v0.s}[2], [start_l], #4
    ld1     {v0.s}[3], [start_l], #4

    // q0 contains coefficients [2, 3, 6, 7]
    // q1 contains coefficients [0, 1, 4, 5]

    /* Execute _asimd_sub_add */

    add     v2.4s, v1.4s, v0.4s
    sub     v0.4s, v1.4s, v0.4s

    /* Execute _asimd_mul_red */

    sqdmulh v1.4s, v0.4s, v7.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v8.4s     // Mullo[a, B']
    mov     v7.4s[0], M             // Load constant M
    sqdmulh v3.4s, v3.4s, v7.4s[0]  // Mulhi[M, Mullo[a, B']]
    sub     v1.4s, v1.4s, v3.4s     // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]

    // q2 contains coefficients [0, 1, 4, 5]
    // q1 contains coefficients [2, 3, 6, 7]

    /* Store the result */

    st1     {v2.s}[0], [start_s], #4
    st1     {v2.s}[1], [start_s], #4
    st1     {v1.s}[0], [start_s], #4
    st1     {v1.s}[1], [start_s], #4
    st1     {v2.s}[2], [start_s], #4
    st1     {v2.s}[3], [start_s], #4
    st1     {v1.s}[2], [start_s], #4
    st1     {v1.s}[3], [start_s], #4

    sub     x3, x3, #1              // Decrement loop counter by 1
    cmp     x3, #0                  // Check wether we are done
    b.ne    1b

    ret     lr


__asm_ntt_inverse_layer_765:

    /* layer 7: length = 4, ridx = 384, loops = 64 */
    __asm_ntt_inverse_layer 4, 384, 64

    /* layer 6: length = 8, ridx = 448, loops = 32 */
    __asm_ntt_inverse_layer 8, 448, 32

    /* layer 5: length = 16, ridx = 480, loops = 16 */
    __asm_ntt_inverse_layer 16, 480, 16

    ret     lr

__asm_ntt_inverse_layer_4321:

    /* layer 4: length = 32, ridx = 496, loops = 8 */
    __asm_ntt_inverse_layer 32, 496, 8

    /* layer 3: length = 64, ridx = 504, loops = 4 */
    __asm_ntt_inverse_layer 64, 504, 4

    /* layer 2: length = 128, ridx = 508, loops = 2 */
    __asm_ntt_inverse_layer 128, 508, 2

    /* layer 1: length = 256, ridx = 510, loops = 1 */

    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * 256      // Store *coefficients[length]

    /* Store layer specific values  */

    add     x1, x1, #4 * 510        // ridx, used for indexing B
    add     x2, x2, #4 * 510        // ridx, used for indexing B'
    ldr     MR_top, [x1], #4        // Load precomputed B
    ldr     MR_bot, [x2], #4        // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a inverse butterfly */

    _asimd_sub_add q0, q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * 256
    _asimd_mul_red q1, v0.4s v1.4s v2.4s v3.4s, start, #4 * 256

    cmp     last, start             // Check if we have reached the next chunk
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

    mov     MR_top, #0x0000         // 4194304
    movk    MR_top, #0x40, lsl #16

    mov     v3.4s[0], MR_top
    mov     v4.4s[0], M

    /*
        for (size_t idx = 0; idx < NTT_P; idx++)
            coefficients[idx] = multiply_reduce(4194304, coefficients[idx]);
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
