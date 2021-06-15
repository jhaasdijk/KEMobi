/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_forward
.type __asm_ntt_forward, %function

/* Provide macro definitions */

.macro butterfly lower, upper, twiddle, t1, t2, t3
    /* _asimd_mul_red */
    sqdmulh \t1, \upper, \twiddle[0]
    mul     \t2, \upper, \twiddle[1]
    sqdmulh \t3, \t2, v28.4s[2]
    sub     \t1, \t1, \t3

    /* _asimd_sub_add */
    sub     \upper, \lower, \t1
    add     \lower, \lower, \t1
.endm

.macro __asm_ntt_forward_layer len, ridx, loops
    mov     start, x0               // Store *coefficients[0]
    add     last, x0, #4 * \len     // Store *coefficients[len]

    /* Store layer specific values  */

    add     x3, x1, #4 * \ridx      // ridx, used for indexing B
    add     x4, x2, #4 * \ridx      // ridx, used for indexing B'
    mov     loop_ctr, #1 * \loops   // loops (NTT_P / len / 2)

    ld1     {v28.s}[0], [x3], #4    // Load precomputed B
    ld1     {v28.s}[1], [x4], #4    // Load precomputed B'

    1:

    /* Perform the ASIMD arithmetic instructions for a forward butterfly */

    ldr     q1, [start, #4 * \len]  // Load the upper coefficients
    ldr     q0, [start]             // Load the lower coefficients

    butterfly v0.4s, v1.4s, v28.4s, v29.4s, v30.4s, v31.4s

    str     q1, [start, #4 * \len]  // Store the upper coefficients
    str     q0, [start], #16        // Store the lower coefficients and move to next chunk

    cmp     last, start             // Check if we have reached the next chunk
    b.ne    1b

    add     start, last, #4 * \len  // Update pointer to next first coefficient
    add     last, last, #8 * \len   // Update pointer to next last coefficient

    ld1     {v28.s}[0], [x3], #4    // Load next precomputed B
    ld1     {v28.s}[1], [x4], #4    // Load next precomputed B'

    sub loop_ctr, loop_ctr, #1      // Decrement loop counter
    cbnz loop_ctr, 1b               // Compare and Branch on Nonzero
.endm

__asm_ntt_forward:

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    /* Alias registers for a specific purpose (and readability) */

    loop_ctr .req x10

    start   .req x11    // Store pointer to the first integer coefficient
    last    .req x12    // Store pointer to the last integer coefficient

    MR_top  .req w13    // Store the precomputed B value for _asimd_mul_red
    MR_bot  .req w14    // Store the precomputed B' value for _asimd_mul_red

    M       .req w15    // Store the constant value M = 6984193

    /* Initialize constant values. Note that the move instruction is only able
     * to insert 16 bit immediate values into its destination. We therefore need
     * to split it up into a move of the lower 16 bits and a move (with keep) of
     * the upper 7 bits. */

    mov     M, #0x9201              // 6984193 (= M)
    movk    M, #0x6a, lsl #16
    mov     v28.4s[2], M             // Allocate M into a vector register


    /* Layers 1+2+3+4 */
    /* NTT forward layer 1: length = 256, ridx = 0, loops = 1 */
    /* NTT forward layer 2: length = 128, ridx = 1, loops = 2 */
    /* NTT forward layer 3: length = 64,  ridx = 3, loops = 4 */
    /* NTT forward layer 4: length = 32,  ridx = 7, loops = 8 */

    mov     start, x0               // Store *coefficients[0]
    mov     x3, x1
    mov     x4, x2

    ld1     {v26.s}[0], [x3], #4    // Load precomputed B[0]
    ld1     {v26.s}[1], [x4], #4    // Load precomputed B'[0]

    ld1     {v27.s}[0], [x3], #4    // Load precomputed B[1]
    ld1     {v27.s}[1], [x4], #4    // Load precomputed B'[1]

    ld1     {v28.s}[0], [x3], #4    // Load precomputed B[2]
    ld1     {v28.s}[1], [x4], #4    // Load precomputed B'[2]

    mov     loop_ctr, #8            // 32 / 4

    1:

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 32]
    ldr     q2, [start, #4 * 64]
    ldr     q3, [start, #4 * 96]

    ldr     q4, [start, #4 * 128]
    ldr     q5, [start, #4 * 160]
    ldr     q6, [start, #4 * 192]
    ldr     q7, [start, #4 * 224]

    ldr     q16, [start, #4 * 256]
    ldr     q17, [start, #4 * 288]
    ldr     q18, [start, #4 * 320]
    ldr     q19, [start, #4 * 352]

    ldr     q20, [start, #4 * 384]
    ldr     q21, [start, #4 * 416]
    ldr     q22, [start, #4 * 448]
    ldr     q23, [start, #4 * 480]

    // LAYER 1

    butterfly v0.4s, v16.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v1.4s, v17.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v2.4s, v18.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v3.4s, v19.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v4.4s, v20.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v5.4s, v21.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v6.4s, v22.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v7.4s, v23.4s, v26.4s, v29.4s, v30.4s, v31.4s

    // LAYER 2

    butterfly v0.4s, v4.4s, v27.4s, v29.4s, v30.4s, v31.4s
    butterfly v1.4s, v5.4s, v27.4s, v29.4s, v30.4s, v31.4s
    butterfly v2.4s, v6.4s, v27.4s, v29.4s, v30.4s, v31.4s
    butterfly v3.4s, v7.4s, v27.4s, v29.4s, v30.4s, v31.4s

    butterfly v16.4s, v20.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v17.4s, v21.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v18.4s, v22.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v19.4s, v23.4s, v28.4s, v29.4s, v30.4s, v31.4s

    str     q0, [start, #4 * 0]
    str     q1, [start, #4 * 32]
    str     q2, [start, #4 * 64]
    str     q3, [start, #4 * 96]

    str     q4, [start, #4 * 128]
    str     q5, [start, #4 * 160]
    str     q6, [start, #4 * 192]
    str     q7, [start, #4 * 224]

    str     q16, [start, #4 * 256]
    str     q17, [start, #4 * 288]
    str     q18, [start, #4 * 320]
    str     q19, [start, #4 * 352]

    str     q20, [start, #4 * 384]
    str     q21, [start, #4 * 416]
    str     q22, [start, #4 * 448]
    str     q23, [start, #4 * 480]

    add start, start, #16           // Move to the next chunk

    sub loop_ctr, loop_ctr, #1      // Decrement loop counter
    cbnz loop_ctr, 1b               // Compare and Branch on Nonzero




    // LAYER 3+4

    mov     start, x0               // Store *coefficients[0]

    add     x3, x1, #4 * 3          // ridx, used for indexing B
    add     x4, x2, #4 * 3          // ridx, used for indexing B'
    add     x5, x1, #4 * 7          // ridx, used for indexing B
    add     x6, x2, #4 * 7          // ridx, used for indexing B'

    ld1     {v26.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v26.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v27.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v27.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v28.s}[0], [x3], #4     // Load (next) precomputed B
    ld1     {v28.s}[1], [x4], #4     // Load (next) precomputed B'

    .rept 8

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 32]
    ldr     q2, [start, #4 * 64]
    ldr     q3, [start, #4 * 96]

    butterfly v0.4s, v2.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v1.4s, v3.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v0.4s, v1.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v2.4s, v3.4s, v27.4s, v29.4s, v30.4s, v31.4s

    str     q0, [start, #4 * 0]
    str     q1, [start, #4 * 32]
    str     q2, [start, #4 * 64]
    str     q3, [start, #4 * 96]

    add start, start, #16           // Move to the next chunk

    .endr

    ld1     {v26.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v26.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v27.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v27.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v28.s}[0], [x3], #4     // Load (next) precomputed B
    ld1     {v28.s}[1], [x4], #4     // Load (next) precomputed B'

    .rept 8

    ldr     q4, [start, #4 * 96]
    ldr     q5, [start, #4 * 128]
    ldr     q6, [start, #4 * 160]
    ldr     q7, [start, #4 * 192]

    butterfly v4.4s, v6.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v5.4s, v7.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v4.4s, v5.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v6.4s, v7.4s, v27.4s, v29.4s, v30.4s, v31.4s

    str     q4, [start, #4 * 96]
    str     q5, [start, #4 * 128]
    str     q6, [start, #4 * 160]
    str     q7, [start, #4 * 192]

    add start, start, #16           // Move to the next chunk

    .endr

    ld1     {v26.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v26.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v27.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v27.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v28.s}[0], [x3], #4     // Load (next) precomputed B
    ld1     {v28.s}[1], [x4], #4     // Load (next) precomputed B'

    .rept 8

    ldr     q16, [start, #4 * 192]
    ldr     q17, [start, #4 * 224]
    ldr     q18, [start, #4 * 256]
    ldr     q19, [start, #4 * 288]

    butterfly v16.4s, v18.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v17.4s, v19.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v16.4s, v17.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v18.4s, v19.4s, v27.4s, v29.4s, v30.4s, v31.4s

    str     q16, [start, #4 * 192]
    str     q17, [start, #4 * 224]
    str     q18, [start, #4 * 256]
    str     q19, [start, #4 * 288]

    add start, start, #16           // Move to the next chunk

    .endr

    ld1     {v26.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v26.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v27.s}[0], [x5], #4     // Load (next) precomputed B
    ld1     {v27.s}[1], [x6], #4     // Load (next) precomputed B'
    ld1     {v28.s}[0], [x3], #4     // Load (next) precomputed B
    ld1     {v28.s}[1], [x4], #4     // Load (next) precomputed B'

    .rept 8

    ldr     q20, [start, #4 * 288]
    ldr     q21, [start, #4 * 320]
    ldr     q22, [start, #4 * 352]
    ldr     q23, [start, #4 * 384]

    butterfly v20.4s, v22.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v21.4s, v23.4s, v28.4s, v29.4s, v30.4s, v31.4s
    butterfly v20.4s, v21.4s, v26.4s, v29.4s, v30.4s, v31.4s
    butterfly v22.4s, v23.4s, v27.4s, v29.4s, v30.4s, v31.4s

    str     q20, [start, #4 * 288]
    str     q21, [start, #4 * 320]
    str     q22, [start, #4 * 352]
    str     q23, [start, #4 * 384]

    add start, start, #16           // Move to the next chunk

    .endr





    /* NTT forward layer 5: length = 16, ridx = 15, loops = 16 */
    __asm_ntt_forward_layer 16, 15, 16

    /* NTT forward layer 6: length = 8, ridx = 31, loops = 32 */
    __asm_ntt_forward_layer 8, 31, 32

    /* NTT forward layer 7: length = 4, ridx = 63, loops = 64 */
    __asm_ntt_forward_layer 4, 63, 64

    /* NTT forward layer 8: length = 2, ridx = 127, loops = 128 */

    start_l .req x11
    start_s .req x12

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x6, x1, #4 * 127        // ridx, used for indexing B
    add     x7, x2, #4 * 127        // ridx, used for indexing B'
    mov     loop_ctr, #1 * 64       // 512 / 8 = 64

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

    /* Execute _asimd_mul_red */

    sqdmulh v2.4s, v0.4s, v5.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v6.4s     // Mullo[a, B']
    sqdmulh v3.4s, v3.4s, v28.4s[2]  // Mulhi[M, Mullo[a, B']]
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

    sub     loop_ctr, loop_ctr, #1  // Decrement loop counter by 1
    cbnz    loop_ctr, 1b            // Compare and Branch on Nonzero

    /* NTT forward layer 9: length = 1, ridx = 255, loops = 256 */

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x6, x1, #4 * 255        // ridx, used for indexing B
    add     x7, x2, #4 * 255        // ridx, used for indexing B'
    mov     loop_ctr, #1 * 64       // 512 / 8 = 64

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

    /* Execute _asimd_mul_red */

    sqdmulh v2.4s, v0.4s, v5.4s     // Mulhi[a, B]
    mul     v3.4s, v0.4s, v6.4s     // Mullo[a, B']
    sqdmulh v3.4s, v3.4s, v28.4s[2]  // Mulhi[M, Mullo[a, B']]
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

    sub     loop_ctr, loop_ctr, #1  // Decrement loop counter by 1
    cbnz    loop_ctr, 1b            // Compare and Branch on Nonzero

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    ret     lr
