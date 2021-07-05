/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_forward
.type __asm_ntt_forward, %function

/* Provide macro definitions */

.macro sub_add lower, upper_in, upper_out
    sub \upper_out, \lower, \upper_in
    add \lower, \lower, \upper_in
.endm

.macro butterfly lower, upper, twid1, twid2, t1, t2
    /* _asimd_mul_red */
    sqdmulh \t1, \upper, \twid1
    mul     \t2, \upper, \twid2
    sqdmulh \t2, \t2, v28.4s[3]
    sub     \t1, \t1, \t2

    /* _asimd_sub_add */
    sub     \upper, \lower, \t1
    add     \lower, \lower, \t1
.endm

.macro doub_butterfly l0, l1, u0, u1, tw0, tw1, tw2, tw3, t0, t1, t2, t3
    sqdmulh \t0, \u0, \tw0
    mul     \t1, \u0, \tw1
    sqdmulh \t1, \t1, v28.4s[3]

    sub     \t0, \t0, \t1
    sqdmulh \t2, \u1, \tw2
    sub     \u0, \l0, \t0
    mul     \t3, \u1, \tw3
    add     \l0, \l0, \t0
    sqdmulh \t3, \t3, v28.4s[3]

    sub     \t2, \t2, \t3
    sub     \u1, \l1, \t2
    add     \l1, \l1, \t2
.endm

.macro trip_butterfly l0, l1, l2, u0, u1, u2, tw0, tw1, tw2, tw3, tw4, tw5, t0, t1, t2, t3, t4, t5
    sqdmulh \t0, \u0, \tw0
    mul     \t1, \u0, \tw1
    sqdmulh \t1, \t1, v28.4s[3]

    sub     \t0, \t0, \t1
    sqdmulh \t2, \u1, \tw2
    sub     \u0, \l0, \t0
    mul     \t3, \u1, \tw3
    add     \l0, \l0, \t0
    sqdmulh \t3, \t3, v28.4s[3]

    sub     \t2, \t2, \t3
    sqdmulh \t4, \u2, \tw4
    sub     \u1, \l1, \t2
    mul     \t5, \u2, \tw5
    add     \l1, \l1, \t2
    sqdmulh \t5, \t5, v28.4s[3]

    sub     \t4, \t4, \t5
    sub     \u2, \l2, \t4
    add     \l2, \l2, \t4
.endm

.macro quad_butterfly l0, l1, l2, l3, u0, u1, u2, u3, tw0, tw1, tw2, tw3, tw4, tw5, tw6, tw7, t0, t1, t2, t3, t4, t5, t6, t7
    sqdmulh \t0, \u0, \tw0
    mul     \t1, \u0, \tw1
    sqdmulh \t1, \t1, v28.4s[3]
    sub     \t0, \t0, \t1

    sqdmulh \t2, \u1, \tw2
    sub     \u0, \l0, \t0
    mul     \t3, \u1, \tw3
    add     \l0, \l0, \t0
    sqdmulh \t3, \t3, v28.4s[3]
    sub     \t2, \t2, \t3

    sqdmulh \t4, \u2, \tw4
    sub     \u1, \l1, \t2
    mul     \t5, \u2, \tw5
    add     \l1, \l1, \t2
    sqdmulh \t5, \t5, v28.4s[3]
    sub     \t4, \t4, \t5

    sqdmulh \t6, \u3, \tw6
    sub     \u2, \l2, \t4
    mul     \t7, \u3, \tw7
    add     \l2, \l2, \t4
    sqdmulh \t7, \t7, v28.4s[3]
    sub     \t6, \t6, \t7

    sub     \u3, \l3, \t6
    add     \l3, \l3, \t6
.endm

