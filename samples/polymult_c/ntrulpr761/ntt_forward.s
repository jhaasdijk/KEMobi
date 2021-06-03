/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_forward_setup
.global __asm_ntt_forward_layer_1
.global __asm_ntt_forward_layer_2
.global __asm_ntt_forward_layer_3
.global __asm_ntt_forward_layer_4

.type __asm_ntt_forward_setup, %function
.type __asm_ntt_forward_layer_1, %function
.type __asm_ntt_forward_layer_2, %function
.type __asm_ntt_forward_layer_3, %function
.type __asm_ntt_forward_layer_4, %function

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

    add     x1, x1, #4 * \ridx          // ridx, used for indexing B
    add     x2, x2, #4 * \ridx          // ridx, used for indexing B'
    mov     x3, #1 * \loops             // loops (NTT_P / length / 2)

    ldr     MR_top, [x1], #4            // Load precomputed B
    ldr     MR_bot, [x2], #4            // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #4 * \length
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #4 * \length

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

__asm_ntt_forward_setup:

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

__asm_ntt_forward_layer_1:

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    /* Store the coefficients pointer and an offset for comparison */

    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * 256      // Store *coefficients[256]

    /* Load the precomputed values for computing Montgomery mulhi, mullo */

    ldr     MR_top, [x1, #4 * 0]    // Store MR_top[0]
    ldr     MR_bot, [x2, #4 * 0]    // Store MR_bot[0]

    loop256:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #1024
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #1024

    /* Check to verify loop condition idx < 256. It's cool to see that we can
     * directly compare X10 (X0) and X11 (X0 + #4 * 256). This is due to the
     * fact that we are working with pointers and not actual values. This allows
     * us to do cheap equality checks without having to execute load
     * instructions. */

    cmp     last, start             // Compare offset with *coefficients[256]
    b.ne    loop256

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

    mov     start, x0               // Store *coefficients[0]
    add     length, x0, #4 * 128    // Store *coefficients[128] for comparison

    ldr     MR_top, [x1, #4 * 1]    // Store MR_top[1]
    ldr     MR_bot, [x2, #4 * 1]    // Store MR_bot[1]

    loop128_0:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #512
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #512

    cmp     length, start           // Compare offset with *coefficients[128]
    b.ne    loop128_0

    add     start, length, #4 * 128     // Store *coefficients[256]
    add     length, length, #4 * 256    // Store *coefficients[384] for comparison

    ldr     MR_top, [x1, #4 * 2]    // Store MR_top[2]
    ldr     MR_bot, [x2, #4 * 2]    // Store MR_bot[2]

    loop128_1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #512
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #512

    cmp     length, start           // Compare offset with *coefficients[384]
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

    mov     start, x0               // Store *coefficients[0]
    add     length, x0, #4 * 64     // Store *coefficients[64] for comparison

    ldr     MR_top, [x1, #4 * 3]    // Store MR_top[3]
    ldr     MR_bot, [x2, #4 * 3]    // Store MR_bot[3]

    loop64_0:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #256

    cmp     length, start           // Compare offset with *coefficients[64]
    b.ne    loop64_0

    add     start, length, #4 * 64      // Store *coefficients[128]
    add     length, length, #4 * 128    // Store *coefficients[192] for comparison

    ldr     MR_top, [x1, #4 * 4]    // Store MR_top[4]
    ldr     MR_bot, [x2, #4 * 4]    // Store MR_bot[4]

    loop64_1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #256

    cmp     length, start           // Compare offset with *coefficients[192]
    b.ne    loop64_1

    add     start, length, #4 * 64      // Store *coefficients[256]
    add     length, length, #4 * 128    // Store *coefficients[320] for comparison

    ldr     MR_top, [x1, #4 * 5]    // Store MR_top[5]
    ldr     MR_bot, [x2, #4 * 5]    // Store MR_bot[5]

    loop64_2:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #256

    cmp     length, start           // Compare offset with *coefficients[320]
    b.ne    loop64_2

    add     start, length, #4 * 64      // Store *coefficients[384]
    add     length, length, #4 * 128    // Store *coefficients[448] for comparison

    ldr     MR_top, [x1, #4 * 6]    // Store MR_top[6]
    ldr     MR_bot, [x2, #4 * 6]    // Store MR_bot[6]

    loop64_3:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #256
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #256

    cmp     length, start           // Compare offset with *coefficients[448]
    b.ne    loop64_3

    ret     lr

__asm_ntt_forward_layer_4:

    mov     start, x0               // Store *coefficients[0]
    add     length, x0, #4 * 32     // Store *coefficients[32] for comparison

    /* Store layer specific values  */

    add     x1, x1, #4 * 7          // ridx = 7, used for indexing B
    add     x2, x2, #4 * 7          // ridx = 7, used for indexing B'
    mov     x3, #8                  // loops = 8 (NTT_P / length / 2)

    ldr     MR_top, [x1], #4        // Load precomputed B
    ldr     MR_bot, [x2], #4        // Load precomputed B'

    loop32:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    _asimd_mul_red q0, v0.4s, v1.4s, v2.4s, v3.4s, start, #128
    _asimd_sub_add q1, v1.4s, q2, v2.4s, v0.4s, start, #128

    cmp     length, start           // Check if we have reached the next chunk
    b.ne    loop32

    add     start, length, #4 * 32  // Update pointer to next first coefficient
    add     length, length, #4 * 64 // Update pointer to next last coefficient

    ldr     MR_top, [x1], #4        // Load precomputed B
    ldr     MR_bot, [x2], #4        // Load precomputed B'

    sub     x3, x3, #1              // Decrement loop counter by 1
    cmp     x3, #0                  // Check wether we are done
    b.ne    loop32

    ret     lr