/* **************************************************************************
 * Name         : toupper_ymm.s
 * Description  : AVX2-accelerated toupper (32 bytes per cycle).
 * ************************************************************************** */

.section .rodata
.align 32
.Lmask_a: .fill 32, 1, 0x61  # 'a'
.Lmask_z: .fill 32, 1, 0x7B  # 'z' + 1
.Lbit5:   .fill 32, 1, 0x20  # Bit 5 mask

.section .text
.globl toupper_ymm
.type toupper_ymm, @function

toupper_ymm:
    movq    %rdi, %rax
.loop:
    vmovdqu (%rdi), %ymm0       # Load 32 bytes
    
    # 1. Mask for 'a'-'z'
    vmovdqa %ymm0, %ymm1
    vpcmpgtb .Lmask_a(%rip), %ymm1, %ymm1 # YMM1 = (char >= 'a')
    
    vmovdqa %ymm0, %ymm2
    vpcmpgtb .Lmask_z(%rip), %ymm2, %ymm2 # YMM2 = (char >= '{')
    
    vpandn  %ymm2, %ymm1, %ymm1   # YMM1 = Mask of letters 'a'-'z'
    
    # 2. Apply conversion (Subtract 0x20 where mask is 1)
    vpand   .Lbit5(%rip), %ymm1, %ymm1
    vpsubb  %ymm1, %ymm0, %ymm0
    
    vmovdqu %ymm0, (%rdi)       # Store 32 bytes

    # 3. NULL check
    vpxor   %ymm1, %ymm1, %ymm1
    vpcmpeqb %ymm1, %ymm0, %ymm1
    vpmovmskb %ymm1, %edx
    testl   %edx, %edx
    jnz     .done               # If NULL found, we're done
    
    addq    $32, %rdi
    jmp     .loop
.done:
    vzeroupper                  # CRITICAL: Clean up YMM state
    ret

.size toupper_ymm, .-toupper_ymm
.section .note.GNU-stack,"",@progbits
