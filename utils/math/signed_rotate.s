/* **************************************************************************
 * Name         : signed_rotate.s
 * Assemble     : as --64 signed_rotate.s -o signed_rotate.o
 * Description  : Specialized circular rotation for arbitrary bit-windows.
 *
 * API          : srol(value, len, count), sror(value, len, count)
 * Input        : %rdi = Value, %rsi = Bitlength (L), %rdx = Count (N)
 * Output       : %rax = Rotated Result
 *
 * Strategy:
 * Stackless Leaf Function. Replaces O(N) bit-by-bit loops with O(1) 
 * mathematical block-shifting. Eliminates callee-saved register usage
 * and safely handles 0-count edge cases.
 * ************************************************************************** */

.section .text

.globl srol
.type srol, @function
srol:
    xorl    %r10d, %r10d            # Direction 0 = Left
    jmp     _rotate_sig_backend

.globl sror
.type sror, @function
sror:
    movl    $1, %r10d               # Direction 1 = Right
    jmp     _rotate_sig_backend

.type _rotate_sig_backend, @function
_rotate_sig_backend:
    movq    %rdi, %rax              # Default return = original value
    
    # 1. Window Width Check (W = L - 1)
    cmpq    $2, %rsi
    jl      .Ldone                  # If length < 2, return original value
    
    movq    %rsi, %r8
    decq    %r8                     # %r8 = W (Data bits excluding sign)

    # 2. Normalize Count (N = Count % W)
    movq    %rax, %r11              # Safely backup original value
    movq    %rdx, %rax              # Move Count to RAX for division
    xorq    %rdx, %rdx              
    divq    %r8                     # RDX = N (Normalized Count)
    movq    %rdx, %r9               # %r9 = N
    movq    %r11, %rax              # Restore original value to RAX
    
    testq   %r9, %r9
    jz      .Ldone                  # If N == 0, return original value

    # 3. Create Isolation Masks
    movq    $1, %rdx
    movb    %r8b, %cl               # %cl = W
    shlq    %cl, %rdx               # %rdx = 1 << W (Sign Mask)
    
    movq    %rdx, %r11
    decq    %r11                    # %r11 = Body Mask ((1 << W) - 1)

    # 4. Isolate Components
    movq    %rax, %rsi              # Use %rsi for the Sign Bit
    andq    %rdx, %rsi              # %rsi = Fixed Sign Bit
    andq    %r11, %rax              # %rax = The Body (bits to rotate)

    # 5. O(1) Block Shift Prep
    subq    %r9, %r8                # %r8 = (W - N)
    
    testl   %r10d, %r10d
    jnz     .Lright_shift

.Lleft_shift:
    movq    %rax, %r10              # Copy body
    movb    %r9b, %cl               # %cl = N
    shlq    %cl, %rax               # (Body << N)
    andq    %r11, %rax              # Mask to window size
    
    movb    %r8b, %cl               # %cl = (W - N)
    shrq    %cl, %r10               # (Body >> (W - N))
    
    orq     %r10, %rax              # Combine wrapped bits
    orq     %rsi, %rax              # Attach Sign Bit
    ret

.Lright_shift:
    movq    %rax, %r10              # Copy body
    movb    %r9b, %cl               # %cl = N
    shrq    %cl, %rax               # (Body >> N)
    
    movb    %r8b, %cl               # %cl = (W - N)
    shlq    %cl, %r10               # (Body << (W - N))
    andq    %r11, %r10              # Mask to window size
    
    orq     %r10, %rax              # Combine wrapped bits
    orq     %rsi, %rax              # Attach Sign Bit

.Ldone:
    ret

.size srol, .-srol
.size sror, .-sror
.section .note.GNU-stack,"",@progbits
