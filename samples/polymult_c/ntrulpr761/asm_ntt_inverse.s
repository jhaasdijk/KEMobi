/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_inverse
.type __asm_ntt_inverse, %function

/* Provide macro definitions */

.macro _asimd_add_sub q0, q1, q2, v0, v1, v2, addr, offset
    ldr     \q0, [\addr]            // Load coefficients[idx]
    ldr     \q1, [\addr, \offset]   // Load coefficients[idx + length]
    add     \v2, \v0, \v1           // temp + coefficients[idx + length]
    sub     \v1, \v0, \v1           // temp - coefficients[idx + length]
    str     \q2, [\addr]            // Store coefficients[idx]
.endm

.macro _asimd_mul_red q1, v0, v1, v2, v3, addr, offset
    sqdmulh \v2, \v1, \v0[0]        // Mulhi[a, B]
    mul     \v3, \v1, \v0[1]        // Mullo[a, B']
    sqdmulh \v3, \v3, \v0[2]        // Mulhi[M, Mullo[a, B']]
    sub     \v1, \v2, \v3           // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]
    str     \q1, [\addr, \offset]   // Store coefficients[idx + length]
    add     \addr, \addr, #16       // Move to the next chunk
.endm

.macro __asm_ntt_inverse_layer len, ridx, loops
    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * \len     // Store *coefficients[len]

    /* Store layer specific values  */

    add     x3, x1, #4 * \ridx      // ridx, used for indexing B
    add     x4, x2, #4 * \ridx      // ridx, used for indexing B'
    mov     x5, #1 * \loops         // loops (NTT_P / len / 2)

    ld1     {v7.s}[0], [x3], #4     // Load precomputed B
    ld1     {v7.s}[1], [x4], #4     // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for an inverse butterfly */

    _asimd_add_sub q0, q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * \len
    _asimd_mul_red q1, v7.4s v1.4s v2.4s v3.4s, start, #4 * \len

    cmp     last, start             // Check if we have reached the next chunk
    b.ne    1b

    add     start, last, #4 * \len  // Update pointer to next first coefficient
    add     last, last, #8 * \len   // Update pointer to next last coefficient

    ld1     {v7.s}[0], [x3], #4     // Load precomputed B
    ld1     {v7.s}[1], [x4], #4     // Load precomputed B'

    sub     x5, x5, #1              // Decrement loop counter by 1
    cmp     x5, #0                  // Check wether we are done
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

