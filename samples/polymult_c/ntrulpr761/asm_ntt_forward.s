/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_forward
.type __asm_ntt_forward, %function

/* Provide macro definitions */

.macro butterfly lower, upper, twid1, twid2, t1, t2
    /* _asimd_mul_red */
    sqdmulh \t1, \upper, \twid1
    mul     \t2, \upper, \twid2
    sqdmulh \t2, \t2, v28.4s[2]
    sub     \t1, \t1, \t2

    /* _asimd_sub_add */
    sub     \upper, \lower, \t1
    add     \lower, \lower, \t1
.endm

__asm_ntt_forward:

    /* Due to our choice of registers we do not need (to store) callee-saved
     * registers. Neither do we use the procedure link register, as we do not
     * branch to any functions from within this subroutine. The function
     * prologue is therefore empty. */

    /* Alias registers for a specific purpose (and readability) */

    start   .req x14    // Store pointer to the first integer coefficient
    M       .req w15    // Store the constant value M = 6984193

    /* Initialize constant values. Note that the move instruction is only able
     * to insert 16 bit immediate values into its destination. We therefore need
     * to split it up into a move of the lower 16 bits and a move (with keep) of
     * the upper 7 bits. */

    mov     M, #0x9201              // 6984193 (= M)
    movk    M, #0x6a, lsl #16
    mov     v28.4s[2], M            // Allocate M into a vector register

    /* Layers 1+2+3+4 */
    /* NTT forward layer 1: length = 256, ridx = 0, loops = 1 */
    /* NTT forward layer 2: length = 128, ridx = 1, loops = 2 */
    /* NTT forward layer 3: length = 64,  ridx = 3, loops = 4 */
    /* NTT forward layer 4: length = 32,  ridx = 7, loops = 8 */

    mov     start, x0               // Store *coefficients[0]

    /* Store layer specific values  */

    add     x3, x1, #4 * 7          // Store *B[7]
    add     x4, x2, #4 * 7          // Store *B'[7]

    /* Preload the required root values, we have enough room */
    /* This works because there are actually only 16 different values */
    /* [7] == [3] == [1] == [0] */
    /* [8] == [4] == [2] */
    /* [9] == [5] */
    /* [10] == [6] */

    ldr     q24, [x3], #4 * 4       // B[7, 8, 9, 10]
    ldr     q25, [x3], #4 * 4       // B[11, 12, 13, 14]
    ldr     q26, [x4], #4 * 4       // B'[7, 8, 9, 10]
    ldr     q27, [x4]               // B'[11, 12, 13, 14]

    /* Repeat this sequence 8 times. We need to perform the calculation for
     * every integer coefficient. We have intervals of 32 values and we can take
     * 4 values in one go. 32 / 4 = 8. */

    .rept 8

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

    butterfly v0.4s, v16.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v1.4s, v17.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v2.4s, v18.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v3.4s, v19.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v4.4s, v20.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v5.4s, v21.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v6.4s, v22.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v7.4s, v23.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s

    // LAYER 2

    butterfly v0.4s, v4.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v1.4s, v5.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v2.4s, v6.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v3.4s, v7.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v16.4s, v20.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s
    butterfly v17.4s, v21.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s
    butterfly v18.4s, v22.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s
    butterfly v19.4s, v23.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s

    // LAYER 3

    butterfly v0.4s, v2.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v1.4s, v3.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v4.4s, v6.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s
    butterfly v5.4s, v7.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s
    butterfly v16.4s, v18.4s, v24.4s[2], v26.4s[2], v30.4s, v31.4s
    butterfly v17.4s, v19.4s, v24.4s[2], v26.4s[2], v30.4s, v31.4s
    butterfly v20.4s, v22.4s, v24.4s[3], v26.4s[3], v30.4s, v31.4s
    butterfly v21.4s, v23.4s, v24.4s[3], v26.4s[3], v30.4s, v31.4s

    // LAYER 4

    butterfly v0.4s, v1.4s, v24.4s[0], v26.4s[0], v30.4s, v31.4s
    butterfly v2.4s, v3.4s, v24.4s[1], v26.4s[1], v30.4s, v31.4s
    butterfly v4.4s, v5.4s, v24.4s[2], v26.4s[2], v30.4s, v31.4s
    butterfly v6.4s, v7.4s, v24.4s[3], v26.4s[3], v30.4s, v31.4s
    butterfly v16.4s, v17.4s, v25.4s[0], v27.4s[0], v30.4s, v31.4s
    butterfly v18.4s, v19.4s, v25.4s[1], v27.4s[1], v30.4s, v31.4s
    butterfly v20.4s, v21.4s, v25.4s[2], v27.4s[2], v30.4s, v31.4s
    butterfly v22.4s, v23.4s, v25.4s[3], v27.4s[3], v30.4s, v31.4s

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

    add     start, start, #16       // Move to the next chunk

    .endr

    /* Layers 5+6+7 */
    /* NTT forward layer 5: length = 16, ridx = 15, loops = 16 */
    /* NTT forward layer 6: length = 8,  ridx = 31, loops = 32 */
    /* NTT forward layer 7: length = 4,  ridx = 63, loops = 64 */

    mov     start, x0               // Store *coefficients[0]

    /* Store layer specific values  */

    add     x3, x1, #4 * 15         // LAYER 5: ridx, used for indexing B
    add     x4, x2, #4 * 15         // LAYER 5: ridx, used for indexing B'

    add     x5, x1, #4 * 31         // LAYER 6: ridx, used for indexing B
    add     x6, x2, #4 * 31         // LAYER 6: ridx, used for indexing B'

    add     x7, x1, #4 * 63         // LAYER 7: ridx, used for indexing B
    add     x9, x2, #4 * 63         // LAYER 7: ridx, used for indexing B'

    /* Repeat this sequence 16 times. We need to perform the calculation for
     * every integer coefficient. We perform the calculation on 32 values in one
     * go. 512 / 32 = 16. */

    .rept 16

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 4]
    ldr     q2, [start, #4 * 8]
    ldr     q3, [start, #4 * 12]
    ldr     q4, [start, #4 * 16]
    ldr     q5, [start, #4 * 20]
    ldr     q6, [start, #4 * 24]
    ldr     q7, [start, #4 * 28]

    // LAYER 5

    ld1     {v28.s}[0], [x3], #4
    ld1     {v28.s}[1], [x4], #4
    butterfly v0.4s, v4.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s
    butterfly v1.4s, v5.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s
    butterfly v2.4s, v6.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s
    butterfly v3.4s, v7.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s

    // LAYER 6

    ld1     {v28.s}[0], [x5], #4
    ld1     {v28.s}[1], [x6], #4
    butterfly v0.4s, v2.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s
    butterfly v1.4s, v3.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s

    ld1     {v28.s}[0], [x5], #4
    ld1     {v28.s}[1], [x6], #4
    butterfly v4.4s, v6.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s
    butterfly v5.4s, v7.4s, v28.4s[0], v28.4s[1], v30.4s, v31.4s

    // LAYER 7

    ldr     q24, [x7], #16
    ldr     q25, [x9], #16
    butterfly v0.4s, v1.4s, v24.4s[0], v25.4s[0], v30.4s, v31.4s
    butterfly v2.4s, v3.4s, v24.4s[1], v25.4s[1], v30.4s, v31.4s
    butterfly v4.4s, v5.4s, v24.4s[2], v25.4s[2], v30.4s, v31.4s
    butterfly v6.4s, v7.4s, v24.4s[3], v25.4s[3], v30.4s, v31.4s

    str     q0, [start, #4 * 0]
    str     q1, [start, #4 * 4]
    str     q2, [start, #4 * 8]
    str     q3, [start, #4 * 12]
    str     q4, [start, #4 * 16]
    str     q5, [start, #4 * 20]
    str     q6, [start, #4 * 24]
    str     q7, [start, #4 * 28]

    add     start, start, #4 * 32   // Update pointer to next first coefficient

    .endr

    /* Layers 8+9 */
    /* NTT forward layer 8: length = 2, ridx = 127, loops = 128 */
    /* NTT forward layer 9: length = 1, ridx = 255, loops = 256 */

    start_l .req x12
    start_s .req x13

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x3, x1, #4 * 127        // LAYER 8: ridx, used for indexing B
    add     x4, x2, #4 * 127        // LAYER 8: ridx, used for indexing B'

    add     x5, x1, #4 * 255        // LAYER 9: ridx, used for indexing B
    add     x6, x2, #4 * 255        // LAYER 9: ridx, used for indexing B'

    .rept 64

    ld1     {v1.s}[0], [start_l], #4
    ld1     {v1.s}[1], [start_l], #4
    ld1     {v0.s}[0], [start_l], #4
    ld1     {v0.s}[1], [start_l], #4
    ld1     {v1.s}[2], [start_l], #4
    ld1     {v1.s}[3], [start_l], #4
    ld1     {v0.s}[2], [start_l], #4
    ld1     {v0.s}[3], [start_l], #4

    // LAYER 8

    ld1     {v24.s}[0], [x3]
    ld1     {v24.s}[1], [x3], #4
    ld1     {v24.s}[2], [x3]
    ld1     {v24.s}[3], [x3], #4

    ld1     {v25.s}[0], [x4]
    ld1     {v25.s}[1], [x4], #4
    ld1     {v25.s}[2], [x4]
    ld1     {v25.s}[3], [x4], #4

    sqdmulh v30.4s, v0.4s, v24.4s       // Mulhi[a, B]
    mul     v31.4s, v0.4s, v25.4s       // Mullo[a, B']
    sqdmulh v31.4s, v31.4s, v28.4s[2]   // Mulhi[M, Mullo[a, B']]
    sub     v30.4s, v30.4s, v31.4s      // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]

    sub     v0.4s, v1.4s, v30.4s
    add     v1.4s, v1.4s, v30.4s

    // q0 contains coefficients [2, 3, 6, 7]
    // q1 contains coefficients [0, 1, 4, 5]

    mov     v2.s[0], v1.s[1]
    mov     v2.s[1], v0.s[1]
    mov     v2.s[2], v1.s[3]
    mov     v2.s[3], v0.s[3]

    mov     v3.s[0], v1.s[0]
    mov     v3.s[1], v0.s[0]
    mov     v3.s[2], v1.s[2]
    mov     v3.s[3], v0.s[2]

    // q2 contains coefficients [1, 3, 5, 7]
    // q3 contains coefficients [0, 2, 4, 6]

    // LAYER 9

    ldr     q26, [x5], #16
    ldr     q27, [x6], #16

    sqdmulh v30.4s, v2.4s, v26.4s       // Mulhi[a, B]
    mul     v31.4s, v2.4s, v27.4s       // Mullo[a, B']
    sqdmulh v31.4s, v31.4s, v28.4s[2]   // Mulhi[M, Mullo[a, B']]
    sub     v30.4s, v30.4s, v31.4s      // Mulhi[a, B] − Mulhi[M, Mullo[a, B']]

    sub     v2.4s, v3.4s, v30.4s
    add     v3.4s, v3.4s, v30.4s

    st1     {v3.s}[0], [start_s], #4
    st1     {v2.s}[0], [start_s], #4
    st1     {v3.s}[1], [start_s], #4
    st1     {v2.s}[1], [start_s], #4
    st1     {v3.s}[2], [start_s], #4
    st1     {v2.s}[2], [start_s], #4
    st1     {v3.s}[3], [start_s], #4
    st1     {v2.s}[3], [start_s], #4

    .endr

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    ret     lr
