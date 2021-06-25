/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global __asm_reduce_coefficients
.type __asm_reduce_coefficients, %function

__asm_reduce_coefficients:

    /* Alias registers for a specific purpose (and readability) */

    start   .req x13	// Store pointer to the first integer coefficient
    M       .req w14    // Store the constant value M = 6984193
    M_inv   .req w15    // Store the constant value M_inv = 20150859

    /* Initialize constant values */

    mov     M, #0x9201              // 6984193 (= M)
    movk    M, #0x6a, lsl #16
    dup     v30.4s, M               // Move M into all 4 elements

    mov	    M_inv, #0x7a4b
    movk    M_inv, #0x133, lsl #16  // 20150859 (= M_inv)
    mov     v31.4s[3], M_inv

    /* Loop over all coefficients */

    mov     start, x0               // Store *coefficients[0]

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

    ret lr
