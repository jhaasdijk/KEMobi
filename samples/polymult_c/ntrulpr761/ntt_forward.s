/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global forward_layer_1
.global forward_layer_2
.global forward_layer_3

.type forward_layer_1, %function
.type forward_layer_2, %function
.type forward_layer_3, %function

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
.macro asimd_arith lowerQt, lowerS4, upperQt, upperS4, temp, addr, offset
    ldr     \lowerQt, [\addr]           // Load the lower coefficients
    sub     \upperS4, \lowerS4, \temp   // coefficients[idx] - temp
    add     \lowerS4, \lowerS4, \temp   // coefficients[idx] + temp
    str     \upperQt, [\addr, \offset]  // Store the upper coefficients
    str     \lowerQt, [\addr], #16      // Store the lower coefficients and move to next chunk
.endm

/*
 * void forward_layer_1(int32_t *coefficients)
 * {
 *     int32_t temp;
 *
 *     for (size_t idx = 0; idx < 256; idx++)
 *     {
 *         temp = multiply_reduce(6672794, coefficients[idx + 256]);
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

forward_layer_1:

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    mov     x10, x0             // Store *coefficients[0]
    add     x11, x0, #0x400     // Store *coefficients[256] for comparison

    // TODO : Move this outside of a specific layer and into ntt_forward()
    /* Alias registers for a specific purpose (and readability) */

    root    .req w12    // Use temporary register W12 to store our roots
    temp    .req w13    // Use register W13 as a generic temporary store

    NTT_QINV    .req w14    // Use temporary register W14 to store NTT_QINV
    NTT_Q       .req w15    // Use temporary register W15 to store -NTT_Q

    mov     NTT_QINV, #0x6e01
    movk    NTT_QINV, #0x72d9, lsl #16  // 1926852097 (= NTT_QINV)
    mov     NTT_Q, #0x6dff
    movk    NTT_Q, #0xff95, lsl #16     // 4287983103 (= -NTT_Q)

    /* Move root[0] = 6672794 into register W12. Note that the move instruction
     * is only able to insert 16 bit immediate values into its destination. We
     * therefore need to split it up into a move of the lower 16 bits and a move
     * (with keep) of the upper 7 bits. */

    mov     root, #0xd19a
    movk    root, #0x65, lsl #16

    loop256_0:

    /* We need to provide multiply_reduce with the correct arguments. The root
     * (singular) is already in place. We move the coefficients into registers
     * W0, W1, W2 and W3. This is done using a pre-index 32-bit load
     * instruction, i.e. the address calculated is used immediately and does not
     * replace the base register. */

    // mulhi(a, B) - mulhi(M * mullo(a, B'))
    // We are working with roots = [1] as this is the first forward layer
    // M = 6984193, M_inv = 1926852097, R = 2147483648 (= 2^31)
    // B  = b * R mod M              = [(_ * R) % M for _ in roots]
    // B' = (b * R mod M) * M' mod R = [(_ * M_inv) % R for _ in B]

    ldr     q0, [x10, #1024]        // coefficients[_ + 256]

    mov     w5, #0xe8cd             // 3336397 = B[0]
    movk    w5, #0x32, lsl #16

    mov     w6, #0xfecd             // -307 = B'[0]
    movk    w6, #0x7fff, lsl #16

    mov     w7, #0x9201             // 6984193 = M
    movk    w7, #0x6a, lsl #16

    mov     v1.4s[0], w5
    sqdmulh v2.4s, v0.4s, v1.4s[0]  // mulhi(a, B)

    mov     v1.4s[0], w6
    mul     v3.4s, v0.4s, v1.4s[0]  // mullo(a, B')

    mov     v1.4s[0], w7
    sqdmulh v3.4s, v3.4s, v1.4s[0]  // mulhi(M, _)

    sub     v0.4s, v2.4s, v3.4s     // mulhi(a, B) - mulhi(M, _)

    /* Perform ASIMD arith instructions */

    ldr     q1, [x10]           // Load coefficients[_ : _ + 3] into register Q1
    sub     v2.4s, v1.4s, v0.4s // coefficients - temp
    add     v1.4s, v1.4s, v0.4s // coefficients + temp
    str     q2, [x10, #1024]    // Store coefficients[_ + 256]
    str     q1, [x10], #16      // Store coefficients[_] and move to next chunk

    /* It's cool to see that we can directly compare X10 (X0) and X11 (X0 +
     * #0x400). This is due to the fact that we are working with pointers and
     * not actual values. This allows us to do cheap equality checks without
     * having to execute load instructions. */

    cmp     x11, x10            // Compare offset with *coefficients[256]
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
 *        temp = multiply_reduce(6672794, coefficients[idx + 128]);
 *        coefficients[idx + 128] = coefficients[idx] - temp;
 *        coefficients[idx] = coefficients[idx] + temp;
 *    }
 *
 *    for (size_t idx = 256; idx < 384; idx++)
 *    {
 *        temp = multiply_reduce(3471433, coefficients[idx + 128]);
 *        coefficients[idx + 128] = coefficients[idx] - temp;
 *        coefficients[idx] = coefficients[idx] + temp;
 *    }
 * }
 */

