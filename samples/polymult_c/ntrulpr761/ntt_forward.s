/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_forward_setup
.global __asm_ntt_forward_layer_1
.global __asm_ntt_forward_layer_2
.global __asm_ntt_forward_layer_3

.type __asm_ntt_forward_setup, %function
.type __asm_ntt_forward_layer_1, %function
.type __asm_ntt_forward_layer_2, %function
.type __asm_ntt_forward_layer_3, %function

/* Provide macro definitions */

/*
 * int32_t montgomery_reduce(int64_t x)
 * {
 *     int32_t out;
 *     out = (int32_t)x * NTT_QINV;
 *     out = (int32_t)((x - (int64_t)out * NTT_Q) >> 32);
 *     return out;
 * }
 *
 * int32_t multiply_reduce(int32_t x, int32_t y)
 * {
 *     return montgomery_reduce((int64_t)x * y);
 * }
 */

/* Multiply x, y and reduce the result using Montgomery reduction */
.macro multiply_reduce out, x, y
    smull   \out,  \x,    \y              // (int64_t) x * y
    mul     temp,  \x,    NTT_QINV        // (int32_t) x * NTT_QINV
    smaddl  \out,  temp,  NTT_Q,    \out  // x - (int64_t) temp * NTT_Q
    lsr     \out,  \out,  #32             // out >> 32
.endm

/* Load 4 consecutive 32-bit integer coefficients */
.macro load_values w0, w1, w2, w3, addr, offset
    ldr	    \w0, [\addr, \offset]
    ldr	    \w1, [\addr, \offset + 4]
    ldr	    \w2, [\addr, \offset + 8]
    ldr	    \w3, [\addr, \offset + 12]
.endm

/* Move 4 32-bit integer coefficients into a SIMD register */
.macro move_values_into_vector w0, w1, w2, w3, v0
    mov     \v0[0], \w0
    mov     \v0[1], \w1
    mov     \v0[2], \w2
    mov     \v0[3], \w3
.endm

/* Perform the ASIMD arith instructions for a forward butterfly */
.macro _asimd_sub_add lowerQt, lowerS4, upperQt, upperS4, temp, addr, offset
    ldr     \lowerQt, [\addr]           // Load the lower coefficients
    sub     \upperS4, \lowerS4, \temp   // coefficients[idx] - temp
    add     \lowerS4, \lowerS4, \temp   // coefficients[idx] + temp
    str     \upperQt, [\addr, \offset]  // Store the upper coefficients
    str     \lowerQt, [\addr], #16      // Store the lower coefficients and move to next chunk
.endm

__asm_ntt_forward_setup:

    /* Alias registers for a specific purpose (and readability) */

    MR_top      .req w6         // TODO : Explain usage
    MR_bot      .req w7         // TODO : Explain usage

    M           .req w13        // Use temporary register W13 to store M

    NTT_QINV    .req w14        // Use temporary register W14 to store NTT_QINV
    NTT_Q       .req w15        // Use temporary register W15 to store -NTT_Q

    /* Initialize constant values. Note that the move instruction is only able
     * to insert 16 bit immediate values into its destination. We therefore need
     * to split it up into a move of the lower 16 bits and a move (with keep) of
     * the upper 7 bits. */

    mov     M, #0x9201          // 6984193    (= M)
    movk    M, #0x6a, lsl #16

    mov     NTT_QINV, #0x6e01   // 1926852097 (= NTT_QINV)
    movk    NTT_QINV, #0x72d9, lsl #16

    mov     NTT_Q, #0x6dff      // 4287983103 (= -NTT_Q)
    movk    NTT_Q, #0xff95, lsl #16

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

