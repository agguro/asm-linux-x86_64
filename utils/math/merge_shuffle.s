/* ***************************************************************************
 * Name        : merge_shuffle.s
 * Description : A recursive, divide-and-conquer shuffling algorithm.
 * Simulates randomness by interleaving sub-sections of the buffer.
 *
 * ABI         : System V AMD64 (Linux)
 * Input       : %rdi = Pointer to the buffer
 * %rsi = Number of elements in the buffer (N)
 * Output      : None (Buffer is shuffled in-place)
 *
 * Strategy    : Perfectly stack-aligned recursive calls. Uses callee-saved 
 * registers for cross-call state, and caller-saved registers 
 * for the merge logic. Base pointer frame removed for alignment.
 * **************************************************************************
 */

.section .text
.globl merge_shuffle
.type merge_shuffle, @function

merge_shuffle:
    # --- 1. Base Case: If size (%rsi) <= 1, exit ---
    cmpq    $1, %rsi
    jle     .Ldone                  

    # --- 2. Stack Setup (Perfectly 16-byte aligned!) ---
    # Entry: RSP is misaligned (+8)
    pushq   %r12                    # +16 (Aligned)
    pushq   %r13                    # +8  (Misaligned)
    pushq   %r14                    # +16 (Aligned for 'call'!)

    movq    %rdi, %r12              
    movq    %rsi, %r13              

    # Calculate Midpoint Offset
    movq    %r13, %r14
    shrq    $1, %r14                # r14 = Size / 2

    # --- 3. Recurse Left Half (r12 to r12 + r14) ---
    movq    %r12, %rdi              # Start of buffer
    movq    %r14, %rsi              # Left size
    call    merge_shuffle           # SAFE: RSP is perfectly aligned

    # --- 4. Recurse Right Half (r12 + r14 to r12 + r13) ---
    movq    %r12, %rdi
    addq    %r14, %rdi              # rdi = Start + Midpoint
    movq    %r13, %rsi
    subq    %r14, %rsi              # rsi = Total - Left
    call    merge_shuffle           # SAFE: RSP is perfectly aligned

    # --- 5. Merge Phase (Interleave) ---
    movq    %r13, %rcx              
.Lmerge_loop:
    decq    %rcx                    
    
    rdtsc                           # Get random bit
    testb   $1, %al
    jz      .Lskip_swap

    # Target 1: Current loop index
    leaq    (%r12, %rcx), %r8       # r8 = address of current element
    
    # Target 2: The Midpoint
    leaq    (%r12, %r14), %r9       # r9 = address of midpoint element

    # Perform the Swap using legal VOLATILE registers (%al and %dl)
    movb    (%r8), %al
    movb    (%r9), %dl              # ABI FIXED: No longer clobbering %rbx
    movb    %dl, (%r8)
    movb    %al, (%r9)

.Lskip_swap:
    testq   %rcx, %rcx              
    jnz     .Lmerge_loop

    # --- 6. Cleanup ---
    popq    %r14
    popq    %r13
    popq    %r12
.Ldone:
    ret                             # Fast exit

.size merge_shuffle, .-merge_shuffle
.section .note.GNU-stack,"",@progbits