__asm_ntt_forward:

    sub sp, sp, #64
    st1 { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    st1 {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32

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
    mov     v28.4s[3], M            // Allocate M into a vector register

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

    // Since B[0, 1, 3, 7] are all equal to 1, we can skip the multiplication
    // (multiplying by 1 is useless) and only need to perform the sub, add
    // operations. This means that we can skip multiplying with root v24.4s[0].

    sub_add v0.4s, v16.4s, v8.4s
    sub_add v1.4s, v17.4s, v9.4s
    sub_add v2.4s, v18.4s, v10.4s
    sub_add v3.4s, v19.4s, v11.4s

    sub_add v4.4s, v20.4s, v12.4s
    sub_add v5.4s, v21.4s, v13.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    // LAYER 2

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    // So now the order is:
    // 0, 1, 2, 3
    // 16, 17, 18, 19
    // 8, 9, 10, 11
    // 12, 13, 14, 15

    quad_butterfly v8.4s, v9.4s, v10.4s, v11.4s, v12.4s, v13.4s, v14.4s, v15.4s, v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v4.4s, v5.4s, v6.4s, v7.4s, v20.4s, v21.4s, v22.4s, v23.4s

    // LAYER 3

    sub_add v0.4s, v2.4s, v4.4s
    sub_add v1.4s, v3.4s, v5.4s

    // So now the order is:
    // 0, 1, 4, 5
    // 16, 17, 18, 19
    // 8, 9, 10, 11
    // 12, 13, 14, 15

    doub_butterfly v16.4s, v17.4s, v18.4s, v19.4s, v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v2.4s, v3.4s, v6.4s, v7.4s
    quad_butterfly v8.4s, v9.4s, v12.4s, v13.4s, v10.4s, v11.4s, v14.4s, v15.4s, v24.4s[2], v26.4s[2], v24.4s[2], v26.4s[2], v24.4s[3], v26.4s[3], v24.4s[3], v26.4s[3], v20.4s, v21.4s, v22.4s, v23.4s, v2.4s, v3.4s, v6.4s, v7.4s

    // LAYER 4

    sub_add v0.4s, v1.4s, v20.4s

    // So now the order is:
    // 0, 20, 4, 5
    // 16, 17, 18, 19
    // 8, 9, 10, 11
    // 12, 13, 14, 15

    trip_butterfly v4.4s, v16.4s, v18.4s, v5.4s, v17.4s, v19.4s, v24.4s[1], v26.4s[1], v24.4s[2], v26.4s[2], v24.4s[3], v26.4s[3], v1.4s, v2.4s, v3.4s, v6.4s, v7.4s, v21.4s
    quad_butterfly v8.4s, v10.4s, v12.4s, v14.4s, v9.4s, v11.4s, v13.4s, v15.4s, v25.4s[0], v27.4s[0], v25.4s[1], v27.4s[1], v25.4s[2], v27.4s[2], v25.4s[3], v27.4s[3], v22.4s, v23.4s, v29.4s, v30.4s, v31.4s, v1.4s, v2.4s, v3.4s

    str     q0, [start, #4 * 0]
    str     q20, [start, #4 * 32]
    str     q4, [start, #4 * 64]
    str     q5, [start, #4 * 96]

    str     q16, [start, #4 * 128]
    str     q17, [start, #4 * 160]
    str     q18, [start, #4 * 192]
    str     q19, [start, #4 * 224]

    str     q8, [start, #4 * 256]
    str     q9, [start, #4 * 288]
    str     q10, [start, #4 * 320]
    str     q11, [start, #4 * 352]

    str     q12, [start, #4 * 384]
    str     q13, [start, #4 * 416]
    str     q14, [start, #4 * 448]
    str     q15, [start, #4 * 480]

    add     start, start, #16       // Move to the next chunk

    .endr

    /* Layers 5+6+7 */
    /* NTT forward layer 5: length = 16, ridx = 15, loops = 16 */
    /* NTT forward layer 6: length = 8,  ridx = 31, loops = 32 */
    /* NTT forward layer 7: length = 4,  ridx = 63, loops = 64 */

    mov     start, x0               // Store *coefficients[0]

    /* Store layer specific values  */

    add     x3, x1, #4 * 16         // LAYER 5: ridx, used for indexing B
    add     x4, x2, #4 * 16         // LAYER 5: ridx, used for indexing B'

    add     x5, x1, #4 * 32         // LAYER 6: ridx, used for indexing B
    add     x6, x2, #4 * 32         // LAYER 6: ridx, used for indexing B'

    add     x7, x1, #4 * 63         // LAYER 7: ridx, used for indexing B
    add     x9, x2, #4 * 63         // LAYER 7: ridx, used for indexing B'

    /* Repeat this sequence 16 times. We need to perform the calculation for
     * every integer coefficient. We perform the calculation on 32 values in one
     * go. 512 / 32 = 16. */

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 4]
    ldr     q2, [start, #4 * 8]
    ldr     q3, [start, #4 * 12]
    ldr     q4, [start, #4 * 16]
    ldr     q5, [start, #4 * 20]
    ldr     q6, [start, #4 * 24]
    ldr     q7, [start, #4 * 28]

    // LAYER 5

    // Since B[15, 31, 63] are all equal to 1, we can skip the multiplication
    // (multiplying by 1 is useless) and only need to perform the sub, add
    // operations.

    sub_add v0.4s, v4.4s, v8.4s
    sub_add v1.4s, v5.4s, v9.4s
    sub_add v2.4s, v6.4s, v10.4s
    sub_add v3.4s, v7.4s, v11.4s

    // So now the order is:
    // 0, 1, 2, 3
    // 8, 9, 10, 11

    // LAYER 6

    sub_add v0.4s, v2.4s, v12.4s
    sub_add v1.4s, v3.4s, v13.4s

    // So now the order is:
    // 0, 1, 12, 13
    // 8, 9, 10, 11

    ldr q26, [x5], #4
    ldr q27, [x6], #4

    doub_butterfly v8.4s, v9.4s, v10.4s, v11.4s, v26.4s[0], v27.4s[0], v26.4s[0], v27.4s[0], v16.4s, v17.4s, v18.4s, v19.4s

    // LAYER 7

    ldr     q30, [x7], #16
    ldr     q31, [x9], #16

    sub_add v0.4s, v1.4s, v14.4s

    // So now the order is:
    // 0, 14, 12, 13
    // 8, 9, 10, 11

    butterfly v12.4s, v13.4s, v30.4s[1], v31.4s[1], v16.4s, v17.4s
    butterfly v8.4s, v9.4s, v30.4s[2], v31.4s[2], v18.4s, v19.4s
    butterfly v10.4s, v11.4s, v30.4s[3], v31.4s[3], v20.4s, v21.4s

    str     q0, [start, #4 * 0]
    str     q14, [start, #4 * 4]
    str     q12, [start, #4 * 8]
    str     q13, [start, #4 * 12]
    str     q8, [start, #4 * 16]
    str     q9, [start, #4 * 20]
    str     q10, [start, #4 * 24]
    str     q11, [start, #4 * 28]

    add     start, start, #4 * 32   // Update pointer to next first coefficient

    .rept 15

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 4]
    ldr     q2, [start, #4 * 8]
    ldr     q3, [start, #4 * 12]
    ldr     q4, [start, #4 * 16]
    ldr     q5, [start, #4 * 20]
    ldr     q6, [start, #4 * 24]
    ldr     q7, [start, #4 * 28]

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    quad_butterfly v0.4s, v1.4s, v2.4s, v3.4s, v4.4s, v5.4s, v6.4s, v7.4s, v24.4s[0], v25.4s[0], v24.4s[0], v25.4s[0], v24.4s[0], v25.4s[0], v24.4s[0], v25.4s[0], v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8

    quad_butterfly v0.4s, v1.4s, v4.4s, v5.4s, v2.4s, v3.4s, v6.4s, v7.4s, v26.4s[0], v27.4s[0], v26.4s[0], v27.4s[0], v26.4s[1], v27.4s[1], v26.4s[1], v27.4s[1], v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s

    ldr     q30, [x7], #16
    ldr     q31, [x9], #16

    quad_butterfly v0.4s, v2.4s, v4.4s, v6.4s, v1.4s, v3.4s, v5.4s, v7.4s, v30.4s[0], v31.4s[0], v30.4s[1], v31.4s[1], v30.4s[2], v31.4s[2], v30.4s[3], v31.4s[3], v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s

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

    // We need to repeat this sequence 32 times. We iterate over 16 values in
    // one go and 512 / 16 = 32.

    .rept 32

    ld4 {v0.s, v1.s, v2.s, v3.s}[0], [start_l], #16
    ld4 {v0.s, v1.s, v2.s, v3.s}[1], [start_l], #16
    ld4 {v0.s, v1.s, v2.s, v3.s}[2], [start_l], #16
    ld4 {v0.s, v1.s, v2.s, v3.s}[3], [start_l], #16

    // Register placement:
    // V0: [0, 4, 8, 12]
    // V1: [1, 5, 9, 13]
    // V2: [2, 6, 10, 14]
    // V3: [3, 7, 11, 15]

    // LAYER 8
    // length = 2, we need 4 roots. We are going to execute:
    // [0, 1, 4, 5]   * [2, 3, 6, 7]     = V0 * V2
    // [8, 9, 12, 13] * [10, 11, 14, 15] = V1 * V3

    ldr q23, [x3], #16
    ldr q24, [x4], #16

    // Register placement:
    // V23 : B[127, 128, 129, 130]
    // V24 : B'[127, 128, 129, 130]

    sqdmulh v16.4s, v2.4s, v23.4s
    mul     v17.4s, v2.4s, v24.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]

    sub     v16.4s, v16.4s, v17.4s
    sqdmulh v18.4s, v3.4s, v23.4s
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v24.4s
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]

    sub     v18.4s, v18.4s, v19.4s
    sub     v3.4s, v1.4s, v18.4s
    add     v1.4s, v1.4s, v18.4s

    //doub_butterfly v0.4s, v1.4s, v2.4s, v3.4s, v23.4s, v24.4s, v23.4s, v24.4s, v16.4s, v17.4s, v18.4s, v19.4s

    // LAYER 9
    // length = 1, we need 8 roots. We are going to execute:
    // [0, 2, 4, 6]    * [1, 3, 5, 7]    = V0 * V1
    // [8, 10, 12, 14] * [9, 11, 13, 15] = V2 * V3

    ld2 {v23.s, v24.s}[0], [x5], #8
    ld2 {v23.s, v24.s}[1], [x5], #8
    ld2 {v23.s, v24.s}[2], [x5], #8
    ld2 {v23.s, v24.s}[3], [x5], #8

    ld2 {v25.s, v26.s}[0], [x6], #8
    ld2 {v25.s, v26.s}[1], [x6], #8
    ld2 {v25.s, v26.s}[2], [x6], #8
    ld2 {v25.s, v26.s}[3], [x6], #8

    // Register placement:
    // V23 : B[255, 257, 259, 261]
    // V24 : B[256, 258, 260, 262]
    // V25 : B'[255, 257, 259, 261]
    // V26 : B'[256, 258, 260, 262]

    sqdmulh v16.4s, v1.4s, v23.4s
    mul     v17.4s, v1.4s, v25.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s
    sub     v1.4s, v0.4s, v16.4s
    add     v0.4s, v0.4s, v16.4s

    sqdmulh v18.4s, v3.4s, v24.4s
    mul     v19.4s, v3.4s, v26.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s
    sub     v3.4s, v2.4s, v18.4s
    add     v2.4s, v2.4s, v18.4s

    st4 {v0.s, v1.s, v2.s, v3.s}[0], [start_s], #16
    st4 {v0.s, v1.s, v2.s, v3.s}[1], [start_s], #16
    st4 {v0.s, v1.s, v2.s, v3.s}[2], [start_s], #16
    st4 {v0.s, v1.s, v2.s, v3.s}[3], [start_s], #16

    .endr

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    sub sp, sp, #64
    ld1 { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    ld1 {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32

    ret     lr