__asm_ntt_forward_layer_1:

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    /* Store the coefficients pointer and an offset for comparison */

    mov     x10, x0                 // Store *coefficients[0]
    add     x11, x0, #4 * 256       // Store *coefficients[256]

    /* Load the precomputed values for computing Montgomery mulhi, mullo */

    ldr     MR_top, [x1, #4 * 0]    // Store MR_top[0]
    ldr     MR_bot, [x2, #4 * 0]    // Store MR_bot[0]

    loop256_0:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #1024
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #1024

    /* Check to verify loop condition idx < 256. It's cool to see that we can
     * directly compare X10 (X0) and X11 (X0 + #4 * 256). This is due to the
     * fact that we are working with pointers and not actual values. This allows
     * us to do cheap equality checks without having to execute load
     * instructions. */

    cmp     x11, x10                // Compare offset with *coefficients[256]
    b.ne    loop256_0

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    ret     lr

/*
 * void forward_layer_2(int32_t *coefficients)
 * {
 *    int32_t temp;
 *
 *    for (size_t idx = 0; idx < 128; idx++)
 *    {
 *        temp = multiply_reduce(zeta[1], coefficients[idx + 128]);
 *        coefficients[idx + 128] = coefficients[idx] - temp;
 *        coefficients[idx] = coefficients[idx] + temp;
 *    }
 *
 *    for (size_t idx = 256; idx < 384; idx++)
 *    {
 *        temp = multiply_reduce(zeta[2], coefficients[idx + 128]);
 *        coefficients[idx + 128] = coefficients[idx] - temp;
 *        coefficients[idx] = coefficients[idx] + temp;
 *    }
 * }
 */

__asm_ntt_forward_layer_2:

    mov     x10, x0                 // Store *coefficients[0]
    add     x11, x0, #4 * 128       // Store *coefficients[128] for comparison

    ldr     MR_top, [x1, #4 * 1]    // Store MR_top[1]
    ldr     MR_bot, [x2, #4 * 1]    // Store MR_bot[1]

    loop128_0:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #512
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #512

    cmp     x11, x10                // Compare offset with *coefficients[128]
    b.ne    loop128_0

    add     x10, x11, #4 * 128      // Store *coefficients[256]
    add     x11, x11, #4 * 256      // Store *coefficients[384] for comparison

    ldr     MR_top, [x1, #4 * 2]    // Store MR_top[2]
    ldr     MR_bot, [x2, #4 * 2]    // Store MR_bot[2]

    loop128_1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #512
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #512

    cmp     x11, x10                // Compare offset with *coefficients[384]
    b.ne    loop128_1

    ret     lr

/*
 * void forward_layer_3(int32_t *coefficients)
 * {
 *     int32_t temp;
 *
 *     for (size_t idx = 0; idx < 64; idx++)
 *     {
 *         temp = multiply_reduce(zeta[3], coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 *     for (size_t idx = 128; idx < 192; idx++)
 *     {
 *         temp = multiply_reduce(zeta[4], coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 *     for (size_t idx = 256; idx < 320; idx++)
 *     {
 *         temp = multiply_reduce(zeta[5], coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 *     for (size_t idx = 384; idx < 448; idx++)
 *     {
 *         temp = multiply_reduce(zeta[6], coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 * }
 */

__asm_ntt_forward_layer_3:

    mov     x10, x0                 // Store *coefficients[0]
    add     x11, x0, #4 * 64        // Store *coefficients[64] for comparison

    ldr     MR_top, [x1, #4 * 3]    // Store MR_top[3]
    ldr     MR_bot, [x2, #4 * 3]    // Store MR_bot[3]

    loop64_0:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10                // Compare offset with *coefficients[64]
    b.ne    loop64_0

    add     x10, x11, #4 * 64       // Store *coefficients[128]
    add     x11, x11, #4 * 128      // Store *coefficients[192] for comparison

    ldr     MR_top, [x1, #4 * 4]    // Store MR_top[4]
    ldr     MR_bot, [x2, #4 * 4]    // Store MR_bot[4]

    loop64_1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10                // Compare offset with *coefficients[192]
    b.ne    loop64_1

    add     x10, x11, #4 * 64       // Store *coefficients[256]
    add     x11, x11, #4 * 128      // Store *coefficients[320] for comparison

    ldr     MR_top, [x1, #4 * 5]    // Store MR_top[5]
    ldr     MR_bot, [x2, #4 * 5]    // Store MR_bot[5]

    loop64_2:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10                // Compare offset with *coefficients[320]
    b.ne    loop64_2

    add     x10, x11, #4 * 64       // Store *coefficients[384]
    add     x11, x11, #4 * 128      // Store *coefficients[448] for comparison

    ldr     MR_top, [x1, #4 * 6]    // Store MR_top[6]
    ldr     MR_bot, [x2, #4 * 6]    // Store MR_bot[6]

    loop64_3:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, x10, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10                // Compare offset with *coefficients[448]
    b.ne    loop64_3

    ret     lr
