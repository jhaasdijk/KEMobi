/* Switch to the text segment - this contains the program code */

.text

/* Provide function declarations */

.global forward_layer_1
.type forward_layer_1, %function

/* Provide symbols that are defined elsewhere */

.extern multiply_reduce

/* Declare constant values */

.equ ZETA, 6672794
.equ LENGTH, 256

// void forward_layer_1(int32_t *coefficients)
// {
//     int32_t temp;
//
//     for (size_t idx = 0; idx < LENGTH; idx++)
//     {
//         temp = multiply_reduce(ZETA, coefficients[idx + LENGTH]);
//         coefficients[idx + LENGTH] = coefficients[idx] - temp;
//         coefficients[idx] = coefficients[idx] + temp;
//     }
// }
//
// This function executes 256 subtractions and 256 additions. The integer
// coefficients are stored as int32_t which means that we can operate on 4
// values simultaneously using the 128 bit SIMD registers. We should therefore
// be able to bring this down to 64 subtractions and 64 additions.
//
// (We are ignoring the cost of the call to multiply_reduce as this is not part
// of the local function. We are also ignoring the load/store overhead)
//
// ASIMD arith instructions (ADD / SUB)
// Execution Latency    : 3
// Execution Throughput : 2
//
// This means that *). Operations dependent on ASIMD arith instructions need to
// wait at least 3 cycles before being able to use the result, and that *). The
// maximum number of ASIMD arith instructions that can be processed per cycle is
// 2.
//
// This means that the absolute (unrealistic) lower bound of what we can achieve
// within the forward_layer_1 function is 64 cycles (128 ASIMD arith
// instructions / 2).

forward_layer_1:

    // w1 is our 23 bit constant multiplicand. This is stored in the
    // parameter/result register r1. We can do this because multiply_reduce
    // takes 2 arguments (the multiplicands) but will only return 1 result. Note
    // that the move instruction is only able to insert 16 bit immediate values
    // into its destination. We therefore need to split it up into a move of the
    // lower 16 bits and a move (with keep) of the upper 7 bits.
    //
    // w9 is going to be our 'size_t idx' loop counter. This is stored in the
    // temporary register r9.
    //
    // Since both values are smaller than 32 bits we can use the 32 bit general
    // purpose registers.

    // // Move the value of ZETA into register r1
    // mov w1, #0xd19a
    // movk w1, #0x65, lsl #16

    // // Move the value of LENGTH into register r9
    // mov w9, LENGTH

    // b multiply_reduce

    // ret lr

    stp	x29, x30, [sp, #-48]!
    mov	x29, sp
    stp	x19, x20, [sp, #16]
    mov	x19, x0
    add	x20, x0, #0x400
    str	x21, [sp, #32]

    // Move the value of ZETA into register r21
    mov	w21, #0xd19a
    movk w21, #0x65, lsl #16

    loop:
    ldr	w1, [x19, #1024]
    mov	w0, w21

    bl multiply_reduce

    ldr	w1, [x19]
    sub	w2, w1, w0
    add	w1, w1, w0
    str	w2, [x19, #1024]
    str	w1, [x19], #4
    cmp	x20, x19

    b.ne loop

    ldp	x19, x20, [sp, #16]
    ldr	x21, [sp, #32]
    ldp	x29, x30, [sp], #48
    ret
