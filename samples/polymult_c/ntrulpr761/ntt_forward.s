/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_forward
.type __asm_ntt_forward, %function

/* Provide macro definitions */

.macro _asimd_mul_red q0, v0, v1, v2, v3, addr, offset
    ldr     \q0, [\addr, \offset]   // Load the upper coefficients
    mov     \v1[0], MR_top          // Load precomputed B
    sqdmulh \v2, \v0, \v1[0]        // Mulhi[a, B]
    mov     \v1[0], MR_bot          // Load precomputed B'
    mul     \v3, \v0, \v1[0]        // Mullo[a, B']
    mov     \v1[0], M               // Load constant M
    sqdmulh \v3, \v3, \v1[0]        // Mulhi[M, Mullo[a, B']]
    sub     \v0, \v2, \v3           // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]
.endm

.macro _asimd_sub_add q0, q1, v0, v1, v2, addr, offset
    ldr     \q0, [\addr]            // Load the lower coefficients
    sub     \v2, \v1, \v0           // coefficients[idx] - temp
    add     \v1, \v1, \v0           // coefficients[idx] + temp
    str     \q1, [\addr, \offset]   // Store the upper coefficients
    str     \q0, [\addr], #16       // Store the lower coefficients and move to next chunk
.endm

.macro __asm_ntt_forward_layer len, ridx, loops
    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * \len     // Store *coefficients[len]

    /* Store layer specific values  */

    add     x3, x1, #4 * \ridx      // ridx, used for indexing B
    add     x4, x2, #4 * \ridx      // ridx, used for indexing B'
    mov     x5, #1 * \loops         // loops (NTT_P / len / 2)

    ldr     MR_top, [x3], #4        // Load precomputed B
    ldr     MR_bot, [x4], #4        // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #4 * \len
    _asimd_sub_add q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * \len

    cmp     last, start             // Check if we have reached the next chunk
    b.ne    1b

    add     start, last, #4 * \len  // Update pointer to next first coefficient
    add     last, last, #8 * \len   // Update pointer to next last coefficient

    ldr     MR_top, [x3], #4        // Load next precomputed B
    ldr     MR_bot, [x4], #4        // Load next precomputed B'

    sub     x5, x5, #1              // Decrement loop counter by 1
    cmp     x5, #0                  // Check whether we are done
    b.ne    1b
.endm

.macro __asm_reduce_coefficients
    dup     v3.4s, M                // Move M into all 4 elements
    mov     v4.4s[0], M_inv         // Move M_inv into index [0]
                                    // We don't need to fill all 4 elements

    mov     start, x0               // Store *coefficients[0]
    add	    last, x0, #4 * 512      // Store *coefficients[len]

    /* Loop over all coefficients */

    1:
    ldr	    q0, [start]
    smull   v1.2d, v0.2s, v4.2s[0]
    sshr    v2.4s, v0.4s, #31
    smull2  v5.2d, v0.4s, v4.4s[0]
    uzp2    v1.4s, v1.4s, v5.4s
    sshr    v1.4s, v1.4s, #15
    sub	    v1.4s, v1.4s, v2.4s
    mls	    v0.4s, v1.4s, v3.4s
    cmge    v1.4s, v0.4s, #0
    add	    v2.4s, v0.4s, v3.4s
    bif	    v0.16b, v2.16b, v1.16b

    str	    q0, [start], #4 * 4     // Store the result and move to next chunk
    cmp	    last, start             // Check whether we are done
    b.ne    1b
.endm

