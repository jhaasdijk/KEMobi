/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_setup
.global __asm_ntt_forward_layer
.global __asm_ntt_forward_layer_8
.global __asm_ntt_forward_layer_9
.global __asm_reduce_coefficients

.type __asm_ntt_setup, %function
.type __asm_ntt_forward_layer, %function
.type __asm_ntt_forward_layer_8, %function
.type __asm_ntt_forward_layer_9, %function
.type __asm_reduce_coefficients, %function

/* Provide macro definitions */

/*
 * Multiply a, b and reduce the result using Montgomery reduction. I.e. we are
 * computing a · b = MR(a · (b · R mod M)). Since we are using known values for
 * b (roots, roots_inv) we can precompute (b · R mod M).
 *
 * M = 6984193, R = 4294967296 (= 2^32)
 *
 * If we can calculate M' = M^-1 mod R, the computation becomes:
 *
 * (a · (b · R mod M) − ((a · (b · R mod M) mod R) · M' mod R) · M) / R
 *
 * Which we can rewrite as:
 *
 * (a · (b · R mod M) − M · (a · (b · R mod M) · M' mod R)) / R
 *
 * Notice how we now need to precompute two values, instead of one.
 *
 * B = (b · R mod M), and B' = ((b · R mod M) · M' mod R)
 *
 * However since we are using known values for b (roots, roots_inv) this is not
 * a problem. We can perform this computation like this:
 *
 * Mulhi[a, B] − Mulhi[M, Mullo[a, B']]
 *
 * In NEON we have acces to a vectorized Mullo (MUL) but unfortunately not to a
 * vectorized Mulhi. We can work around this issue by using the SQDMULH
 * instruction and using R = 2^31 instead.
 *
 * (a · (b · R mod M) − M · (a · (b · R mod M) · M' mod R)) / R
 *
 * Then becomes:
 *
 * (2a · (b · R mod M) - 2M · (a · (b · R mod M) · M' mod R)) / 2R
 *
 * M = 6984193, M_inv = 1926852097, R = 2147483648 (= 2^31)
 *
 * To precompute the values in Python, execute the following:
 *
 * roots is a list with the original roots for the size - 512 cyclic NTT
 * B  = b · R mod M              = [(_ * R) % M for _ in roots]
 * B' = (b · R mod M) · M' mod R = [(_ * M_inv) % R for _ in B]
 *
 * Note that precomputation is not limited to the roots but can be performed for
 * any known value.
 */

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

.macro _asimd_sub_add q1, v1, q2, v2, v0, addr, offset
    ldr     \q1, [\addr]            // Load the lower coefficients
    sub     \v2, \v1, \v0           // coefficients[idx] - temp
    add     \v1, \v1, \v0           // coefficients[idx] + temp
    str     \q2, [\addr, \offset]   // Store the upper coefficients
    str     \q1, [\addr], #16       // Store the lower coefficients and move to next chunk
.endm

.macro __asm_ntt_forward_layer length, ridx, loops
    mov     start, x0                   // Store *coefficients[0]
    add     last, x0, #4 * \length      // Store *coefficients[length]

    /* Store layer specific values  */

    add     x3, x1, #4 * \ridx          // ridx, used for indexing B
    add     x4, x2, #4 * \ridx          // ridx, used for indexing B'
    mov     x5, #1 * \loops             // loops (NTT_P / length / 2)

    ldr     MR_top, [x3], #4            // Load precomputed B
    ldr     MR_bot, [x4], #4            // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #4 * \length
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #4 * \length

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

__asm_ntt_setup:

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