forward_layer_2:

    mov     x10, x0             // Store *coefficients[0]
    add     x11, x0, #0x200     // Store *coefficients[128] for comparison

    /* Move root[1] = 6672794 into register W12 */
    /* Note that we could skip this as root[0] == root[1] */

    mov     root, #0xd19a
    movk    root, #0x65, lsl #16

    loop128_0:

    /* Load 4 32 bit integer coefficients into registers W0, W1, W2 and W3 */

    load_values w0, w1, w2, w3, x10, #512

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, (int32_t) temp */

    // TODO : Vectorize multiply_reduce

    /* (int64_t) x * y */
    smull   x0, w0, root
    smull   x1, w1, root
    smull   x2, w2, root
    smull   x3, w3, root

    /* temp = (int32_t) x * NTT_QINV */
    mul     w4, w0, NTT_QINV
    mul     w5, w1, NTT_QINV
    mul     w6, w2, NTT_QINV
    mul     w7, w3, NTT_QINV

    /* x - (int64_t) temp * NTT_Q */
    smaddl  x0, w4, NTT_Q, x0
    smaddl  x1, w5, NTT_Q, x1
    smaddl  x2, w6, NTT_Q, x2
    smaddl  x3, w7, NTT_Q, x3

    /* out >> 32 */
    lsr     x0, x0, #32
    lsr     x1, x1, #32
    lsr     x2, x2, #32
    lsr     x3, x3, #32

    /* The results are stored in W0, W1, W2, W3, move them into register Q0 */

    move_values_into_vector w0, w1, w2, w3, v0.s

    /* Perform ASIMD arith instructions */
    /* asimd_arith lowerQt, lowerS4, upperQt, upperS4, temp, addr, offset */

    asimd_arith q1, v1.4s, q2, v2.4s, v0.4s, x10, #512

    cmp     x11, x10            // Compare offset with *coefficients[128]
    b.ne    loop128_0

    add     x10, x11, #0x200    // Store *coefficients[256]
    add     x11, x11, #0x400    // Store *coefficients[384] for comparison

    /* Move root[2] = 3471433 into register W12 */

    mov	    root, #0xf849
    movk    root, #0x34, lsl #16

    loop128_1:

    /* Load 4 32 bit integer coefficients into registers W0, W1, W2 and W3 */

    load_values w0, w1, w2, w3, x10, #512

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, (int32_t) temp */

    multiply_reduce x0, w0, root
    multiply_reduce x1, w1, root
    multiply_reduce x2, w2, root
    multiply_reduce x3, w3, root

    /* The results are stored in W0, W1, W2, W3, move them into register Q0 */

    move_values_into_vector w0, w1, w2, w3, v0.s

    /* Perform ASIMD arith instructions */
    /* asimd_arith lowerQt, lowerS4, upperQt, upperS4, temp, addr, offset */

    asimd_arith q1, v1.4s, q2, v2.4s, v0.4s, x10, #512

    cmp     x11, x10            // Compare offset with *coefficients[384]
    b.ne    loop128_1

    ret     lr

