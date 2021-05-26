/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global forward_layer_1
.type forward_layer_1, %function

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

.macro multiply_reduce out, x, y
    smull   \out,  \x,    \y              // (int64_t) x * y
    mul     temp,  \x,    NTT_QINV        // (int32_t) x * NTT_QINV
    smaddl  \out,  temp,  NTT_Q,    \out  // x - (int64_t) temp * NTT_Q
    lsr     \out,  \out,  #32             // out >> 32
.endm

/* void forward_layer_1(int32_t *coefficients)
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

    /*
     * TODO : Think about register usage (e.g. use r0...r7 for intermediate
     * values as much as possible, this potentialy saves us from having to store
     * callee-saved registers)
     */

    /*
     * We are using 3 callee-saved registers (x19, x20, x21). Therefore we need
     * to ensure that their current values are stored on the stack. We do the
     * same for the procedure call link register (x30).
     */
    stp	    x19, x20, [sp, #-32]!
    mov	    x19, x0                 // Move coefficients[0] into register X19
    add	    x20, x0, #0x400         // Store coefficients[256] for comparison
    stp	    x21, x30, [sp, #16]

    /*
     * Move the first root (6672794) into register R21. Note that the move
     * instruction is only able to insert 16 bit immediate values into its
     * destination. We therefore need to split it up into a move of the lower 16
     * bits and a move (with keep) of the upper 7 bits.
     */
    mov	    w21, #0xd19a
    movk    w21, #0x65, lsl #16

    loop:

    /*
     * We need to provide multiply_reduce with the correct arguments. We move
     * the root into register W0 and coefficients[idx + 256] into register W1.
     * The latter is done using a pre-index 32-bit load instruction, i.e. the
     * address calculated is used immediately and does not replace the base
     * register.
     */
    mov	    w0, w21
    ldr	    w1, [x19, #1024]

    /* multiply_reduce (int64_t) out, (int32_t) x, (int32_t) y, Q_inv, Q */
    multiply_reduce x0, w0, w1, w2, w1

    ldr	    w1, [x19]        // Load coefficients[idx] into register W1
    sub	    w2, w1, w0       // coefficients[idx] - temp
    add	    w1, w1, w0       // coefficients[idx] + temp
    str	    w2, [x19, #1024] // Store coefficients[idx + 256]
    str	    w1, [x19], #4    // Store coefficients[idx] and move to next element
    cmp	    x20, x19         // Compare this element with coefficients[256]

    b.ne    loop

    /*
     * Restore the callee-saved registers and the procedure call link register
     * before returning control to our caller.
     */
    ldp	    x21, x30, [sp, #16]
    ldp	    x19, x20, [sp], #32
    ret
