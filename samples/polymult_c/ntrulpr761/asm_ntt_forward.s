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

__asm_ntt_forward:

    sub     sp, sp, #64
    st1     { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    st1     {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32

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

    /* Preload the required root values, we have enough room */
    /* This works because there are actually only 16 different values */
    /* [7] == [3] == [1] == [0] */
    /* [8] == [4] == [2] */
    /* [9] == [5] */
    /* [10] == [6] */

    ldr     q24, [x1, #4 * 7]       // B[7, 8, 9, 10]
    ldr     q25, [x1, #4 * 11]      // B[11, 12, 13, 14]
    ldr     q26, [x2, #4 * 7]       // B'[7, 8, 9, 10]
    ldr     q27, [x2, #4 * 11]      // B'[11, 12, 13, 14]

    /* Repeat this sequence 8 times. We need to perform the calculation for
     * every integer coefficient. We have intervals of 32 values and we can take
     * 4 values in one go. 32 / 4 = 8. */

    ldr     q0, [start, #4 * 0]
    ldr     q16, [start, #4 * 256]
    ldr     q1, [start, #4 * 32]
    ldr     q17, [start, #4 * 288]
    ldr     q2, [start, #4 * 64]
    ldr     q18, [start, #4 * 320]
    ldr     q3, [start, #4 * 96]
    ldr     q19, [start, #4 * 352]

    ldr     q4, [start, #4 * 128]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 384]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 160]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 416]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 192]

    ldr     q22, [start, #4 * 448]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 224]
    ldr     q23, [start, #4 * 480]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 0]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 32]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 64]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 96]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 128]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 160]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 192]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 224]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 256]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 288]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 320]
    str     q11, [start, #4 * 352]
    add     v14.4s, v14.4s, v2.4s

    ldr     q0, [start, #4 * 4]
    str     q12, [start, #4 * 384]
    ldr     q16, [start, #4 * 260]
    str     q13, [start, #4 * 416]
    ldr     q1, [start, #4 * 36]
    str     q15, [start, #4 * 480]
    ldr     q17, [start, #4 * 292]
    str     q14, [start, #4 * 448]

    ldr     q2, [start, #4 * 68]
    ldr     q18, [start, #4 * 324]
    ldr     q3, [start, #4 * 100]
    ldr     q19, [start, #4 * 356]

    ldr     q4, [start, #4 * 132]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 388]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 164]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 420]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 196]

    ldr     q22, [start, #4 * 452]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 228]
    ldr     q23, [start, #4 * 484]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 4]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 36]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 68]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 100]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 132]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 164]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 196]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 228]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 260]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 292]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 324]
    str     q11, [start, #4 * 356]
    add     v14.4s, v14.4s, v2.4s

    ldr     q0, [start, #4 * 8]
    str     q12, [start, #4 * 388]
    ldr     q16, [start, #4 * 264]
    str     q13, [start, #4 * 420]
    ldr     q1, [start, #4 * 40]
    str     q15, [start, #4 * 484]
    ldr     q17, [start, #4 * 296]
    str     q14, [start, #4 * 452]

    ldr     q2, [start, #4 * 72]
    ldr     q18, [start, #4 * 328]
    ldr     q3, [start, #4 * 104]
    ldr     q19, [start, #4 * 360]

    ldr     q4, [start, #4 * 136]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 392]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 168]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 424]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 200]

    ldr     q22, [start, #4 * 456]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 232]
    ldr     q23, [start, #4 * 488]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 8]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 40]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 72]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 104]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 136]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 168]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 200]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 232]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 264]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 296]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 328]
    str     q11, [start, #4 * 360]
    add     v14.4s, v14.4s, v2.4s

    ldr     q0, [start, #4 * 12]
    str     q12, [start, #4 * 392]
    ldr     q16, [start, #4 * 268]
    str     q13, [start, #4 * 424]
    ldr     q1, [start, #4 * 44]
    str     q15, [start, #4 * 488]
    ldr     q17, [start, #4 * 300]
    str     q14, [start, #4 * 456]

    ldr     q2, [start, #4 * 76]
    ldr     q18, [start, #4 * 332]
    ldr     q3, [start, #4 * 108]
    ldr     q19, [start, #4 * 364]

    ldr     q4, [start, #4 * 140]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 396]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 172]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 428]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 204]

    ldr     q22, [start, #4 * 460]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 236]
    ldr     q23, [start, #4 * 492]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 12]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 44]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 76]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 108]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 140]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 172]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 204]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 236]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 268]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 300]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 332]
    str     q11, [start, #4 * 364]
    add     v14.4s, v14.4s, v2.4s

    ldr     q0, [start, #4 * 16]
    str     q12, [start, #4 * 396]
    ldr     q16, [start, #4 * 272]
    str     q13, [start, #4 * 428]
    ldr     q1, [start, #4 * 48]
    str     q15, [start, #4 * 492]
    ldr     q17, [start, #4 * 304]
    str     q14, [start, #4 * 460]

    ldr     q2, [start, #4 * 80]
    ldr     q18, [start, #4 * 336]
    ldr     q3, [start, #4 * 112]
    ldr     q19, [start, #4 * 368]

    ldr     q4, [start, #4 * 144]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 400]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 176]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 432]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 208]

    ldr     q22, [start, #4 * 464]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 240]
    ldr     q23, [start, #4 * 496]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 16]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 48]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 80]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 112]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 144]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 176]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 208]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 240]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 272]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 304]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 336]
    str     q11, [start, #4 * 368]
    add     v14.4s, v14.4s, v2.4s

    ldr     q0, [start, #4 * 20]
    str     q12, [start, #4 * 400]
    ldr     q16, [start, #4 * 276]
    str     q13, [start, #4 * 432]
    ldr     q1, [start, #4 * 52]
    str     q15, [start, #4 * 496]
    ldr     q17, [start, #4 * 308]
    str     q14, [start, #4 * 464]

    ldr     q2, [start, #4 * 84]
    ldr     q18, [start, #4 * 340]
    ldr     q3, [start, #4 * 116]
    ldr     q19, [start, #4 * 372]

    ldr     q4, [start, #4 * 148]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 404]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 180]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 436]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 212]

    ldr     q22, [start, #4 * 468]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 244]
    ldr     q23, [start, #4 * 500]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 20]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 52]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 84]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 116]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 148]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 180]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 212]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 244]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 276]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 308]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 340]
    str     q11, [start, #4 * 372]
    add     v14.4s, v14.4s, v2.4s

    str     q12, [start, #4 * 404]
    str     q13, [start, #4 * 436]
    str     q15, [start, #4 * 500]
    str     q14, [start, #4 * 468]

    ldr     q0, [start, #4 * 24]
    ldr     q16, [start, #4 * 280]
    ldr     q1, [start, #4 * 56]
    ldr     q17, [start, #4 * 312]
    ldr     q2, [start, #4 * 88]
    ldr     q18, [start, #4 * 344]
    ldr     q3, [start, #4 * 120]
    ldr     q19, [start, #4 * 376]

    ldr     q4, [start, #4 * 152]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 408]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 184]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 440]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 216]

    ldr     q22, [start, #4 * 472]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 248]
    ldr     q23, [start, #4 * 504]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 24]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 56]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 88]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 120]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 152]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 184]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 216]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 248]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 280]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 312]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 344]
    str     q11, [start, #4 * 376]
    add     v14.4s, v14.4s, v2.4s

    ldr     q0, [start, #4 * 28]
    str     q12, [start, #4 * 408]
    ldr     q1, [start, #4 * 60]
    str     q13, [start, #4 * 440]
    ldr     q2, [start, #4 * 92]
    str     q15, [start, #4 * 504]
    ldr     q3, [start, #4 * 124]
    str     q14, [start, #4 * 472]

    ldr     q16, [start, #4 * 284]
    ldr     q17, [start, #4 * 316]
    ldr     q18, [start, #4 * 348]
    ldr     q19, [start, #4 * 380]

    ldr     q4, [start, #4 * 156]
    sub_add v0.4s, v16.4s, v8.4s
    ldr     q20, [start, #4 * 412]
    sub_add v1.4s, v17.4s, v9.4s
    ldr     q5, [start, #4 * 188]
    sub_add v2.4s, v18.4s, v10.4s
    ldr     q21, [start, #4 * 444]
    sub_add v3.4s, v19.4s, v11.4s
    ldr     q6, [start, #4 * 220]

    ldr     q22, [start, #4 * 476]
    sub_add v4.4s, v20.4s, v12.4s
    ldr     q7, [start, #4 * 252]
    ldr     q23, [start, #4 * 508]
    sub_add v5.4s, v21.4s, v13.4s

    sub_add v0.4s, v4.4s, v16.4s
    sub_add v1.4s, v5.4s, v17.4s
    sub_add v6.4s, v22.4s, v14.4s
    sub_add v7.4s, v23.4s, v15.4s

    sqdmulh v4.4s, v12.4s, v24.4s[1]
    mul     v5.4s, v12.4s, v26.4s[1]

    sub_add v2.4s, v6.4s, v18.4s
    sub_add v3.4s, v7.4s, v19.4s

    sqdmulh v5.4s, v5.4s, v28.4s[3]
    sub     v4.4s, v4.4s, v5.4s

    sqdmulh v6.4s, v13.4s, v24.4s[1]
    sub     v12.4s, v8.4s, v4.4s
    mul     v7.4s, v13.4s, v26.4s[1]
    add     v8.4s, v8.4s, v4.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v14.4s, v24.4s[1]
    sub     v13.4s, v9.4s, v6.4s
    mul     v21.4s, v14.4s, v26.4s[1]
    add     v9.4s, v9.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v15.4s, v24.4s[1]
    sub     v14.4s, v10.4s, v20.4s
    mul     v23.4s, v15.4s, v26.4s[1]
    add     v10.4s, v10.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sub     v15.4s, v11.4s, v22.4s
    add     v11.4s, v11.4s, v22.4s

    sub_add v0.4s, v2.4s, v4.4s

    sub     v5.4s, v1.4s, v3.4s
    sqdmulh v2.4s, v18.4s, v24.4s[1]
    add     v1.4s, v1.4s, v3.4s
    mul     v3.4s, v18.4s, v26.4s[1]
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v19.4s, v24.4s[1]
    sub     v18.4s, v16.4s, v2.4s
    mul     v7.4s, v19.4s, v26.4s[1]
    add     v16.4s, v16.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sqdmulh v20.4s, v10.4s, v24.4s[2]
    sub     v19.4s, v17.4s, v6.4s
    mul     v21.4s, v10.4s, v26.4s[2]
    add     v17.4s, v17.4s, v6.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v11.4s, v24.4s[2]
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v26.4s[2]
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v2.4s, v14.4s, v24.4s[3]
    sub     v11.4s, v9.4s, v22.4s
    mul     v3.4s, v14.4s, v26.4s[3]
    add     v9.4s, v9.4s, v22.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    sub     v2.4s, v2.4s, v3.4s

    sqdmulh v6.4s, v15.4s, v24.4s[3]
    sub     v14.4s, v12.4s, v2.4s
    mul     v7.4s, v15.4s, v26.4s[3]
    add     v12.4s, v12.4s, v2.4s
    sqdmulh v7.4s, v7.4s, v28.4s[3]
    sub     v6.4s, v6.4s, v7.4s

    sub     v15.4s, v13.4s, v6.4s
    add     v13.4s, v13.4s, v6.4s

    sub_add v0.4s, v1.4s, v20.4s

    sqdmulh v1.4s, v5.4s, v24.4s[1]
    mul     v2.4s, v5.4s, v26.4s[1]
    sqdmulh v2.4s, v2.4s, v28.4s[3]
    str     q0, [start, #4 * 28]

    sub     v1.4s, v1.4s, v2.4s
    sqdmulh v3.4s, v17.4s, v24.4s[2]
    str     q20, [start, #4 * 60]
    sub     v5.4s, v4.4s, v1.4s
    mul     v6.4s, v17.4s, v26.4s[2]
    add     v4.4s, v4.4s, v1.4s
    sqdmulh v6.4s, v6.4s, v28.4s[3]

    sub     v3.4s, v3.4s, v6.4s
    sqdmulh v7.4s, v19.4s, v24.4s[3]
    sub     v17.4s, v16.4s, v3.4s
    mul     v21.4s, v19.4s, v26.4s[3]
    add     v16.4s, v16.4s, v3.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    str     q4, [start, #4 * 92]

    sub     v7.4s, v7.4s, v21.4s
    sqdmulh v22.4s, v9.4s, v25.4s[0]
    str     q5, [start, #4 * 124]
    sub     v19.4s, v18.4s, v7.4s
    mul     v23.4s, v9.4s, v27.4s[0]
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    add     v18.4s, v18.4s, v7.4s

    sub     v22.4s, v22.4s, v23.4s
    sqdmulh v29.4s, v11.4s, v25.4s[1]
    str     q16, [start, #4 * 156]
    sub     v9.4s, v8.4s, v22.4s
    mul     v30.4s, v11.4s, v27.4s[1]
    add     v8.4s, v8.4s, v22.4s
    sqdmulh v30.4s, v30.4s, v28.4s[3]
    str     q17, [start, #4 * 188]

    sub     v29.4s, v29.4s, v30.4s
    sqdmulh v31.4s, v13.4s, v25.4s[2]
    str     q18, [start, #4 * 220]
    sub     v11.4s, v10.4s, v29.4s
    mul     v1.4s, v13.4s, v27.4s[2]
    add     v10.4s, v10.4s, v29.4s
    sqdmulh v1.4s, v1.4s, v28.4s[3]
    str     q19, [start, #4 * 252]

    sub     v31.4s, v31.4s, v1.4s
    sqdmulh v2.4s, v15.4s, v25.4s[3]
    str     q8, [start, #4 * 284]
    sub     v13.4s, v12.4s, v31.4s
    mul     v3.4s, v15.4s, v27.4s[3]
    add     v12.4s, v12.4s, v31.4s
    sqdmulh v3.4s, v3.4s, v28.4s[3]
    str     q9, [start, #4 * 316]

    sub     v2.4s, v2.4s, v3.4s
    sub     v15.4s, v14.4s, v2.4s
    str     q10, [start, #4 * 348]
    str     q11, [start, #4 * 380]
    add     v14.4s, v14.4s, v2.4s

    str     q12, [start, #4 * 412]
    str     q13, [start, #4 * 444]
    str     q15, [start, #4 * 508]
    str     q14, [start, #4 * 476]

    /* Layers 5+6+7 */
    /* NTT forward layer 5: length = 16, ridx = 15, loops = 16 */
    /* NTT forward layer 6: length = 8,  ridx = 31, loops = 32 */
    /* NTT forward layer 7: length = 4,  ridx = 63, loops = 64 */

    mov     start, x0               // Store *coefficients[0]

    /* Repeat this sequence 16 times. We need to perform the calculation for
     * every integer coefficient. We perform the calculation on 32 values in one
     * go. 512 / 32 = 16. */

    ldr     q0, [start, #4 * 0]
    ldr     q4, [start, #4 * 16]
    ldr     q1, [start, #4 * 4]
    ldr     q5, [start, #4 * 20]

    /* Store layer specific values  */

    add     x3, x1, #4 * 16         // LAYER 5: ridx, used for indexing B
    add     x4, x2, #4 * 16         // LAYER 5: ridx, used for indexing B'
    add     x5, x1, #4 * 32         // LAYER 6: ridx, used for indexing B

    ldr     q2, [start, #4 * 8]
    ldr     q6, [start, #4 * 24]

    sub_add v0.4s, v4.4s, v8.4s
    sub_add v1.4s, v5.4s, v9.4s

    ldr     q3, [start, #4 * 12]
    ldr     q7, [start, #4 * 28]

    add     x6, x2, #4 * 32         // LAYER 6: ridx, used for indexing B'
    add     x7, x1, #4 * 63         // LAYER 7: ridx, used for indexing B
    add     x9, x2, #4 * 63         // LAYER 7: ridx, used for indexing B'

    sub_add v2.4s, v6.4s, v10.4s
    sub_add v3.4s, v7.4s, v11.4s

    // So now the order is:
    // 0, 1, 2, 3
    // 8, 9, 10, 11

    ldr     q26, [x5], #4
    ldr     q27, [x6], #4

    sub_add v0.4s, v2.4s, v12.4s

    sqdmulh v16.4s, v10.4s, v26.4s[0]
    sub     v13.4s, v1.4s, v3.4s
    mul     v17.4s, v10.4s, v27.4s[0]
    add     v1.4s, v1.4s, v3.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    // So now the order is:
    // 0, 1, 12, 13
    // 8, 9, 10, 11

    sqdmulh v18.4s, v11.4s, v26.4s[0]
    sub     v10.4s, v8.4s, v16.4s
    mul     v19.4s, v11.4s, v27.4s[0]
    add     v8.4s, v8.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    ldr     q30, [x7], #16
    ldr     q31, [x9], #16

    sub     v11.4s, v9.4s, v18.4s
    add     v9.4s, v9.4s, v18.4s
    sub     v14.4s, v0.4s, v1.4s
    add     v0.4s, v0.4s, v1.4s

    // So now the order is:
    // 0, 14, 12, 13
    // 8, 9, 10, 11

    sqdmulh v16.4s, v13.4s, v30.4s[1]
    mul     v17.4s, v13.4s, v31.4s[1]
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    str     q14, [start, #4 * 4]
    str     q0, [start, #4 * 0]


    sqdmulh v18.4s, v9.4s, v30.4s[2]
    sub     v16.4s, v16.4s, v17.4s
    sub     v13.4s, v12.4s, v16.4s
    mul     v19.4s, v9.4s, v31.4s[2]
    add     v12.4s, v12.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]

    str     q12, [start, #4 * 8]
    str     q13, [start, #4 * 12]

    sqdmulh v20.4s, v11.4s, v30.4s[3]
    sub     v18.4s, v18.4s, v19.4s
    sub     v9.4s, v8.4s, v18.4s
    mul     v21.4s, v11.4s, v31.4s[3]
    add     v8.4s, v8.4s, v18.4s

    str     q8, [start, #4 * 16]
    str     q9, [start, #4 * 20]

    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q24, [x3], #4
    sub     v20.4s, v20.4s, v21.4s
    sub     v11.4s, v10.4s, v20.4s
    add     v10.4s, v10.4s, v20.4s

    ldr     q25, [x4], #4
    ldr     q4, [start, #4 * 48]

    str     q10, [start, #4 * 24]
    str     q11, [start, #4 * 28]

    ldr     q5, [start, #4 * 52]
    ldr     q0, [start, #4 * 32]
    ldr     q1, [start, #4 * 36]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 56]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 60]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 40]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 44]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 36]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 32]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 40]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 44]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    str     q4, [start, #4 * 48]
    str     q5, [start, #4 * 52]
    str     q6, [start, #4 * 56]
    str     q7, [start, #4 * 60]

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    ldr     q4, [start, #4 * 80]
    ldr     q5, [start, #4 * 84]
    ldr     q0, [start, #4 * 64]
    ldr     q1, [start, #4 * 68]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 88]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 92]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 72]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 76]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 68]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 64]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 72]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 76]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    str     q4, [start, #4 * 80]
    str     q5, [start, #4 * 84]
    str     q6, [start, #4 * 88]
    str     q7, [start, #4 * 92]

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    ldr     q4, [start, #4 * 112]
    ldr     q5, [start, #4 * 116]
    ldr     q0, [start, #4 * 96]
    ldr     q1, [start, #4 * 100]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 120]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 124]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 104]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 108]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 100]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 96]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 104]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 108]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 112]
    ldr     q4, [start, #4 * 144]
    str     q5, [start, #4 * 116]
    ldr     q5, [start, #4 * 148]
    str     q6, [start, #4 * 120]
    str     q7, [start, #4 * 124]

    ldr     q0, [start, #4 * 128]
    ldr     q1, [start, #4 * 132]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 152]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 156]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 136]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 140]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 132]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 128]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 136]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 140]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 144]
    ldr     q4, [start, #4 * 176]
    str     q5, [start, #4 * 148]
    ldr     q5, [start, #4 * 180]
    str     q6, [start, #4 * 152]
    str     q7, [start, #4 * 156]

    ldr     q0, [start, #4 * 160]
    ldr     q1, [start, #4 * 164]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 184]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 188]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 168]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 172]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 164]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 160]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 168]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 172]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 176]
    ldr     q4, [start, #4 * 208]
    str     q5, [start, #4 * 180]
    ldr     q5, [start, #4 * 212]
    str     q6, [start, #4 * 184]
    str     q7, [start, #4 * 188]

    ldr     q0, [start, #4 * 192]
    ldr     q1, [start, #4 * 196]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 216]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 220]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 200]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 204]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 196]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 192]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 200]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 204]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 208]
    ldr     q4, [start, #4 * 240]
    str     q5, [start, #4 * 212]
    ldr     q5, [start, #4 * 244]
    str     q6, [start, #4 * 216]
    str     q7, [start, #4 * 220]

    ldr     q0, [start, #4 * 224]
    ldr     q1, [start, #4 * 228]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 248]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 252]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 232]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 236]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 228]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 224]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 232]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 236]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 240]
    ldr     q4, [start, #4 * 272]
    str     q5, [start, #4 * 244]
    str     q6, [start, #4 * 248]
    ldr     q5, [start, #4 * 276]
    str     q7, [start, #4 * 252]

    ldr     q0, [start, #4 * 256]
    ldr     q1, [start, #4 * 260]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 280]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 284]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 264]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 268]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 260]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 256]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 264]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 268]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 272]
    ldr     q4, [start, #4 * 304]
    str     q5, [start, #4 * 276]
    ldr     q5, [start, #4 * 308]
    str     q6, [start, #4 * 280]
    str     q7, [start, #4 * 284]

    ldr     q0, [start, #4 * 288]
    ldr     q1, [start, #4 * 292]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 312]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 316]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 296]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 300]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 292]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 288]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 296]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 300]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 304]
    ldr     q4, [start, #4 * 336]
    str     q5, [start, #4 * 308]
    ldr     q5, [start, #4 * 340]
    str     q6, [start, #4 * 312]
    str     q7, [start, #4 * 316]

    ldr     q0, [start, #4 * 320]
    ldr     q1, [start, #4 * 324]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 344]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 348]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 328]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 332]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 324]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 320]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 328]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 332]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 336]
    ldr     q4, [start, #4 * 368]
    str     q5, [start, #4 * 340]
    ldr     q5, [start, #4 * 372]
    str     q6, [start, #4 * 344]
    str     q7, [start, #4 * 348]

    ldr     q0, [start, #4 * 352]
    ldr     q1, [start, #4 * 356]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 376]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 380]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 360]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 364]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 356]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 352]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 360]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 364]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 368]
    ldr     q4, [start, #4 * 400]
    str     q5, [start, #4 * 372]
    ldr     q5, [start, #4 * 404]
    str     q6, [start, #4 * 376]
    str     q7, [start, #4 * 380]

    ldr     q0, [start, #4 * 384]
    ldr     q1, [start, #4 * 388]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 408]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 412]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 392]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 396]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 388]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 384]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 392]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 396]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 400]
    ldr     q4, [start, #4 * 432]
    str     q5, [start, #4 * 404]
    ldr     q5, [start, #4 * 436]
    str     q6, [start, #4 * 408]
    str     q7, [start, #4 * 412]

    ldr     q0, [start, #4 * 416]
    ldr     q1, [start, #4 * 420]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 440]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 444]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 424]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 428]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 420]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 416]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 424]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 428]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 432]
    ldr     q4, [start, #4 * 464]
    str     q5, [start, #4 * 436]
    ldr     q5, [start, #4 * 468]
    str     q6, [start, #4 * 440]
    str     q7, [start, #4 * 444]

    ldr     q0, [start, #4 * 448]
    ldr     q1, [start, #4 * 452]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 472]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 476]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 456]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 460]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 452]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 448]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 456]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 460]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    ldr     q24, [x3], #4
    ldr     q25, [x4], #4

    str     q4, [start, #4 * 464]
    ldr     q4, [start, #4 * 496]
    str     q5, [start, #4 * 468]
    ldr     q5, [start, #4 * 500]
    str     q6, [start, #4 * 472]
    str     q7, [start, #4 * 476]

    ldr     q0, [start, #4 * 480]
    ldr     q1, [start, #4 * 484]

    sqdmulh v16.4s, v4.4s, v24.4s[0]
    ldr     q6, [start, #4 * 504]
    mul     v17.4s, v4.4s, v25.4s[0]
    ldr     q7, [start, #4 * 508]

    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q2, [start, #4 * 488]
    sub     v16.4s, v16.4s, v17.4s
    ldr     q3, [start, #4 * 492]

    sqdmulh v18.4s, v5.4s, v24.4s[0]
    sub     v4.4s, v0.4s, v16.4s
    mul     v19.4s, v5.4s, v25.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v24.4s[0]
    ldr     q26, [x5], #8
    sub     v5.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v25.4s[0]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    ldr     q27, [x6], #8
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v24.4s[0]
    sub     v6.4s, v2.4s, v20.4s
    mul     v23.4s, v7.4s, v25.4s[0]
    add     v2.4s, v2.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v2.4s, v26.4s[0]
    ldr     q30, [x7], #16
    sub     v7.4s, v3.4s, v22.4s
    mul     v17.4s, v2.4s, v27.4s[0]
    add     v3.4s, v3.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q31, [x9], #16
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v26.4s[0]
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v27.4s[0]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v6.4s, v26.4s[1]
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v6.4s, v27.4s[1]
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s

    sqdmulh v22.4s, v7.4s, v26.4s[1]
    sub     v6.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v27.4s[1]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    sqdmulh v16.4s, v1.4s, v30.4s[0]
    sub     v7.4s, v5.4s, v22.4s
    mul     v17.4s, v1.4s, v31.4s[0]
    add     v5.4s, v5.4s, v22.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    sub     v16.4s, v16.4s, v17.4s

    sqdmulh v18.4s, v3.4s, v30.4s[1]
    sub     v1.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v31.4s[1]
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]
    str     q1, [start, #4 * 484]
    sub     v18.4s, v18.4s, v19.4s

    sqdmulh v20.4s, v5.4s, v30.4s[2]
    str     q0, [start, #4 * 480]

    sub     v3.4s, v2.4s, v18.4s
    mul     v21.4s, v5.4s, v31.4s[2]
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]
    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v7.4s, v30.4s[3]
    str     q2, [start, #4 * 488]

    sub     v5.4s, v4.4s, v20.4s
    mul     v23.4s, v7.4s, v31.4s[3]
    add     v4.4s, v4.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]
    sub     v22.4s, v22.4s, v23.4s

    str     q3, [start, #4 * 492]
    sub     v7.4s, v6.4s, v22.4s
    add     v6.4s, v6.4s, v22.4s

    str     q4, [start, #4 * 496]
    str     q5, [start, #4 * 500]
    str     q6, [start, #4 * 504]
    str     q7, [start, #4 * 508]


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

    // We need to repeat this sequence 16 times. We iterate over 32 values in
    // one go and 512 / 32 = 16.

    .rept 16

    ld4     {v0.s, v1.s, v2.s, v3.s}[0], [start_l], #16
    ld4     {v0.s, v1.s, v2.s, v3.s}[1], [start_l], #16
    ld4     {v0.s, v1.s, v2.s, v3.s}[2], [start_l], #16
    ld4     {v0.s, v1.s, v2.s, v3.s}[3], [start_l], #16

    ldr     q23, [x3], #16
    ldr     q24, [x4], #16

    ld4     {v8.s, v9.s, v10.s, v11.s}[0], [start_l], #16
    ld4     {v8.s, v9.s, v10.s, v11.s}[1], [start_l], #16
    ld4     {v8.s, v9.s, v10.s, v11.s}[2], [start_l], #16

    sqdmulh v16.4s, v2.4s, v23.4s
    ld4     {v8.s, v9.s, v10.s, v11.s}[3], [start_l], #16

    // Register placement:
    // V0: [0, 4, 8, 12]
    // V1: [1, 5, 9, 13]
    // V2: [2, 6, 10, 14]
    // V3: [3, 7, 11, 15]

    // LAYER 8
    // length = 2, we need 4 roots. We are going to execute:
    // [0, 1, 4, 5]   * [2, 3, 6, 7]     = V0 * V2
    // [8, 9, 12, 13] * [10, 11, 14, 15] = V1 * V3

    ldr     q12, [x3], #16
    mul     v17.4s, v2.4s, v24.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]
    ldr     q13, [x4], #16

    // Register placement:
    // V23 : B[127, 128, 129, 130]
    // V24 : B'[127, 128, 129, 130]

    sub     v16.4s, v16.4s, v17.4s
    sqdmulh v18.4s, v3.4s, v23.4s
    sub     v2.4s, v0.4s, v16.4s
    mul     v19.4s, v3.4s, v24.4s
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v19.4s, v19.4s, v28.4s[3]

    sub     v18.4s, v18.4s, v19.4s
    sqdmulh v20.4s, v10.4s, v12.4s
    sub     v3.4s, v1.4s, v18.4s
    mul     v21.4s, v10.4s, v13.4s
    add     v1.4s, v1.4s, v18.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]

    sub     v20.4s, v20.4s, v21.4s
    sqdmulh v22.4s, v11.4s, v12.4s
    sub     v10.4s, v8.4s, v20.4s
    mul     v23.4s, v11.4s, v13.4s
    add     v8.4s, v8.4s, v20.4s
    sqdmulh v23.4s, v23.4s, v28.4s[3]

    ld2     {v24.s, v25.s}[0], [x5], #8
    ld2     {v24.s, v25.s}[1], [x5], #8
    ld2     {v24.s, v25.s}[2], [x5], #8
    ld2     {v24.s, v25.s}[3], [x5], #8

    sub     v22.4s, v22.4s, v23.4s
    sub     v11.4s, v9.4s, v22.4s
    add     v9.4s, v9.4s, v22.4s

    // LAYER 9
    // length = 1, we need 8 roots. We are going to execute:
    // [0, 2, 4, 6]    * [1, 3, 5, 7]    = V0 * V1
    // [8, 10, 12, 14] * [9, 11, 13, 15] = V2 * V3

    ld2     {v26.s, v27.s}[0], [x6], #8
    ld2     {v26.s, v27.s}[1], [x6], #8
    ld2     {v26.s, v27.s}[2], [x6], #8
    ld2     {v26.s, v27.s}[3], [x6], #8

    ld2     {v12.s, v13.s}[0], [x5], #8
    ld2     {v12.s, v13.s}[1], [x5], #8
    ld2     {v12.s, v13.s}[2], [x5], #8
    ld2     {v12.s, v13.s}[3], [x5], #8

    // Register placement:
    // V23 : B[255, 257, 259, 261]
    // V24 : B[256, 258, 260, 262]
    // V25 : B'[255, 257, 259, 261]
    // V26 : B'[256, 258, 260, 262]

    sqdmulh v18.4s, v3.4s, v25.4s
    mul     v19.4s, v3.4s, v27.4s

    ld2     {v14.s, v15.s}[0], [x6], #8
    ld2     {v14.s, v15.s}[1], [x6], #8
    ld2     {v14.s, v15.s}[2], [x6], #8
    ld2     {v14.s, v15.s}[3], [x6], #8

    sqdmulh v19.4s, v19.4s, v28.4s[3]

    sub     v18.4s, v18.4s, v19.4s
    sqdmulh v16.4s, v1.4s, v24.4s
    sub     v3.4s, v2.4s, v18.4s
    mul     v17.4s, v1.4s, v26.4s
    add     v2.4s, v2.4s, v18.4s
    sqdmulh v17.4s, v17.4s, v28.4s[3]

    sub     v16.4s, v16.4s, v17.4s
    sqdmulh v22.4s, v11.4s, v13.4s
    sub     v1.4s, v0.4s, v16.4s
    mul     v24.4s, v11.4s, v15.4s
    add     v0.4s, v0.4s, v16.4s
    sqdmulh v24.4s, v24.4s, v28.4s[3]

    sub     v22.4s, v22.4s, v24.4s
    sqdmulh v20.4s, v9.4s, v12.4s
    sub     v11.4s, v10.4s, v22.4s
    mul     v21.4s, v9.4s, v14.4s
    add     v10.4s, v10.4s, v22.4s
    sqdmulh v21.4s, v21.4s, v28.4s[3]

    st4     {v0.s, v1.s, v2.s, v3.s}[0], [start_s], #16
    sub     v20.4s, v20.4s, v21.4s
    st4     {v0.s, v1.s, v2.s, v3.s}[1], [start_s], #16
    sub     v9.4s, v8.4s, v20.4s
    st4     {v0.s, v1.s, v2.s, v3.s}[2], [start_s], #16
    add     v8.4s, v8.4s, v20.4s
    st4     {v0.s, v1.s, v2.s, v3.s}[3], [start_s], #16

    st4     {v8.s, v9.s, v10.s, v11.s}[0], [start_s], #16
    st4     {v8.s, v9.s, v10.s, v11.s}[1], [start_s], #16
    st4     {v8.s, v9.s, v10.s, v11.s}[2], [start_s], #16
    st4     {v8.s, v9.s, v10.s, v11.s}[3], [start_s], #16

    .endr

    /* Restore any callee-saved registers (and possibly the procedure call link
     * register) before returning control to our caller. We avoided using such
     * registers, our function epilogue is therefore simply: */

    sub     sp, sp, #64
    ld1     { v8.2s,  v9.2s, v10.2s, v11.2s}, [sp], #32
    ld1     {v12.2s, v13.2s, v14.2s, v15.2s}, [sp], #32
    ret     lr
