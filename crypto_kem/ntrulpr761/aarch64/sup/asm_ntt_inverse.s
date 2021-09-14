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

__asm_ntt_inverse:

    sub     sp, sp, #64
    st1     { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    st1     {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32

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

    // We need to repeat this sequence 16 times. We iterate over 32 values in
    // one go and 512 / 32 = 16.

    .rept 16

    ld4     {v0.s, v1.s, v2.s, v3.s}[0], [start_l], #16
    ld4     {v0.s, v1.s, v2.s, v3.s}[1], [start_l], #16
    ld4     {v0.s, v1.s, v2.s, v3.s}[2], [start_l], #16
    ld4     {v0.s, v1.s, v2.s, v3.s}[3], [start_l], #16

    ld2     {v24.s, v25.s}[0], [x3], #8
    ld2     {v24.s, v25.s}[1], [x3], #8
    ld2     {v24.s, v25.s}[2], [x3], #8
    ld2     {v24.s, v25.s}[3], [x3], #8

    ld2     {v26.s, v27.s}[0], [x4], #8
    ld2     {v26.s, v27.s}[1], [x4], #8
    ld2     {v26.s, v27.s}[2], [x4], #8
    ld2     {v26.s, v27.s}[3], [x4], #8

    ldr     q30, [x5], #16
    ldr     q31, [x6], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    sqdmulh v17.4s, v16.4s, v24.4s
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v26.4s
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v25.4s
    ld4     {v8.s, v9.s, v10.s, v11.s}[0], [start_l], #16
    mul     v18.4s, v18.4s, v27.4s
    ld4     {v8.s, v9.s, v10.s, v11.s}[1], [start_l], #16
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    ld4     {v8.s, v9.s, v10.s, v11.s}[2], [start_l], #16
    sub     v3.4s, v19.4s, v18.4s
    ld4     {v8.s, v9.s, v10.s, v11.s}[3], [start_l], #16

    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v18.4s, v16.4s, v30.4s
    sub     v17.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v31.4s
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v18.4s, v16.4s

    sqdmulh v19.4s, v17.4s, v30.4s
    ld2     {v12.s, v13.s}[0], [x3], #8
    mul     v17.4s, v17.4s, v31.4s
    ld2     {v12.s, v13.s}[1], [x3], #8
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ld2     {v12.s, v13.s}[2], [x3], #8
    sub     v3.4s, v19.4s, v17.4s
    ld2     {v12.s, v13.s}[3], [x3], #8

    ld2     {v14.s, v15.s}[0], [x4], #8
    ld2     {v14.s, v15.s}[1], [x4], #8
    ld2     {v14.s, v15.s}[2], [x4], #8
    ld2     {v14.s, v15.s}[3], [x4], #8

    sub     v20.4s, v8.4s, v9.4s
    add     v8.4s, v8.4s, v9.4s

    sqdmulh v21.4s, v20.4s, v12.4s
    sub     v22.4s, v10.4s, v11.4s
    mul     v20.4s, v20.4s, v14.4s
    add     v10.4s, v10.4s, v11.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v9.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v13.4s
    sub     v20.4s, v8.4s, v10.4s
    mul     v22.4s, v22.4s, v15.4s
    add     v8.4s, v8.4s, v10.4s
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v11.4s, v23.4s, v22.4s

    ldr     q4, [x5], #16
    ldr     q5, [x6], #16

    sqdmulh v22.4s, v20.4s, v4.4s
    mul     v20.4s, v20.4s, v5.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v10.4s, v22.4s, v20.4s

    sub     v21.4s, v9.4s, v11.4s
    add     v9.4s, v9.4s, v11.4s
    sqdmulh v23.4s, v21.4s, v4.4s
    mul     v21.4s, v21.4s, v5.4s

    st4     {v0.s, v1.s, v2.s, v3.s}[0], [start_s], #16
    st4     {v0.s, v1.s, v2.s, v3.s}[1], [start_s], #16
    st4     {v0.s, v1.s, v2.s, v3.s}[2], [start_s], #16
    st4     {v0.s, v1.s, v2.s, v3.s}[3], [start_s], #16

    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v11.4s, v23.4s, v21.4s

    st4     {v8.s, v9.s, v10.s, v11.s}[0], [start_s], #16
    st4     {v8.s, v9.s, v10.s, v11.s}[1], [start_s], #16
    st4     {v8.s, v9.s, v10.s, v11.s}[2], [start_s], #16
    st4     {v8.s, v9.s, v10.s, v11.s}[3], [start_s], #16

    .endr

    /* Layers 7+6+5 */
    /* NTT inverse layer 7: length = 4, ridx = 384, loops = 64 */
    /* NTT inverse layer 6: length = 8, ridx = 448, loops = 32 */
    /* NTT inverse layer 5: length = 16, ridx = 480, loops = 16 */

    mov     start, x0               // Store *coefficients[0]

    /* Store layer specific values  */

    add     x3, x1, #4 * 384        // LAYER 7: ridx, used for indexing B
    ldr     q0, [start, #4 * 0]
    add     x4, x2, #4 * 384        // LAYER 7: ridx, used for indexing B'
    ldr     q1, [start, #4 * 4]
    add     x5, x1, #4 * 449        // LAYER 6: ridx, used for indexing B
    ldr     q2, [start, #4 * 8]
    add     x6, x2, #4 * 449        // LAYER 6: ridx, used for indexing B'
    ldr     q3, [start, #4 * 12]
    add     x7, x1, #4 * 481        // LAYER 5: ridx, used for indexing B
    sub_add v0.4s, v1.4s, v8.4s
    add     x9, x2, #4 * 481        // LAYER 5: ridx, used for indexing B'

    // So now the order is:
    // 0, 8, 2, 3
    // 4, 5, 6, 7

    ldr     q27, [x3], #16
    ldr     q29, [x4], #16

    ldr     q4, [start, #4 * 16]
    sub     v15.4s, v2.4s, v3.4s
    ldr     q5, [start, #4 * 20]
    add     v2.4s, v2.4s, v3.4s

    ldr     q6, [start, #4 * 24]
    ldr     q7, [start, #4 * 28]

    sqdmulh v16.4s, v15.4s, v27.4s[1]
    sub     v17.4s, v4.4s, v5.4s
    mul     v15.4s, v15.4s, v29.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v3.4s, v16.4s, v15.4s

    sqdmulh v18.4s, v17.4s, v27.4s[2]
    sub     v19.4s, v6.4s, v7.4s
    mul     v17.4s, v17.4s, v29.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v5.4s, v18.4s, v17.4s

    sqdmulh v20.4s, v19.4s, v27.4s[3]
    mul     v19.4s, v19.4s, v29.4s[3]
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v7.4s, v20.4s, v19.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    // So now the order is:
    // 0, 8, 9, 10
    // 4, 5, 6, 7

    ldr     q30, [x5], #4
    ldr     q31, [x6], #4

    sub     v21.4s, v4.4s, v6.4s
    add     v4.4s, v4.4s, v6.4s

    sqdmulh v22.4s, v21.4s, v30.4s[0]
    sub     v23.4s, v5.4s, v7.4s
    mul     v21.4s, v21.4s, v31.4s[0]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v6.4s, v22.4s, v21.4s

    sqdmulh v24.4s, v23.4s, v30.4s[0]
    mul     v23.4s, v23.4s, v31.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v7.4s, v24.4s, v23.4s

    sub_add v0.4s, v4.4s, v11.4s
    str     q0, [start, #4 * 0]
    str     q11, [start, #4 * 16]

    sub_add v8.4s, v5.4s, v12.4s
    str     q8, [start, #4 * 4]
    str     q12, [start, #4 * 20]

    sub_add v9.4s, v6.4s, v13.4s
    str     q9, [start, #4 * 8]
    str     q13, [start, #4 * 24]

    sub_add v10.4s, v7.4s, v14.4s
    str     q10, [start, #4 * 12]
    str     q14, [start, #4 * 28]

    // So now the order is:
    // 0, 8, 9, 10
    // 11, 12, 13, 14

    ldr     q0, [start, #4 * 32]
    ldr     q1, [start, #4 * 36]
    ldr     q2, [start, #4 * 40]
    ldr     q3, [start, #4 * 44]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16

    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 48]
    ldr     q5, [start, #4 * 52]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    ldr     q6, [start, #4 * 56]
    ldr     q7, [start, #4 * 60]

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 32]
    ldr     q0, [start, #4 * 64]
    str     q1, [start, #4 * 36]
    ldr     q1, [start, #4 * 68]
    str     q2, [start, #4 * 40]
    ldr     q2, [start, #4 * 72]
    str     q3, [start, #4 * 44]
    ldr     q3, [start, #4 * 76]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    str     q4, [start, #4 * 48]
    ldr     q4, [start, #4 * 80]
    str     q5, [start, #4 * 52]
    ldr     q5, [start, #4 * 84]
    str     q6, [start, #4 * 56]
    ldr     q6, [start, #4 * 88]
    str     q7, [start, #4 * 60]
    ldr     q7, [start, #4 * 92]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 64]
    ldr     q0, [start, #4 * 96]
    str     q1, [start, #4 * 68]
    ldr     q1, [start, #4 * 100]
    str     q2, [start, #4 * 72]
    ldr     q2, [start, #4 * 104]
    str     q3, [start, #4 * 76]
    ldr     q3, [start, #4 * 108]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    str     q4, [start, #4 * 80]
    ldr     q4, [start, #4 * 112]
    str     q5, [start, #4 * 84]
    ldr     q5, [start, #4 * 116]
    str     q6, [start, #4 * 88]
    ldr     q6, [start, #4 * 120]
    str     q7, [start, #4 * 92]
    ldr     q7, [start, #4 * 124]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 96]
    ldr     q0, [start, #4 * 128]
    str     q1, [start, #4 * 100]
    ldr     q1, [start, #4 * 132]
    str     q2, [start, #4 * 104]
    ldr     q2, [start, #4 * 136]
    str     q3, [start, #4 * 108]
    ldr     q3, [start, #4 * 140]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    str     q4, [start, #4 * 112]
    ldr     q4, [start, #4 * 144]
    str     q5, [start, #4 * 116]
    ldr     q5, [start, #4 * 148]
    str     q6, [start, #4 * 120]
    ldr     q6, [start, #4 * 152]
    str     q7, [start, #4 * 124]
    ldr     q7, [start, #4 * 156]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 128]
    str     q1, [start, #4 * 132]
    str     q2, [start, #4 * 136]
    str     q3, [start, #4 * 140]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 144]
    ldr     q0, [start, #4 * 160]
    str     q5, [start, #4 * 148]
    ldr     q1, [start, #4 * 164]
    str     q6, [start, #4 * 152]
    ldr     q2, [start, #4 * 168]
    str     q7, [start, #4 * 156]
    ldr     q3, [start, #4 * 172]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 176]
    ldr     q5, [start, #4 * 180]
    ldr     q6, [start, #4 * 184]
    ldr     q7, [start, #4 * 188]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 160]
    str     q1, [start, #4 * 164]
    str     q2, [start, #4 * 168]
    str     q3, [start, #4 * 172]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 176]
    ldr     q0, [start, #4 * 192]
    str     q5, [start, #4 * 180]
    ldr     q1, [start, #4 * 196]
    ldr     q2, [start, #4 * 200]
    str     q6, [start, #4 * 184]
    ldr     q3, [start, #4 * 204]
    str     q7, [start, #4 * 188]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 208]
    ldr     q5, [start, #4 * 212]
    ldr     q6, [start, #4 * 216]
    ldr     q7, [start, #4 * 220]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 192]
    str     q1, [start, #4 * 196]
    str     q2, [start, #4 * 200]
    str     q3, [start, #4 * 204]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 208]
    ldr     q0, [start, #4 * 224]
    str     q5, [start, #4 * 212]
    ldr     q1, [start, #4 * 228]
    str     q6, [start, #4 * 216]
    ldr     q2, [start, #4 * 232]
    str     q7, [start, #4 * 220]
    ldr     q3, [start, #4 * 236]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 240]
    ldr     q5, [start, #4 * 244]
    ldr     q6, [start, #4 * 248]
    ldr     q7, [start, #4 * 252]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 224]
    str     q1, [start, #4 * 228]
    str     q2, [start, #4 * 232]
    str     q3, [start, #4 * 236]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 240]
    ldr     q0, [start, #4 * 256]
    str     q5, [start, #4 * 244]
    ldr     q1, [start, #4 * 260]
    str     q6, [start, #4 * 248]
    ldr     q2, [start, #4 * 264]
    str     q7, [start, #4 * 252]
    ldr     q3, [start, #4 * 268]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 272]
    ldr     q5, [start, #4 * 276]
    ldr     q6, [start, #4 * 280]
    ldr     q7, [start, #4 * 284]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 256]
    str     q1, [start, #4 * 260]
    str     q2, [start, #4 * 264]
    str     q3, [start, #4 * 268]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 272]
    ldr     q0, [start, #4 * 288]
    str     q5, [start, #4 * 276]
    ldr     q1, [start, #4 * 292]
    str     q6, [start, #4 * 280]
    ldr     q2, [start, #4 * 296]
    str     q7, [start, #4 * 284]
    ldr     q3, [start, #4 * 300]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 304]
    ldr     q5, [start, #4 * 308]
    ldr     q6, [start, #4 * 312]
    ldr     q7, [start, #4 * 316]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 288]
    sqdmulh v23.4s, v22.4s, v30.4s[0]
    str     q1, [start, #4 * 292]
    mul     v22.4s, v22.4s, v31.4s[0]
    str     q2, [start, #4 * 296]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    str     q3, [start, #4 * 300]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 304]
    ldr     q0, [start, #4 * 320]
    str     q5, [start, #4 * 308]
    ldr     q1, [start, #4 * 324]
    str     q6, [start, #4 * 312]
    ldr     q2, [start, #4 * 328]
    str     q7, [start, #4 * 316]
    ldr     q3, [start, #4 * 332]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 336]
    ldr     q5, [start, #4 * 340]
    ldr     q6, [start, #4 * 344]
    ldr     q7, [start, #4 * 348]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 320]
    sqdmulh v23.4s, v22.4s, v30.4s[0]
    str     q1, [start, #4 * 324]
    mul     v22.4s, v22.4s, v31.4s[0]
    str     q2, [start, #4 * 328]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    str     q3, [start, #4 * 332]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 336]
    ldr     q0, [start, #4 * 352]
    str     q5, [start, #4 * 340]
    ldr     q1, [start, #4 * 356]
    str     q6, [start, #4 * 344]
    ldr     q2, [start, #4 * 360]
    str     q7, [start, #4 * 348]
    ldr     q3, [start, #4 * 364]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 368]
    ldr     q5, [start, #4 * 372]
    ldr     q6, [start, #4 * 376]
    ldr     q7, [start, #4 * 380]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 352]
    sqdmulh v23.4s, v22.4s, v30.4s[0]
    str     q1, [start, #4 * 356]
    mul     v22.4s, v22.4s, v31.4s[0]
    str     q2, [start, #4 * 360]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    str     q3, [start, #4 * 364]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 368]
    ldr     q0, [start, #4 * 384]
    str     q5, [start, #4 * 372]
    ldr     q1, [start, #4 * 388]
    str     q6, [start, #4 * 376]
    ldr     q2, [start, #4 * 392]
    str     q7, [start, #4 * 380]
    ldr     q3, [start, #4 * 396]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 400]
    ldr     q5, [start, #4 * 404]
    ldr     q6, [start, #4 * 408]
    ldr     q7, [start, #4 * 412]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 384]
    sqdmulh v23.4s, v22.4s, v30.4s[0]
    str     q1, [start, #4 * 388]
    mul     v22.4s, v22.4s, v31.4s[0]
    str     q2, [start, #4 * 392]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    str     q3, [start, #4 * 396]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 400]
    ldr     q0, [start, #4 * 416]
    str     q5, [start, #4 * 404]
    ldr     q1, [start, #4 * 420]
    str     q6, [start, #4 * 408]
    ldr     q2, [start, #4 * 424]
    str     q7, [start, #4 * 412]
    ldr     q3, [start, #4 * 428]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 432]
    ldr     q5, [start, #4 * 436]
    ldr     q6, [start, #4 * 440]
    ldr     q7, [start, #4 * 444]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 416]
    sqdmulh v23.4s, v22.4s, v30.4s[0]
    str     q1, [start, #4 * 420]
    mul     v22.4s, v22.4s, v31.4s[0]
    str     q2, [start, #4 * 424]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    str     q3, [start, #4 * 428]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 432]
    ldr     q0, [start, #4 * 448]
    str     q5, [start, #4 * 436]
    ldr     q1, [start, #4 * 452]
    str     q6, [start, #4 * 440]
    ldr     q2, [start, #4 * 456]
    str     q7, [start, #4 * 444]
    ldr     q3, [start, #4 * 460]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 464]
    ldr     q5, [start, #4 * 468]
    ldr     q6, [start, #4 * 472]
    ldr     q7, [start, #4 * 476]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 448]
    sqdmulh v23.4s, v22.4s, v30.4s[0]
    str     q1, [start, #4 * 452]
    mul     v22.4s, v22.4s, v31.4s[0]
    str     q2, [start, #4 * 456]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    str     q3, [start, #4 * 460]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 464]
    ldr     q0, [start, #4 * 480]
    str     q5, [start, #4 * 468]
    ldr     q1, [start, #4 * 484]
    str     q6, [start, #4 * 472]
    ldr     q2, [start, #4 * 488]
    str     q7, [start, #4 * 476]
    ldr     q3, [start, #4 * 492]

    ldr     q24, [x3], #16
    ldr     q25, [x4], #16
    sub     v16.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    ldr     q4, [start, #4 * 496]
    ldr     q5, [start, #4 * 500]
    ldr     q6, [start, #4 * 504]
    ldr     q7, [start, #4 * 508]

    sqdmulh v17.4s, v16.4s, v24.4s[0]
    sub     v18.4s, v2.4s, v3.4s
    mul     v16.4s, v16.4s, v25.4s[0]
    add     v2.4s, v2.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v1.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v24.4s[1]
    sub     v20.4s, v4.4s, v5.4s
    mul     v18.4s, v18.4s, v25.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v24.4s[2]
    sub     v22.4s, v6.4s, v7.4s
    mul     v20.4s, v20.4s, v25.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v5.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v24.4s[3]
    mul     v22.4s, v22.4s, v25.4s[3]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q26, [x5], #8
    ldr     q27, [x6], #8
    sub     v16.4s, v0.4s, v2.4s
    add     v0.4s, v0.4s, v2.4s

    sqdmulh v17.4s, v16.4s, v26.4s[0]
    sub     v18.4s, v1.4s, v3.4s
    mul     v16.4s, v16.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v2.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v26.4s[0]
    sub     v20.4s, v4.4s, v6.4s
    mul     v18.4s, v18.4s, v27.4s[0]
    add     v4.4s, v4.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v3.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v26.4s[1]
    sub     v22.4s, v5.4s, v7.4s
    mul     v20.4s, v20.4s, v27.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    sqdmulh v23.4s, v22.4s, v26.4s[1]
    mul     v22.4s, v22.4s, v27.4s[1]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    ldr     q30, [x7], #4
    ldr     q31, [x9], #4
    sub     v16.4s, v0.4s, v4.4s
    add     v0.4s, v0.4s, v4.4s

    sqdmulh v17.4s, v16.4s, v30.4s[0]
    sub     v18.4s, v1.4s, v5.4s
    mul     v16.4s, v16.4s, v31.4s[0]
    add     v1.4s, v1.4s, v5.4s
    sqdmulh v16.4s, v16.4s, v28.4s[3]
    sub     v4.4s, v17.4s, v16.4s

    sqdmulh v19.4s, v18.4s, v30.4s[0]
    sub     v20.4s, v2.4s, v6.4s
    mul     v18.4s, v18.4s, v31.4s[0]
    add     v2.4s, v2.4s, v6.4s
    sqdmulh v18.4s, v18.4s, v28.4s[3]
    sub     v5.4s, v19.4s, v18.4s

    sqdmulh v21.4s, v20.4s, v30.4s[0]
    sub     v22.4s, v3.4s, v7.4s
    mul     v20.4s, v20.4s, v31.4s[0]
    add     v3.4s, v3.4s, v7.4s
    sqdmulh v20.4s, v20.4s, v28.4s[3]
    sub     v6.4s, v21.4s, v20.4s

    str     q0, [start, #4 * 480]
    str     q1, [start, #4 * 484]
    str     q2, [start, #4 * 488]
    str     q3, [start, #4 * 492]

    sqdmulh v23.4s, v22.4s, v30.4s[0]
    mul     v22.4s, v22.4s, v31.4s[0]
    sqdmulh v22.4s, v22.4s, v28.4s[3]
    sub     v7.4s, v23.4s, v22.4s

    str     q4, [start, #4 * 496]
    str     q5, [start, #4 * 500]
    str     q6, [start, #4 * 504]
    str     q7, [start, #4 * 508]

    /* Layers 4+3+2+1 */
    /* NTT inverse layer 4: length = 32, ridx = 496, loops = 8 */
    /* NTT inverse layer 3: length = 64, ridx = 504, loops = 4 */
    /* NTT inverse layer 2: length = 128, ridx = 508, loops = 2 */
    /* NTT inverse layer 1: length = 256, ridx = 510, loops = 1 */

    mov     start, x0               // Store *coefficients[0]

    /* Preload the required root values, we have enough room */
    /* This works because there are actually only 16 different values */
    /* [496] == [504] == [508] == [510] */
    /* [497] == [505] == [509] */
    /* [498] == [506] */
    /* [499] == [507] */

    ldr     q24, [x1, #4 * 496]     // B[496, 497, 498, 499]
    ldr     q25, [x1, #4 * 500]     // B[500, 501, 502, 503]
    ldr     q26, [x2, #4 * 496]     // B'[496, 497, 498, 499]
    ldr     q27, [x2, #4 * 500]     // B'[500, 501, 502, 503]

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 32]

    ldr     q2, [start, #4 * 64]
    ldr     q3, [start, #4 * 96]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 128]
    ldr     q5, [start, #4 * 160]

    ldr     q6, [start, #4 * 192]
    ldr     q7, [start, #4 * 224]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 256]
    ldr     q17, [start, #4 * 288]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 320]
    ldr     q19, [start, #4 * 352]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 384]
    ldr     q21, [start, #4 * 416]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 448]
    ldr     q23, [start, #4 * 480]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 0]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 32]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 64]
    str     q10, [start, #4 * 96]

    str     q2, [start, #4 * 256]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 288]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 320]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 352]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 128]
    str     q6, [start, #4 * 384]

    str     q12, [start, #4 * 160]
    str     q7, [start, #4 * 416]

    str     q13, [start, #4 * 192]
    str     q15, [start, #4 * 448]

    str     q14, [start, #4 * 224]
    str     q29, [start, #4 * 480]

    ldr     q0, [start, #4 * 4]
    ldr     q1, [start, #4 * 36]

    ldr     q2, [start, #4 * 68]
    ldr     q3, [start, #4 * 100]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 132]
    ldr     q5, [start, #4 * 164]

    ldr     q6, [start, #4 * 196]
    ldr     q7, [start, #4 * 228]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 260]
    ldr     q17, [start, #4 * 292]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 324]
    ldr     q19, [start, #4 * 356]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 388]
    ldr     q21, [start, #4 * 420]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 452]
    ldr     q23, [start, #4 * 484]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 4]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 36]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 68]
    str     q10, [start, #4 * 100]

    str     q2, [start, #4 * 260]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 292]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 324]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 356]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 132]
    str     q6, [start, #4 * 388]

    str     q12, [start, #4 * 164]
    str     q7, [start, #4 * 420]

    str     q13, [start, #4 * 196]
    str     q15, [start, #4 * 452]

    str     q14, [start, #4 * 228]
    str     q29, [start, #4 * 484]

    ldr     q0, [start, #4 * 8]
    ldr     q1, [start, #4 * 40]

    ldr     q2, [start, #4 * 72]
    ldr     q3, [start, #4 * 104]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 136]
    ldr     q5, [start, #4 * 168]

    ldr     q6, [start, #4 * 200]
    ldr     q7, [start, #4 * 232]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 264]
    ldr     q17, [start, #4 * 296]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 328]
    ldr     q19, [start, #4 * 360]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 392]
    ldr     q21, [start, #4 * 424]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 456]
    ldr     q23, [start, #4 * 488]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 8]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 40]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 72]
    str     q10, [start, #4 * 104]

    str     q2, [start, #4 * 264]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 296]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 328]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 360]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 136]
    str     q6, [start, #4 * 392]

    str     q12, [start, #4 * 168]
    str     q7, [start, #4 * 424]

    str     q13, [start, #4 * 200]
    str     q15, [start, #4 * 456]

    str     q14, [start, #4 * 232]
    str     q29, [start, #4 * 488]

    ldr     q0, [start, #4 * 12]
    ldr     q1, [start, #4 * 44]

    ldr     q2, [start, #4 * 76]
    ldr     q3, [start, #4 * 108]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 140]
    ldr     q5, [start, #4 * 172]

    ldr     q6, [start, #4 * 204]
    ldr     q7, [start, #4 * 236]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 268]
    ldr     q17, [start, #4 * 300]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 332]
    ldr     q19, [start, #4 * 364]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 396]
    ldr     q21, [start, #4 * 428]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 460]
    ldr     q23, [start, #4 * 492]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 12]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 44]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 76]
    str     q10, [start, #4 * 108]

    str     q2, [start, #4 * 268]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 300]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 332]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 364]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 140]
    str     q6, [start, #4 * 396]

    str     q12, [start, #4 * 172]
    str     q7, [start, #4 * 428]

    str     q13, [start, #4 * 204]
    str     q15, [start, #4 * 460]

    str     q14, [start, #4 * 236]
    str     q29, [start, #4 * 492]

    ldr     q0, [start, #4 * 16]
    ldr     q1, [start, #4 * 48]

    ldr     q2, [start, #4 * 80]
    ldr     q3, [start, #4 * 112]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 144]
    ldr     q5, [start, #4 * 176]

    ldr     q6, [start, #4 * 208]
    ldr     q7, [start, #4 * 240]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 272]
    ldr     q17, [start, #4 * 304]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 336]
    ldr     q19, [start, #4 * 368]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 400]
    ldr     q21, [start, #4 * 432]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 464]
    ldr     q23, [start, #4 * 496]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 16]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 48]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 80]
    str     q10, [start, #4 * 112]

    str     q2, [start, #4 * 272]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 304]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 336]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 368]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 144]
    str     q6, [start, #4 * 400]

    str     q12, [start, #4 * 176]
    str     q7, [start, #4 * 432]

    str     q13, [start, #4 * 208]
    str     q15, [start, #4 * 464]

    str     q14, [start, #4 * 240]
    str     q29, [start, #4 * 496]

    ldr     q0, [start, #4 * 20]
    ldr     q1, [start, #4 * 52]

    ldr     q2, [start, #4 * 84]
    ldr     q3, [start, #4 * 116]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 148]
    ldr     q5, [start, #4 * 180]

    ldr     q6, [start, #4 * 212]
    ldr     q7, [start, #4 * 244]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 276]
    ldr     q17, [start, #4 * 308]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 340]
    ldr     q19, [start, #4 * 372]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 404]
    ldr     q21, [start, #4 * 436]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 468]
    ldr     q23, [start, #4 * 500]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 20]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 52]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 84]
    str     q10, [start, #4 * 116]

    str     q2, [start, #4 * 276]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 308]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 340]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 372]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 148]
    str     q6, [start, #4 * 404]

    str     q12, [start, #4 * 180]
    str     q7, [start, #4 * 436]

    str     q13, [start, #4 * 212]
    str     q15, [start, #4 * 468]

    str     q14, [start, #4 * 244]
    str     q29, [start, #4 * 500]

    ldr     q0, [start, #4 * 24]
    ldr     q1, [start, #4 * 56]

    ldr     q2, [start, #4 * 88]
    ldr     q3, [start, #4 * 120]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 152]
    ldr     q5, [start, #4 * 184]

    ldr     q6, [start, #4 * 216]
    ldr     q7, [start, #4 * 248]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 280]
    ldr     q17, [start, #4 * 312]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 344]
    ldr     q19, [start, #4 * 376]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 408]
    ldr     q21, [start, #4 * 440]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 472]
    ldr     q23, [start, #4 * 504]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 24]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 56]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 88]
    str     q10, [start, #4 * 120]

    str     q2, [start, #4 * 280]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 312]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 344]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 376]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 152]
    str     q6, [start, #4 * 408]

    str     q12, [start, #4 * 184]
    str     q7, [start, #4 * 440]

    str     q13, [start, #4 * 216]
    str     q15, [start, #4 * 472]

    str     q14, [start, #4 * 248]
    str     q29, [start, #4 * 504]

    ldr     q0, [start, #4 * 28]
    ldr     q1, [start, #4 * 60]

    ldr     q2, [start, #4 * 92]
    ldr     q3, [start, #4 * 124]

    sub_add v0.4s, v1.4s, v8.4s
    sub     v9.4s, v2.4s, v3.4s
    sqdmulh v10.4s, v9.4s, v24.4s[1]
    add     v2.4s, v2.4s, v3.4s

    ldr     q4, [start, #4 * 156]
    ldr     q5, [start, #4 * 188]

    ldr     q6, [start, #4 * 220]
    ldr     q7, [start, #4 * 252]

    sub     v11.4s, v4.4s, v5.4s
    mul     v9.4s, v9.4s, v26.4s[1]
    add     v4.4s, v4.4s, v5.4s
    sqdmulh v9.4s, v9.4s, v28.4s[3]
    sub     v3.4s, v10.4s, v9.4s

    sqdmulh v12.4s, v11.4s, v24.4s[2]
    sub     v13.4s, v6.4s, v7.4s
    mul     v11.4s, v11.4s, v26.4s[2]
    add     v6.4s, v6.4s, v7.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v5.4s, v12.4s, v11.4s

    ldr     q16, [start, #4 * 284]
    ldr     q17, [start, #4 * 316]

    sqdmulh v14.4s, v13.4s, v24.4s[3]
    mul     v13.4s, v13.4s, v26.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v7.4s, v14.4s, v13.4s

    ldr     q18, [start, #4 * 348]
    ldr     q19, [start, #4 * 380]

    sub     v15.4s, v16.4s, v17.4s
    add     v16.4s, v16.4s, v17.4s

    ldr     q20, [start, #4 * 412]
    ldr     q21, [start, #4 * 444]

    sqdmulh v29.4s, v15.4s, v25.4s[0]
    sub     v30.4s, v18.4s, v19.4s
    mul     v15.4s, v15.4s, v27.4s[0]
    add     v18.4s, v18.4s, v19.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]
    sub     v17.4s, v29.4s, v15.4s

    ldr     q22, [start, #4 * 476]
    ldr     q23, [start, #4 * 508]

    sqdmulh v31.4s, v30.4s, v25.4s[1]
    sub     v11.4s, v20.4s, v21.4s
    mul     v30.4s, v30.4s, v27.4s[1]
    add     v20.4s, v20.4s, v21.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    sub     v19.4s, v31.4s, v30.4s

    sqdmulh v12.4s, v11.4s, v25.4s[2]
    sub     v13.4s, v22.4s, v23.4s
    mul     v11.4s, v11.4s, v27.4s[2]
    add     v22.4s, v22.4s, v23.4s
    sqdmulh v11.4s, v11.4s, v28.4s[3]
    sub     v21.4s, v12.4s, v11.4s

    sqdmulh v14.4s, v13.4s, v25.4s[3]
    mul     v13.4s, v13.4s, v27.4s[3]
    sqdmulh v13.4s, v13.4s, v28.4s[3]
    sub     v23.4s, v14.4s, v13.4s

    sub_add v0.4s, v2.4s, v9.4s
    sub_add v8.4s, v3.4s, v10.4s

    sub_add v4.4s, v6.4s, v1.4s

    sqdmulh v2.4s, v1.4s, v24.4s[1]
    sub     v3.4s, v5.4s, v7.4s
    mul     v1.4s, v1.4s, v26.4s[1]
    add     v5.4s, v5.4s, v7.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    sub     v6.4s, v2.4s, v1.4s

    sqdmulh v11.4s, v3.4s, v24.4s[1]
    sub     v12.4s, v16.4s, v18.4s
    mul     v3.4s, v3.4s, v26.4s[1]
    add     v16.4s, v16.4s, v18.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v7.4s, v11.4s, v3.4s

    sqdmulh v13.4s, v12.4s, v24.4s[2]
    sub     v14.4s, v17.4s, v19.4s
    mul     v12.4s, v12.4s, v26.4s[2]
    add     v17.4s, v17.4s, v19.4s
    sqdmulh v12.4s, v12.4s, v28.4s[3]
    sub     v18.4s, v13.4s, v12.4s

    sqdmulh v15.4s, v14.4s, v24.4s[2]
    sub     v29.4s, v20.4s, v22.4s
    mul     v14.4s, v14.4s, v26.4s[2]
    add     v20.4s, v20.4s, v22.4s
    sqdmulh v14.4s, v14.4s, v28.4s[3]
    sub     v19.4s, v15.4s, v14.4s

    sqdmulh v30.4s, v29.4s, v24.4s[3]
    sub     v31.4s, v21.4s, v23.4s
    mul     v29.4s, v29.4s, v26.4s[3]
    add     v21.4s, v21.4s, v23.4s
    sqdmulh v29.4s, v29.4s, v28.4s[3]
    sub     v22.4s, v30.4s, v29.4s

    sqdmulh v1.4s, v31.4s, v24.4s[3]
    sub_add v0.4s, v4.4s, v11.4s
    mul     v31.4s, v31.4s, v26.4s[3]
    sub_add v8.4s, v5.4s, v12.4s
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub_add v9.4s, v6.4s, v13.4s
    sub     v23.4s, v1.4s, v31.4s
    sub_add v10.4s, v7.4s, v14.4s

    sub     v2.4s, v16.4s, v20.4s
    add     v16.4s, v16.4s, v20.4s

    sqdmulh v3.4s, v2.4s, v24.4s[1]
    sub     v4.4s, v17.4s, v21.4s
    mul     v2.4s, v2.4s, v26.4s[1]
    add     v17.4s, v17.4s, v21.4s
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    sub     v20.4s, v3.4s, v2.4s

    sqdmulh v5.4s, v4.4s, v24.4s[1]
    sub     v6.4s, v18.4s, v22.4s
    mul     v4.4s, v4.4s, v26.4s[1]
    add     v18.4s, v18.4s, v22.4s
    sqdmulh v4.4s, v4.4s, v28.4s[3]
    sub     v21.4s, v5.4s, v4.4s

    sqdmulh v7.4s, v6.4s, v24.4s[1]
    sub     v15.4s, v19.4s, v23.4s
    mul     v6.4s, v6.4s, v26.4s[1]
    add     v19.4s, v19.4s, v23.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]
    sub     v22.4s, v7.4s, v6.4s

    sqdmulh v29.4s, v15.4s, v24.4s[1]
    sub_add v0.4s, v16.4s, v2.4s
    mul     v15.4s, v15.4s, v26.4s[1]
    sub_add v8.4s, v17.4s, v3.4s
    sqdmulh v15.4s, v15.4s, v28.4s[3]

    str     q0, [start, #4 * 28]
    sub_add v9.4s, v18.4s, v4.4s
    sub     v23.4s, v29.4s, v15.4s

    str     q8, [start, #4 * 60]
    sub_add v10.4s, v19.4s, v5.4s

    str     q9, [start, #4 * 92]
    str     q10, [start, #4 * 124]

    str     q2, [start, #4 * 284]
    sub_add v11.4s, v20.4s, v6.4s
    str     q3, [start, #4 * 316]
    sub_add v12.4s, v21.4s, v7.4s
    str     q4, [start, #4 * 348]
    sub_add v13.4s, v22.4s, v15.4s
    str     q5, [start, #4 * 380]

    sub_add v14.4s, v23.4s, v29.4s

    str     q11, [start, #4 * 156]
    str     q6, [start, #4 * 412]

    str     q12, [start, #4 * 188]
    str     q7, [start, #4 * 444]

    str     q13, [start, #4 * 220]
    str     q15, [start, #4 * 476]

    str     q14, [start, #4 * 252]
    str     q29, [start, #4 * 508]

    sub     sp, sp, #64
    ld1     { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    ld1     {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32
    ret     lr
