/*
 ***************************************************************************
 * Name        : fisher_yates_shuffle.s
 * Description : Performs an unbiased, linear-time (O(n)) shuffle of a buffer.
 * Ensures every possible permutation of the deck is equally likely.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = Pointer to the buffer
 * %rsi = Number of elements in the buffer (N)
 * Output      : None (Buffer is shuffled in-place)
 *
 * Strategy    : Pure Leaf Function (Zero Stack). Uses volatile %r9 instead 
 * of %rbx for division to maintain strict ABI compliance.
 * **************************************************************************
 */

.section .text
.globl fisher_yates_shuffle
.type fisher_yates_shuffle, @function

fisher_yates_shuffle:
    testq   %rsi, %rsi              # Handle 0-length case
    jz      .Ldone
    
    movq    %rsi, %r8               # i = N
.Lloop:
    decq    %r8                     # i-- (goes from N-1 down to 1)
    jz      .Ldone

    # Generate random j in range [0, i]
    rdtsc                           # Get entropy (EDX:EAX)
    shrq    $3, %rax                # Apply empirical shift
    xorq    %rdx, %rdx              # Clear upper bits for division
    
    movq    %r8, %r9                # Use caller-saved %r9 instead of %rbx!
    incq    %r9                     # Divisor = i + 1
    divq    %r9                     # RDX = remainder j

    # --- MOV Swap (Performance Optimized) ---
    movb    (%rdi, %r8), %al        # Load buffer[i]
    movb    (%rdi, %rdx), %cl       # Load buffer[j]
    movb    %cl, (%rdi, %r8)        # Store buffer[j] at i
    movb    %al, (%rdi, %rdx)       # Store buffer[i] at j
    
    jmp     .Lloop

.Ldone:
    ret                             # Fast exit

.size fisher_yates_shuffle, .-fisher_yates_shuffle
.section .note.GNU-stack,"",@progbits
