/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_ntt_inverse
.type __asm_ntt_inverse, %function

/* Provide macro definitions */

.macro sub_add lower, upper_in, upper_out
    sub \upper_out, \lower, \upper_in
    add \lower, \lower, \upper_in
.endm

.macro butterfly lower, upper, twid1, twid2, t1, t2
    /* _asimd_sub_add */
    sub     \t1, \lower, \upper
    add     \lower, \lower, \upper

    /* _asimd_mul_red */
    sqdmulh \t2, \t1, \twid1
    mul     \t1, \t1, \twid2
    sqdmulh \t1, \t1, v28.4s[3]
    sub     \upper, \t2, \t1
.endm

.macro doub_butterfly l0, l1, u0, u1, tw0, tw1, tw2, tw3, t0, t1, t2, t3
    sub     \t0, \l0, \u0
    add     \l0, \l0, \u0

    sqdmulh \t1, \t0, \tw0
    sub     \t2, \l1, \u1
    mul     \t0, \t0, \tw1
    add     \l1, \l1, \u1
    sqdmulh \t0, \t0, v28.4s[3]
    sub     \u0, \t1, \t0

    sqdmulh \t3, \t2, \tw2
    mul     \t2, \t2, \tw3
    sqdmulh \t2, \t2, v28.4s[3]
    sub     \u1, \t3, \t2
.endm

.macro trip_butterfly l0, l1, l2, u0, u1, u2, tw0, tw1, tw2, tw3, tw4, tw5, t0, t1, t2, t3, t4, t5
    sub     \t0, \l0, \u0
    add     \l0, \l0, \u0

    sqdmulh \t1, \t0, \tw0
    sub     \t2, \l1, \u1
    mul     \t0, \t0, \tw1
    add     \l1, \l1, \u1
    sqdmulh \t0, \t0, v28.4s[3]
    sub     \u0, \t1, \t0

    sqdmulh \t3, \t2, \tw2
    sub     \t4, \l2, \u2
    mul     \t2, \t2, \tw3
    add     \l2, \l2, \u2
    sqdmulh \t2, \t2, v28.4s[3]
    sub     \u1, \t3, \t2

    sqdmulh \t5, \t4, \tw4
    mul     \t4, \t4, \tw5
    sqdmulh \t4, \t4, v28.4s[3]
    sub     \u2, \t5, \t4
.endm

.macro quad_butterfly l0, l1, l2, l3, u0, u1, u2, u3, tw0, tw1, tw2, tw3, tw4, tw5, tw6, tw7, t0, t1, t2, t3, t4, t5, t6, t7
    sub     \t0, \l0, \u0
    add     \l0, \l0, \u0

    sqdmulh \t1, \t0, \tw0
    sub     \t2, \l1, \u1
    mul     \t0, \t0, \tw1
    add     \l1, \l1, \u1
    sqdmulh \t0, \t0, v28.4s[3]
    sub     \u0, \t1, \t0

    sqdmulh \t3, \t2, \tw2
    sub     \t4, \l2, \u2
    mul     \t2, \t2, \tw3
    add     \l2, \l2, \u2
    sqdmulh \t2, \t2, v28.4s[3]
    sub     \u1, \t3, \t2

    sqdmulh \t5, \t4, \tw4
    sub     \t6, \l3, \u3
    mul     \t4, \t4, \tw5
    add     \l3, \l3, \u3
    sqdmulh \t4, \t4, v28.4s[3]
    sub     \u2, \t5, \t4

    sqdmulh \t7, \t6, \tw6
    mul     \t6, \t6, \tw7
    sqdmulh \t6, \t6, v28.4s[3]
    sub     \u3, \t7, \t6
.endm

