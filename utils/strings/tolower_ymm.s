/* **************************************************************************
 * Name         : tolower_ymm.s
 * Description  : AVX2-accelerated tolower (32 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .rodata
.align 32
.L_A:      .fill 32, 1, 0x40  # 'A' - 1
.L_Z:      .fill 32, 1, 0x5B  # 'Z' + 1
.Lbit5:    .fill 32, 1, 0x20  # Bit 5 mask

.section .text
.globl tolower_ymm
.type tolower_ymm, @function

tolower_ymm:
    movq    %rdi, %rax
    vmovdqa .L_A(%rip), %ymm1   # Load constants
    vmovdqa .L_Z(%rip), %ymm2
    vmovdqa .Lbit5(%rip), %ymm3

.loop:
    vmovdqu (%rdi), %ymm0       # Load 32 bytes

    # 1. Mask for 'A' <= char <= 'Z'
    # Comparison: (char > 0x40) AND (char < 0x5B)
    vmovdqa %ymm0, %ymm4
    vpcmpgtb %ymm1, %ymm4, %ymm4 # YMM4 = char > 'A'-1
    
    vmovdqa %ymm0, %ymm5
    vpcmpgtb %ymm2, %ymm5, %ymm5 # YMM5 = char > 'Z'
    
    vpandn  %ymm5, %ymm4, %ymm4   # YMM4 = Mask of letters 'A'-'Z'
    
    # 2. Apply conversion (Add 0x20 where mask is 1)
    vpand   %ymm3, %ymm4, %ymm4   # Isolate bit 5 for letters only
    vpaddb  %ymm4, %ymm0, %ymm0
    
    vmovdqu %ymm0, (%rdi)       # Store back

    # 3. NULL check
    vpxor   %ymm1, %ymm1, %ymm1 # Clear YMM1
    vpcmpeqb %ymm1, %ymm0, %ymm1
    vpmovmskb %ymm1, %edx
    testl   %edx, %edx          # Check if any NULL byte was found
    jnz     .done
    
    addq    $32, %rdi
    jmp     .loop
.done:
    vzeroupper
    ret

.size tolower_ymm, .-tolower_ymm
.section .note.GNU-stack,"",@progbits
