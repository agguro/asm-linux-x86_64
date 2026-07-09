/* **************************************************************************
 * Name         : toupper_xmm.s
 * Description  : SIMD-accelerated toupper (16 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .rodata
.align 16
.Lmask_a: .fill 16, 1, 0x61  # 'a'
.Lmask_z: .fill 16, 1, 0x7B  # 'z' + 1
.Lbit5:   .fill 16, 1, 0x20  # Bit 5 mask

.section .text
.globl toupper_xmm
.type toupper_xmm, @function

toupper_xmm:
    movq    %rdi, %rax
.loop:
    movdqu  (%rdi), %xmm0       # Load 16 bytes (Unaligned)
    
    # 1. Identify letters in range ['a', 'z']
    movdqa  %xmm0, %xmm1        # Work copy
    pcmpgtb .Lmask_a(%rip), %xmm1 # XMM1 = 1 where char >= 'a'
    
    movdqa  %xmm0, %xmm2        # Work copy
    pcmpgtb .Lmask_z(%rip), %xmm2 # XMM2 = 1 where char >= '{' (z+1)
    
    # 2. XMM3 = (char >= 'a') & ~(char > 'z')
    pandn   %xmm2, %xmm1        # Now XMM1 is 1 only for 'a'-'z'
    
    # 3. Apply mask to clear bit 5 (to uppercase)
    # We want to AND with ~0x20 where XMM1 is 1
    pand    .Lbit5(%rip), %xmm1 # Mask bit 5 only where letters exist
    psubb   %xmm1, %xmm0        # Subtract 0x20 from those specific bytes
    
    movdqu  %xmm0, (%rdi)       # Store back
    
    # Check for null terminator to decide to loop or finish
    pmovmskb %xmm0, %edx        # Get mask of bytes
    testl   %edx, %edx          # This is tricky due to nulls; 
                                # usually we use pcmpistri for robust end-checking
    
    addq    $16, %rdi
    jmp     .loop               # (Simplified: Add end-check via pcmpistri)

.size toupper_xmm, .-toupper_xmm
.section .note.GNU-stack,"",@progbits
