.text

.global polyAddAsm
.type polyAddAsm, %function

.equ PRIMEP, 6 // p, determines the degree of the polynomials A, B and P

// The volatile attribute instructs the compiler not to optimize the
// assembler. The variables are stored as follows. A:X0, B:X1, P:X2.
// The integer coefficients are stored as uint32_t which means we can
// operate on 4 values simultaneously.

polyAddAsm:
    mov x3, PRIMEP

    loop4:
    ldr q0, [x0], #16
    ldr q1, [x1], #16
    add v0.4s, v0.4s, v1.4s
    str q0, [x2], #16

    sub x3, x3, #4      // decrement counter
    cmp x3, #3

    b.hi loop4          // if x3 > 3  : loop4
    b.ls loop1          // if x3 <= 3 : loop1

    loop1:
    ldr w4, [x0], #4
    ldr w5, [x1], #4
    add w4, w4, w5
    str w4, [x2], #4

    sub x3, x3, #1
    cmp x3, #0

    b.hi loop1

    ret lr
