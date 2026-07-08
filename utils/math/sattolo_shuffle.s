/*
 ***************************************************************************
 * Name        : sattolo_shuffle.s
 * Description : Generates a single cyclic permutation of a buffer.
 * Guarantees that no element remains in its original starting position.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = Pointer to the buffer
 * %rsi = Number of elements in the buffer (N)
 * Output      : None (Buffer is shuffled in-place)
 *
 * Strategy    : A variation of Fisher-Yates where the random index 'j' is 
 * selected from the range [0, i-1]. By strictly excluding 
 * the current index 'i' from the swap, the algorithm forces 
 * every element to be displaced, creating a full cycle.
 * **************************************************************************
 */

.section .text
.globl sattolo_shuffle
.type sattolo_shuffle, @function

sattolo_shuffle:
    cmpq    $2, %rsi                # Sattolo requires at least 2 elements
    jl      .Ldone
    
    movq    %rsi, %r8               # i = N
.Lloop:
    decq    %r8                     # i-- (Current index)
    jz      .Ldone

    # Generate random j in range [0, i-1]
    rdtsc                           
    shrq    $3, %rax
    xorq    %rdx, %rdx
    
    movq    %r8, %r9                # FIXED: Use volatile %r9 instead of %rbx!
    divq    %r9                     # RDX = remainder j in [0, i-1]

    # --- MOV Swap ---
    movb    (%rdi, %r8), %al
    movb    (%rdi, %rdx), %cl
    movb    %cl, (%rdi, %r8)
    movb    %al, (%rdi, %rdx)
    
    jmp     .Lloop

.Ldone:
    ret                             # Fast exit

.size sattolo_shuffle, .-sattolo_shuffle
.section .note.GNU-stack,"",@progbits
