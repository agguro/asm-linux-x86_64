/*
 **************************************************************************
 * Name        : nlz.s
 * Description : Count leading zeros (64-bit). 
 * Uses the Branch-Free "Bit-Fill" method for performance.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = 64-bit value to analyze
 * Output      : %rax = count of leading zeros (0-64)
 * **************************************************************************
 */

.section .text
   
.globl nlz
.type nlz, @function
nlz:
    movq    %rdi, %rax
    testq   %rax, %rax
    jnz     .Lstart_nlz
    movq    $64, %rax
    ret

.Lstart_nlz:
    # Bit-Fill: Propagate the highest '1' bit to the right
    movq    %rax, %rdx
    shrq    $1, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $2, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $4, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $8, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $16, %rdx
    orq     %rdx, %rax
    movq    %rax, %rdx
    shrq    $32, %rdx
    orq     %rdx, %rax

    # RAX is now a contiguous block of 1s representing the magnitude.
    # By inverting it, the leading zeros become 1s.
    notq    %rax              
    popcntq %rax, %rax        # Count the inverted 1s to get the leading zeros
    ret

.size nlz, .-nlz 
.section .note.GNU-stack,"",@progbits
