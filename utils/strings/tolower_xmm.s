/* **************************************************************************
 * Name         : tolower_xmm.s
 * Description  : SIMD-accelerated tolower (16 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .rodata
.align 16
.Lmask_A: .fill 16, 1, 0x41  # 'A'
.Lmask_Z: .fill 16, 1, 0x5B  # 'Z' + 1
.Lbit5:   .fill 16, 1, 0x20  # Bit 5 mask

.section .text
.globl tolower_xmm
.type tolower_xmm, @function

tolower_xmm:
    movq    %rdi, %rax          # Save pointer for return
.loop:
    movdqu  (%rdi), %xmm0       # Load 16 bytes (unaligned)

    # 1. Identify letters in range ['A', 'Z']
    movdqa  %xmm0, %xmm1        
    pcmpgtb .Lmask_A(%rip), %xmm1 # XMM1 = 1 where char > 0x40 ('A'-1)
    
    movdqa  %xmm0, %xmm2        
    pcmpgtb .Lmask_Z(%rip), %xmm2 # XMM2 = 1 where char >= 0x5B ('Z'+1)
    
    # 2. XMM1 = (char >= 'A') & ~(char > 'Z')
    pandn   %xmm2, %xmm1        # Now XMM1 is 0xFF only for 'A'-'Z'
    
    # 3. Apply mask to set bit 5 (to lowercase)
    # PAND masks the 0x20 bits, PADD adds them to the XMM0 register
    pand    .Lbit5(%rip), %xmm1 
    paddb   %xmm1, %xmm0        
    
    movdqu  %xmm0, (%rdi)       # Store back

    # 4. End-of-string check (Safety)
    # Search for NULL (0x00) in the processed block
    pxor    %xmm1, %xmm1        # Zero register
    pcmpeqb %xmm1, %xmm0        # Compare for NULL
    pmovmskb %xmm0, %edx        # Get mask of matches
    testl   %edx, %edx          # If any byte was NULL, we are done
    jnz     .done
    
    addq    $16, %rdi
    jmp     .loop
.done:
    ret

.size tolower_xmm, .-tolower_xmm
.section .note.GNU-stack,"",@progbits
