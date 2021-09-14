/* Switch to the text segment - this contains the program code */

.text

.global __asm_reduce_multiply
.global __asm_reduce_coefficients

.type __asm_reduce_multiply, %function
.type __asm_reduce_coefficients, %function

__asm_reduce_multiply:

    /* Alias registers for a specific purpose (and readability) */

    factor  .req w13
    start   .req x14    // Store pointer to the first integer coefficient
    M       .req w15    // Store the constant value M = 6984193

    /* Initialize constant values */

    // 512^-1 mod 6984193     = 6970552
    // B  = 6970552 · R mod M = 4194304
    // B' = B · M' mod R      = 4194304
    // Move wide with zero, 4194304 = 0x400000

    movz    factor, #0x40, lsl #16
    mov     v28.4s[2], factor

    mov     M, #0x9201
    movk    M, #0x6a, lsl #16
    mov     v28.4s[3], M

    /* Multiplication with the accumulated factor -N */

    mov     start, x0

    .rept 16

    ldr     q0, [start, #4 * 0]
    ldr     q1, [start, #4 * 4]
    ldr     q2, [start, #4 * 8]
    ldr     q3, [start, #4 * 12]
    ldr     q4, [start, #4 * 16]
    ldr     q5, [start, #4 * 20]
    ldr     q6, [start, #4 * 24]
    ldr     q7, [start, #4 * 28]

    sqdmulh v30.4s, v0.4s, v28.4s[2]
    mul     v31.4s, v0.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v0.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v1.4s, v28.4s[2]
    mul     v31.4s, v1.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v1.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v2.4s, v28.4s[2]
    mul     v31.4s, v2.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v2.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v3.4s, v28.4s[2]
    mul     v31.4s, v3.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v3.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v4.4s, v28.4s[2]
    mul     v31.4s, v4.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v4.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v5.4s, v28.4s[2]
    mul     v31.4s, v5.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v5.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v6.4s, v28.4s[2]
    mul     v31.4s, v6.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v6.4s, v30.4s, v31.4s

    sqdmulh v30.4s, v7.4s, v28.4s[2]
    mul     v31.4s, v7.4s, v28.4s[2]
    sqdmulh v31.4s, v31.4s, v28.4s[3]
    sub     v7.4s, v30.4s, v31.4s

    str     q0, [start, #4 * 0]
    str     q1, [start, #4 * 4]
    str     q2, [start, #4 * 8]
    str     q3, [start, #4 * 12]
    str     q4, [start, #4 * 16]
    str     q5, [start, #4 * 20]
    str     q6, [start, #4 * 24]
    str     q7, [start, #4 * 28]

    add     start, start, #4 * 32

    .endr

    ret     lr

__asm_reduce_coefficients:

    /* Alias registers for a specific purpose (and readability) */

    start   .req x13	// Store pointer to the first integer coefficient
    M       .req w14    // Store the constant value M = 6984193
    M_inv   .req w15    // Store the constant value M_inv = 20150859

    /* Initialize constant values */

    mov     M, #0x9201
    movk    M, #0x6a, lsl #16
    dup     v30.4s, M

    mov	    M_inv, #0x7a4b
    movk    M_inv, #0x133, lsl #16
    mov     v31.4s[3], M_inv

    /* Loop over all coefficients */

    mov     start, x0

    .rept 128

    ldr	    q0, [start]

    smull   v27.2d, v0.2s, v31.2s[3]
    sshr    v28.4s, v0.4s, #31
    smull2  v29.2d, v0.4s, v31.4s[3]
    uzp2    v27.4s, v27.4s, v29.4s
    sshr    v27.4s, v27.4s, #15
    sub	    v27.4s, v27.4s, v28.4s
    mls	    v0.4s, v27.4s, v30.4s
    cmge    v27.4s, v0.4s, #0
    add	    v28.4s, v0.4s, v30.4s
    bif	    v0.16b, v28.16b, v27.16b

    str	    q0, [start]
    add     start, start, #16

    .endr

    ret     lr