__asm_ntt_forward:

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    /* Alias registers for a specific purpose (and readability) */

    start   .req x10    // Store pointer to the first integer coefficient
    last    .req x11    // Store pointer to the last integer coefficient

    MR_top  .req w12    // Store the precomputed B value for _asimd_mul_red
    MR_bot  .req w13    // Store the precomputed B' value for _asimd_mul_red

    M       .req w14    // Store the constant value M = 6984193
    M_inv   .req w15    // Store the constant value M_inv = 20150859

    /* Initialize constant values. Note that the move instruction is only able
     * to insert 16 bit immediate values into its destination. We therefore need
     * to split it up into a move of the lower 16 bits and a move (with keep) of
     * the upper 7 bits. */

    mov     M, #0x9201              // 6984193 (= M)
    movk    M, #0x6a, lsl #16

    mov	    M_inv, #0x7a4b
    movk    M_inv, #0x133, lsl #16  // 20150859 (= M_inv)

    /* NTT forward layer 1: length = 256, ridx = 0, loops = 1 */

    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * 256      // Store *coefficients[256]

    ldr     MR_top, [x1, #4 * 0]    // Load precomputed B[0]
    ldr     MR_bot, [x2, #4 * 0]    // Load precomputed B'[0]

    1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #4 * 256
    _asimd_sub_add q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * 256

    /* Check to verify loop condition idx < 256. It's cool to see that we can
     * directly compare X10 (X0) and X11 (X0 + #4 * 256). This is due to the
     * fact that we are working with pointers and not actual values. This allows
     * us to do cheap equality checks without having to execute load
     * instructions. */

    cmp     last, start             // Compare offset with *coefficients[256]
    b.ne    1b

    /* NTT forward layer 2: length = 128, ridx = 1, loops = 2 */
    __asm_ntt_forward_layer 128, 1, 2

    /* NTT forward layer 3: length = 64, ridx = 3, loops = 4 */
    __asm_ntt_forward_layer 64, 3, 4

    /* NTT forward layer 4: length = 32, ridx = 7, loops = 8 */
    __asm_ntt_forward_layer 32, 7, 8

    /* NTT forward layer 5: length = 16, ridx = 15, loops = 16 */
    __asm_ntt_forward_layer 16, 15, 16

    /* NTT forward layer 6: length = 8, ridx = 31, loops = 32 */
    __asm_ntt_forward_layer 8, 31, 32

    /* NTT forward layer 7: length = 4, ridx = 63, loops = 64 */
    __asm_ntt_forward_layer 4, 63, 64

    /* NTT forward layer 8: length = 2, ridx = 127, loops = 128 */

    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x6, x1, #4 * 127        // ridx, used for indexing B
    add     x7, x2, #4 * 127        // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    /* Load the precomputed roots */

    ldr     MR_top, [x6], #4        // B[0]
    mov     v7.4s[0], MR_top
    mov     v7.4s[1], MR_top

    ldr     MR_bot, [x7], #4        // B'[0]
    mov     v8.4s[0], MR_bot
    mov     v8.4s[1], MR_bot

    ldr     MR_top, [x6], #4        //  B[1]
    mov     v7.4s[2], MR_top
    mov     v7.4s[3], MR_top

    ldr     MR_bot, [x7], #4        //  B'[1]
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

    /* Execute _asimd_mul_red */

    sqdmulh v2.4s, v0.4s, v7.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v8.4s     // Mullo[a, B']
    mov     v7.4s[0], M             // Load constant M
    sqdmulh v3.4s, v3.4s, v7.4s[0]  // Mulhi[M, Mullo[a, B']]
    sub     v2.4s, v2.4s, v3.4s     // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]

    /* Execute _asimd_sub_add */

    sub     v0.4s, v1.4s, v2.4s
    add     v1.4s, v1.4s, v2.4s

    /* Store the result */

    st1     {v1.s}[0], [start_s], #4
    st1     {v1.s}[1], [start_s], #4
    st1     {v0.s}[0], [start_s], #4
    st1     {v0.s}[1], [start_s], #4
    st1     {v1.s}[2], [start_s], #4
    st1     {v1.s}[3], [start_s], #4
    st1     {v0.s}[2], [start_s], #4
    st1     {v0.s}[3], [start_s], #4

    sub     x3, x3, #1              // Decrement loop counter by 1
    cmp     x3, #0                  // Check wether we are done
    b.ne    1b

    /* NTT forward layer 9: length = 1, ridx = 255, loops = 256 */

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x6, x1, #4 * 255        // ridx, used for indexing B
    add     x7, x2, #4 * 255        // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    ldr q7, [x6], #16               // Load precomputed B
    ldr q8, [x7], #16               // Load precomputed B'

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

    /* Execute _asimd_mul_red */

    sqdmulh v2.4s, v0.4s, v7.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v8.4s     // Mullo[a, B']
    mov     v7.4s[0], M             // Load constant M
    sqdmulh v3.4s, v3.4s, v7.4s[0]  // Mulhi[M, Mullo[a, B']]
    sub     v2.4s, v2.4s, v3.4s     // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]

    /* Execute _asimd_sub_add */

    sub     v0.4s, v1.4s, v2.4s
    add     v1.4s, v1.4s, v2.4s

    /* Store the result */

    st1     {v1.s}[0], [start_s], #4
    st1     {v0.s}[0], [start_s], #4
    st1     {v1.s}[1], [start_s], #4
    st1     {v0.s}[1], [start_s], #4
    st1     {v1.s}[2], [start_s], #4
    st1     {v0.s}[2], [start_s], #4
    st1     {v1.s}[3], [start_s], #4
    st1     {v0.s}[3], [start_s], #4

    sub     x3, x3, #1              // Decrement loop counter by 1
    cmp     x3, #0                  // Check wether we are done
    b.ne    1b

    /* Reduce the integer coefficients before returning control */

    __asm_reduce_coefficients

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    ret     lr