__asm_ntt_inverse:

    sub sp, sp, #64
    st1 { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    st1 {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32

    /* Alias registers for a specific purpose (and readability) */

    start   .req x14    // Store pointer to the first integer coefficient
    M       .req w15    // Store the constant value M = 6984193

    /* Initialize constant values */

    mov     M, #0x9201              // 6984193 (= M)
    movk    M, #0x6a, lsl #16
    mov     v28.4s[3], M

    /* Layers 9+8 */
    /* NTT inverse layer 9: length = 1, ridx = 0 */
    /* NTT inverse layer 8: length = 2, ridx = 256 */

    start_l .req x10
    start_s .req x11

    mov     start_l, x0
    mov     start_s, x0

    /* Store layer specific values  */

    add     x3, x1, #4 * 0          // LAYER 9: ridx, used for indexing B
    add     x4, x2, #4 * 0          // LAYER 9: ridx, used for indexing B'

    add     x5, x1, #4 * 256        // LAYER 8: ridx, used for indexing B
    add     x6, x2, #4 * 256        // LAYER 8: ridx, used for indexing B'

    // We need to repeat this sequence 32 times. We iterate over 16 values in
    // one go and 512 / 16 = 32.

    .rept 32

    ld4 {v0.s, v1.s, v2.s, v3.s}[0], [start_l], #16
    ld4 {v0.s, v1.s, v2.s, v3.s}[1], [start_l], #16
    ld4 {v0.s, v1.s, v2.s, v3.s}[2], [start_l], #16
    ld4 {v0.s, v1.s, v2.s, v3.s}[3], [start_l], #16

    // LAYER 9
    // length = 1, we need 8 roots. We are going to execute:
    // [0, 2, 4, 6]    * [1, 3, 5, 7]    = V0 * V1
    // [8, 10, 12, 14] * [9, 11, 13, 15] = V2 * V3

    ld2 {v23.s, v24.s}[0], [x3], #8
    ld2 {v23.s, v24.s}[1], [x3], #8
    ld2 {v23.s, v24.s}[2], [x3], #8
    ld2 {v23.s, v24.s}[3], [x3], #8

    ld2 {v25.s, v26.s}[0], [x4], #8
    ld2 {v25.s, v26.s}[1], [x4], #8
    ld2 {v25.s, v26.s}[2], [x4], #8
    ld2 {v25.s, v26.s}[3], [x4], #8

    doub_butterfly v0.4s, v2.4s, v1.4s, v3.4s, v23.4s, v25.4s, v24.4s, v26.4s, v4.4s, v5.4s, v6.4s, v7.4s

    // LAYER 8
    // length = 2, we need 4 roots. We are going to execute:
    // [0, 1, 4, 5]   * [2, 3, 6, 7]     = V0 * V2
    // [8, 9, 12, 13] * [10, 11, 14, 15] = V1 * V3

    ldr q30, [x5], #16
    ldr q31, [x6], #16

    butterfly v0.4s, v2.4s, v30.4s, v31.4s, v8.4s, v10.4s
    butterfly v1.4s, v3.4s, v30.4s, v31.4s, v9.4s, v11.4s

    st4 {v0.s, v1.s, v2.s, v3.s}[0], [start_s], #16
    st4 {v0.s, v1.s, v2.s, v3.s}[1], [start_s], #16
    st4 {v0.s, v1.s, v2.s, v3.s}[2], [start_s], #16
    st4 {v0.s, v1.s, v2.s, v3.s}[3], [start_s], #16

    .endr

    /* Layers 7+6+5 */
    /* NTT inverse layer 7: length = 4, ridx = 384, loops = 64 */
    /* NTT inverse layer 6: length = 8, ridx = 448, loops = 32 */
    /* NTT inverse layer 5: length = 16, ridx = 480, loops = 16 */

    mov     start, x0               // Store *coefficients[0]

    /* Store layer specific values  */

    add     x3, x1, #4 * 384        // LAYER 7: ridx, used for indexing B
    add     x4, x2, #4 * 384        // LAYER 7: ridx, used for indexing B'

    add     x5, x1, #4 * 449        // LAYER 6: ridx, used for indexing B
    add     x6, x2, #4 * 449        // LAYER 6: ridx, used for indexing B'

    add     x7, x1, #4 * 481        // LAYER 5: ridx, used for indexing B
    add     x9, x2, #4 * 481        // LAYER 5: ridx, used for indexing B'

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 4]
    ldr     q2, [start, #4 * 8]
    ldr     q3, [start, #4 * 12]
    ldr     q4, [start, #4 * 16]
    ldr     q5, [start, #4 * 20]
    ldr     q6, [start, #4 * 24]
    ldr     q7, [start, #4 * 28]

    // LAYER 7

    // Since B[384, 448, 480] are all equal to 1, we can skip the multiplication
    // (multiplying by 1 is useless) and only need to perform the sub, add
    // operations.

    sub_add v0.4s, v1.4s, v8.4s

    // So now the order is:
    // 0, 8, 2, 3
    // 4, 5, 6, 7

    ldr     q27, [x3], #16
    ldr     q29, [x4], #16

    trip_butterfly v2.4s, v4.4s, v6.4s, v3.4s, v5.4s, v7.4s, v27.4s[1], v29.4s[1], v27.4s[2], v29.4s[2], v27.4s[3], v29.4s[3], v15.4s, v16.4s, v17.4s, v18.4s, v19.4s, v20.4s

    // LAYER 6

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    // So now the order is:
    // 0, 8, 9, 10
    // 4, 5, 6, 7

    ldr q30, [x5], #4
    ldr q31, [x6], #4

    doub_butterfly v4.4s, v5.4s, v6.4s, v7.4s, v30.4s[0], v31.4s[0], v30.4s[0], v31.4s[0], v21.4s, v22.4s, v23.4s, v24.4s

    // LAYER 5

    sub_add v0.4s, v4.4s, v11.4s
    sub_add v8.4s, v5.4s, v12.4s
    sub_add v9.4s, v6.4s, v13.4s
    sub_add v10.4s, v7.4s, v14.4s

    // So now the order is:
    // 0, 8, 9, 10
    // 11, 12, 13, 14

    str     q0, [start, #4 * 0]
    str     q8, [start, #4 * 4]
    str     q9, [start, #4 * 8]
    str     q10, [start, #4 * 12]
    str     q11, [start, #4 * 16]
    str     q12, [start, #4 * 20]
    str     q13, [start, #4 * 24]
    str     q14, [start, #4 * 28]

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

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16

    quad_butterfly v0.4s, v2.4s, v4.4s, v6.4s, v1.4s, v3.4s, v5.4s, v7.4s, v24.4s[0], v25.4s[0], v24.4s[1], v25.4s[1], v24.4s[2], v25.4s[2], v24.4s[3], v25.4s[3], v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s

    ldr q26, [x5], #8
    ldr q27, [x6], #8

    quad_butterfly v0.4s, v1.4s, v4.4s, v5.4s, v2.4s, v3.4s, v6.4s, v7.4s, v26.4s[0], v27.4s[0], v26.4s[0], v27.4s[0], v26.4s[1], v27.4s[1], v26.4s[1], v27.4s[1], v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s

    ldr q30, [x7], #4
    ldr q31, [x9], #4

    quad_butterfly v0.4s, v1.4s, v2.4s, v3.4s, v4.4s, v5.4s, v6.4s, v7.4s, v30.4s[0], v31.4s[0], v30.4s[0], v31.4s[0], v30.4s[0], v31.4s[0], v30.4s[0], v31.4s[0], v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s

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

    /* Layers 4+3+2+1 */
    /* NTT inverse layer 4: length = 32, ridx = 496, loops = 8 */
    /* NTT inverse layer 3: length = 64, ridx = 504, loops = 4 */
    /* NTT inverse layer 2: length = 128, ridx = 508, loops = 2 */
    /* NTT inverse layer 1: length = 256, ridx = 510, loops = 1 */

    mov     start, x0               // Store *coefficients[0]

    /* Store layer specific values  */

    add     x3, x1, #4 * 496        // Store *B[496]
    add     x4, x2, #4 * 496        // Store *B'[496]

    /* Preload the required root values, we have enough room */
    /* This works because there are actually only 16 different values */
    /* [496] == [504] == [508] == [510] */
    /* [497] == [505] == [509] */
    /* [498] == [506] */
    /* [499] == [507] */

    ldr     q24, [x3], #4 * 4       // B[496, 497, 498, 499]
    ldr     q25, [x3], #4 * 4       // B[500, 501, 502, 503]
    ldr     q26, [x4], #4 * 4       // B'[496, 497, 498, 499]
    ldr     q27, [x4]               // B'[500, 501, 502, 503]

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

    // LAYER 4

    // Since B[496, 504, 508, 510] are all equal to 1, we can skip the
    // multiplication (multiplying by 1 is useless) and only need to perform the
    // sub, add operations. This means that we can skip multiplying with root
    // v24.4s[0].

    sub_add v0.4s, v1.4s, v8.4s

    // So now the order is:
    // 0, 8, 2, 3
    // 4, 5, 6, 7
    // 16, 17, 18, 19
    // 20, 21, 22, 23

    trip_butterfly v2.4s, v4.4s, v6.4s, v3.4s, v5.4s, v7.4s, v24.4s[1], v26.4s[1], v24.4s[2], v26.4s[2], v24.4s[3], v26.4s[3], v9.4s, v10.4s, v11.4s, v12.4s, v13.4s, v14.4s
    quad_butterfly v16.4s, v18.4s, v20.4s, v22.4s, v17.4s, v19.4s, v21.4s, v23.4s, v25.4s[0], v27.4s[0], v25.4s[1], v27.4s[1], v25.4s[2], v27.4s[2], v25.4s[3], v27.4s[3], v15.4s, v29.4s, v30.4s, v31.4s, v11.4s, v12.4s, v13.4s, v14.4s

    // LAYER 3

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    // So now the order is:
    // 0, 8, 9, 10
    // 4, 5, 6, 7
    // 16, 17, 18, 19
    // 20, 21, 22, 23

    doub_butterfly v4.4s, v5.4s, v6.4s, v7.4s, v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v1.4s, v2.4s, v3.4s, v11.4s
    quad_butterfly v16.4s, v17.4s, v20.4s, v21.4s, v18.4s, v19.4s, v22.4s, v23.4s, v24.4s[2], v26.4s[2], v24.4s[2], v26.4s[2], v24.4s[3], v26.4s[3], v24.4s[3], v26.4s[3], v12.4s, v13.4s, v14.4s, v15.4s, v29.4s, v30.4s, v31.4s, v1.4s

    // LAYER 2

    sub_add v0.4s, v4.4s, v11.4s
    sub_add v8.4s, v5.4s, v12.4s
    sub_add v9.4s, v6.4s, v13.4s
    sub_add v10.4s, v7.4s, v14.4s

    // So now the order is:
    // 0, 8, 9, 10
    // 11, 12, 13, 14
    // 16, 17, 18, 19
    // 20, 21, 22, 23

    quad_butterfly v16.4s, v17.4s, v18.4s, v19.4s, v20.4s, v21.4s, v22.4s, v23.4s, v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v24.4s[1], v26.4s[1], v2.4s, v3.4s, v4.4s, v5.4s, v6.4s, v7.4s, v15.4s, v29.4s

    // LAYER 1

    sub_add v0.4s, v16.4s, v2.4s
    sub_add v8.4s, v17.4s, v3.4s
    sub_add v9.4s, v18.4s, v4.4s
    sub_add v10.4s, v19.4s, v5.4s

    sub_add v11.4s, v20.4s, v6.4s
    sub_add v12.4s, v21.4s, v7.4s
    sub_add v13.4s, v22.4s, v15.4s
    sub_add v14.4s, v23.4s, v29.4s

    // So now the order is:
    // 0, 8, 9, 10
    // 11, 12, 13, 14
    // 2, 3, 4, 5
    // 6, 7, 15, 29

    str     q0, [start, #4 * 0]
    str     q8, [start, #4 * 32]
    str     q9, [start, #4 * 64]
    str     q10, [start, #4 * 96]

    str     q11, [start, #4 * 128]
    str     q12, [start, #4 * 160]
    str     q13, [start, #4 * 192]
    str     q14, [start, #4 * 224]

    str     q2, [start, #4 * 256]
    str     q3, [start, #4 * 288]
    str     q4, [start, #4 * 320]
    str     q5, [start, #4 * 352]

    str     q6, [start, #4 * 384]
    str     q7, [start, #4 * 416]
    str     q15, [start, #4 * 448]
    str     q29, [start, #4 * 480]

    add     start, start, #16       // Move to the next chunk

    .endr

    sub sp, sp, #64
    ld1 { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    ld1 {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32

    ret     lr