__asm_ntt_inverse:

    /* Alias registers for a specific purpose (and readability) */

    start   .req x10    // Store pointer to the first integer coefficient
    last    .req x11    // Store pointer to the last integer coefficient

    MR_top  .req w12    // Store the precomputed B value for _asimd_mul_red
    MR_bot  .req w13    // Store the precomputed B' value for _asimd_mul_red

    M       .req w14    // Store the constant value M = 6984193
    M_inv   .req w15    // Store the constant value M_inv = 20150859

    /* Initialize constant values */

    mov     M, #0x9201              // 6984193 (= M)
    movk    M, #0x6a, lsl #16

    mov     v7.4s[2], M             // M TODO : Redundant statement

    mov	    M_inv, #0x7a4b
    movk    M_inv, #0x133, lsl #16  // 20150859 (= M_inv)

    /* NTT inverse layer 9: length = 1, ridx = 0 */

    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x6, x1, #4 * 0          // ridx, used for indexing B
    add     x7, x2, #4 * 0          // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    ldr q5, [x6], #16               // Load precomputed B
    ldr q6, [x7], #16               // Load precomputed B'

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

    /* Execute _asimd_add_sub */

    add     v2.4s, v1.4s, v0.4s
    sub     v0.4s, v1.4s, v0.4s

    /* Execute _asimd_mul_red */

    sqdmulh v1.4s, v0.4s, v5.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v6.4s     // Mullo[a, B']
    sqdmulh v3.4s, v3.4s, v7.4s[2]  // Mulhi[M, Mullo[a, B']]
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

    /* NTT inverse layer 8: length = 2, ridx = 256 */

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x6, x1, #4 * 256        // ridx, used for indexing B
    add     x7, x2, #4 * 256        // ridx, used for indexing B'
    mov     x3, #1 * 64             // 512 / 8 = 64

    1:

    /* Load the precomputed roots */

    ld1     {v5.s}[0], [x6]
    ld1     {v5.s}[1], [x6], #4
    ld1     {v5.s}[2], [x6]
    ld1     {v5.s}[3], [x6], #4

    ld1     {v6.s}[0], [x7]
    ld1     {v6.s}[1], [x7], #4
    ld1     {v6.s}[2], [x7]
    ld1     {v6.s}[3], [x7], #4

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

    /* Execute _asimd_add_sub */

    add     v2.4s, v1.4s, v0.4s
    sub     v0.4s, v1.4s, v0.4s

    /* Execute _asimd_mul_red */

    sqdmulh v1.4s, v0.4s, v5.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v6.4s     // Mullo[a, B']
    sqdmulh v3.4s, v3.4s, v7.4s[2]  // Mulhi[M, Mullo[a, B']]
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

    /* NTT inverse layer 7: length = 4, ridx = 384, loops = 64 */
    __asm_ntt_inverse_layer 4, 384, 64

    /* NTT inverse layer 6: length = 8, ridx = 448, loops = 32 */
    __asm_ntt_inverse_layer 8, 448, 32

    /* NTT inverse layer 5: length = 16, ridx = 480, loops = 16 */
    __asm_ntt_inverse_layer 16, 480, 16

    /**
     * @brief Ensure that the coefficients stay within their allocated 32 bits
     *
     * Due to how the inverse NTT transformation is calculated, each layer
     * increases the possible bitsize of the integer coefficients by 1.
     * Performing 9 layers increases the possible bitsize of the integer
     * coefficients by 9. To ensure that the integer coefficients stay within
     * their allocated 32 bits we either 1) need to ensure that all values are
     * at most 23 bits at the start of the function or 2) perform an
     * intermediate reduction.
     */

    __asm_reduce_coefficients

    /* NTT inverse layer 4: length = 32, ridx = 496, loops = 8 */
    __asm_ntt_inverse_layer 32, 496, 8

    /* NTT inverse layer 3: length = 64, ridx = 504, loops = 4 */
    __asm_ntt_inverse_layer 64, 504, 4

    /* NTT inverse layer 2: length = 128, ridx = 508, loops = 2 */
    __asm_ntt_inverse_layer 128, 508, 2

    /* NTT inverse layer 1: length = 256, ridx = 510, loops = 1 */

    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * 256      // Store *coefficients[256]

    add     x3, x1, #4 * 510
    add     x4, x2, #4 * 510
    ld1     {v7.s}[0], [x3], #4     // Load precomputed B
    ld1     {v7.s}[1], [x4], #4     // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a inverse butterfly */

    _asimd_add_sub q0, q1, q2, v0.4s, v1.4s, v2.4s, start, #4 * 256
    _asimd_mul_red q1, v7.4s v1.4s v2.4s v3.4s, start, #4 * 256

    cmp     last, start             // Compare offset with *coefficients[256]
    b.ne    1b

    /* Multiply the result with the accumulated factor to complete the NTT */

    mov     start, x0
    add     last, x0, #4 * 512

    // 512^-1 mod 6984193     = 6970552
    // B  = 6970552 · R mod M = 4194304
    // B' = B · M' mod R      = 4194304

    mov     MR_top, #0x0000         // 4194304
    movk    MR_top, #0x40, lsl #16
    mov     v3.4s[0], MR_top

    2:

    ldr     q0, [start]             // Load coefficients[idx]
    sqdmulh v1.4s, v0.4s, v3.4s[0]  // Execute multiply_reduce
    mul     v2.4s, v0.4s, v3.4s[0]
    sqdmulh v2.4s, v2.4s, v7.4s[2]
    sub     v0.4s, v1.4s, v2.4s
    str     q0, [start], #16        // Store coefficients[idx]

    cmp     last, start
    b.ne    2b

    __asm_reduce_coefficients

    ret lr