/*
 * void forward_layer_1(int32_t *coefficients)
 * {
 *     int32_t temp;
 *
 *     for (size_t idx = 0; idx < 256; idx++)
 *     {
 *         temp = multiply_reduce(zeta[0], coefficients[idx + 256]);
 *         coefficients[idx + 256] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 * }
 *
 * This function executes 256 subtractions and 256 additions. The integer
 * coefficients are stored as int32_t which means that we can operate on 4
 * values simultaneously using the 128 bit SIMD registers. We should therefore
 * be able to bring this down to 64 subtractions and 64 additions.
 *
 * (We are ignoring the cost of the call to multiply_reduce as this is not part
 * of the local function. We are also ignoring the load/store overhead)
 *
 * ASIMD arith instructions (ADD / SUB)
 * Execution Latency    : 3
 * Execution Throughput : 2
 *
 * This means that *). Operations dependent on ASIMD arith instructions need to
 * wait at least 3 cycles before being able to use the result, and that *). The
 * maximum number of ASIMD arith instructions that can be processed per cycle is
 * 2.
 *
 * This means that the absolute (unrealistic) lower bound of what we can achieve
 * within the forward_layer_1 function is 64 cycles (128 ASIMD arith
 * instructions / 2).
 */

__asm_ntt_forward_layer:

    /* layer 1: length = 256, ridx = 0, loops = 1 */

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    /* Store the coefficients pointer and an offset for comparison */

    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * 256      // Store *coefficients[256]

    /* Load the precomputed values for computing Montgomery mulhi, mullo */

    ldr     MR_top, [x1, #4 * 0]    // Load precomputed B[0]
    ldr     MR_bot, [x2, #4 * 0]    // Load precomputed B'[0]

    1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #4 * 256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #4 * 256

    /* Check to verify loop condition idx < 256. It's cool to see that we can
     * directly compare X10 (X0) and X11 (X0 + #4 * 256). This is due to the
     * fact that we are working with pointers and not actual values. This allows
     * us to do cheap equality checks without having to execute load
     * instructions. */

    cmp     last, start             // Compare offset with *coefficients[256]
    b.ne    1b

    /* layer 2: length = 128, ridx = 1, loops = 2 */
    __asm_ntt_forward_layer 128, 1, 2

    /* layer 3: length = 64, ridx = 3, loops = 4 */
    __asm_ntt_forward_layer 64, 3, 4

    /* layer 4: length = 32, ridx = 7, loops = 8 */
    __asm_ntt_forward_layer 32, 7, 8

    /* layer 5: length = 16, ridx = 15, loops = 16 */
    __asm_ntt_forward_layer 16, 15, 16

    /* layer 6: length = 8, ridx = 31, loops = 32 */
    __asm_ntt_forward_layer 8, 31, 32

    /* layer 7: length = 4, ridx = 63, loops = 64 */
    __asm_ntt_forward_layer 4, 63, 64

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    ret     lr


/* length = 2, ridx = 127, loops = 128 */
__asm_ntt_forward_layer_8:

    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x1, x1, #4 * 127        // ridx, used for indexing B
    add     x2, x2, #4 * 127        // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    /* Load the precomputed roots */

    ldr     MR_top, [x1], #4        // B[0]
    mov     v7.4s[0], MR_top
    mov     v7.4s[1], MR_top

    ldr     MR_bot, [x2], #4        // B'[0]
    mov     v8.4s[0], MR_bot
    mov     v8.4s[1], MR_bot

    ldr     MR_top, [x1], #4        //  B[1]
    mov     v7.4s[2], MR_top
    mov     v7.4s[3], MR_top

    ldr     MR_bot, [x2], #4        //  B'[1]
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

    ret     lr


/* length = 1, ridx = 255, loops = 256 */
__asm_ntt_forward_layer_9:

    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x1, x1, #4 * 255        // ridx, used for indexing B
    add     x2, x2, #4 * 255        // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    ldr q7, [x1], #16               // Load precomputed B
    ldr q8, [x2], #16               // Load precomputed B'

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

    ret     lr


__asm_reduce_coefficients:

    /* Initialize and load constant values */

    mov	    w3, #0x9201
    movk    w3, #0x6a, lsl #16  // 6984193
    mov	    w4, #0x7a4b
    movk    w4, #0x133, lsl #16 // 20150859

    dup     v3.4s, w3           // Copy 6984193 into all 4 elements
    mov     v4.4s[0], w4
    add	    x1, x0, #4 * 512

    /* Loop over all coefficients */

    1:
    ldr	    q0, [x0]
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

    str	    q0, [x0], #16       // Store the result and move to next chunk
    cmp	    x1, x0              // Check whether we are done
    b.ne    1b

    ret     lr