/*
 * void forward_layer_3(int32_t *coefficients)
 * {
 *     int32_t temp;
 *
 *     for (size_t idx = 0; idx < 64; idx++)
 *     {
 *         temp = multiply_reduce(6672794, coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 *     for (size_t idx = 128; idx < 192; idx++)
 *     {
 *         temp = multiply_reduce(3471433, coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 *     for (size_t idx = 256; idx < 320; idx++)
 *     {
 *         temp = multiply_reduce(4089706, coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 *     for (size_t idx = 384; idx < 448; idx++)
 *     {
 *         temp = multiply_reduce(2592208, coefficients[idx + 64]);
 *         coefficients[idx + 64] = coefficients[idx] - temp;
 *         coefficients[idx] = coefficients[idx] + temp;
 *     }
 * }
 */

forward_layer_3:

    mov     x10, x0             // Store *coefficients[0]
    add     x11, x0, #0x100     // Store *coefficients[64] for comparison
    mov     root, #0xd19a       // Move root[3] = 6672794 into register W12
    movk    root, #0x65, lsl #16

    loop64_0:

    /* Move 4 32 bit integer coefficients into registers W0, W1, W2 and W3 */
    load_values w0, w1, w2, w3, x10, #256

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, (int32_t) temp */
    multiply_reduce x0, w0, root
    multiply_reduce x1, w1, root
    multiply_reduce x2, w2, root
    multiply_reduce x3, w3, root

    /* The results are stored in W0, W1, W2, W3, move them into register Q0 */
    move_values_into_vector w0, w1, w2, w3, v0.s

    /* Perform ASIMD arith instructions */
    asimd_arith q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10            // Compare offset with *coefficients[64]
    b.ne    loop64_0

    add     x10, x11, #0x100    // Store *coefficients[128]
    add     x11, x11, #0x200    // Store *coefficients[192] for comparison
    mov	    root, #0xf849       // Move root[4] = 3471433 into register W12
    movk    root, #0x34, lsl #16

    loop64_1:

    /* Move 4 32 bit integer coefficients into registers W0, W1, W2 and W3 */
    load_values w0, w1, w2, w3, x10, #256

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, (int32_t) temp */
    multiply_reduce x0, w0, root
    multiply_reduce x1, w1, root
    multiply_reduce x2, w2, root
    multiply_reduce x3, w3, root

    /* The results are stored in W0, W1, W2, W3, move them into register Q0 */
    move_values_into_vector w0, w1, w2, w3, v0.s

    /* Perform ASIMD arith instructions */
    asimd_arith q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10            // Compare offset with *coefficients[192]
    b.ne    loop64_1

    add     x10, x11, #0x100    // Store *coefficients[256]
    add     x11, x11, #0x200    // Store *coefficients[320] for comparison
    mov	    root, #0x676a       // Move root[5] = 4089706 into register W12
    movk    root, #0x3e, lsl #16

    loop64_2:

    /* Move 4 32 bit integer coefficients into registers W0, W1, W2 and W3 */
    load_values w0, w1, w2, w3, x10, #256

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, (int32_t) temp */
    multiply_reduce x0, w0, root
    multiply_reduce x1, w1, root
    multiply_reduce x2, w2, root
    multiply_reduce x3, w3, root

    /* The results are stored in W0, W1, W2, W3, move them into register Q0 */
    move_values_into_vector w0, w1, w2, w3, v0.s

    /* Perform ASIMD arith instructions */
    asimd_arith q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10            // Compare offset with *coefficients[320]
    b.ne    loop64_2

    add     x10, x11, #0x100    // Store *coefficients[384]
    add     x11, x11, #0x200    // Store *coefficients[448] for comparison
    mov	    root, #0x8dd0       // Move root[6] = 2592208 into register W12
    movk    root, #0x27, lsl #16

    loop64_3:

    /* Move 4 32 bit integer coefficients into registers W0, W1, W2 and W3 */
    load_values w0, w1, w2, w3, x10, #256

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, (int32_t) temp */
    multiply_reduce x0, w0, root
    multiply_reduce x1, w1, root
    multiply_reduce x2, w2, root
    multiply_reduce x3, w3, root

    /* The results are stored in W0, W1, W2, W3, move them into register Q0 */
    move_values_into_vector w0, w1, w2, w3, v0.s

    /* Perform ASIMD arith instructions */
    asimd_arith q1, v1.4s, q2, v2.4s, v0.4s, x10, #256

    cmp     x11, x10            // Compare offset with *coefficients[448]
    b.ne    loop64_3

    ret     lr
