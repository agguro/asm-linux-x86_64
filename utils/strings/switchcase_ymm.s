/* **************************************************************************
 * Name         : switchcase_ymm.s
 * Description  : AVX2-accelerated switchcase (32 bytes per cycle).
 * ************************************************************************** */

.section .rodata
.align 32
.L_A:      .fill 32, 1, 0x40  # 'A' - 1
.L_Z:      .fill 32, 1, 0x5B  # 'Z' + 1
.L_a:      .fill 32, 1, 0x60  # 'a' - 1
.L_z:      .fill 32, 1, 0x7B  # 'z' + 1
.Lbit5:    .fill 32, 1, 0x20  # Bit 5 mask

.section .text
.globl switchcase_ymm
.type switchcase_ymm, @function

switchcase_ymm:
    movq    %rdi, %rax
    vmovdqa .L_A(%rip), %ymm1
    vmovdqa .L_Z(%rip), %ymm2
    vmovdqa .L_a(%rip), %ymm3
    vmovdqa .L_z(%rip), %ymm4
    vmovdqa .Lbit5(%rip), %ymm5

.loop:
    vmovdqu (%rdi), %ymm0

    # 1. Mask A-Z: (char > 'A'-1) AND (char < 'Z'+1)
    vmovdqa %ymm0, %ymm6
    vpcmpgtb %ymm1, %ymm6, %ymm6   # YMM6 = char > 'A'-1
    vmovdqa %ymm0, %ymm7
    vpcmpgtb %ymm2, %ymm7, %ymm7   # YMM7 = char > 'Z'
    vpandn  %ymm7, %ymm6, %ymm6    # YMM6 = Mask A-Z

    # 2. Mask a-z: (char > 'a'-1) AND (char < 'z'+1)
    vmovdqa %ymm0, %ymm7
    vpcmpgtb %ymm3, %ymm7, %ymm7   # YMM7 = char > 'a'-1
    vmovdqa %ymm0, %ymm8
    vpcmpgtb %ymm4, %ymm8, %ymm8   # YMM8 = char > 'z'
    vpandn  %ymm8, %ymm7, %ymm7    # YMM7 = Mask a-z

    # 3. Combine ranges and prepare XOR mask
    vpor    %ymm6, %ymm7, %ymm6    # YMM6 = Any alpha char
    vpand   %ymm5, %ymm6, %ymm6    # YMM6 = Bit 5 mask only for letters

    # 4. Flip bit 5
    vpxor   %ymm6, %ymm0, %ymm0
    
    vmovdqu %ymm0, (%rdi)

    # 5. NULL check
    vpxor   %ymm1, %ymm1, %ymm1    # Reuse YMM1 to clear
    vpcmpeqb %ymm1, %ymm0, %ymm1
    vpmovmskb %ymm1, %edx
    testl   %edx, %edx
    jnz     .done

    addq    $32, %rdi
    jmp     .loop

.done:
    vzeroupper
    ret

.size switchcase_ymm, .-switchcase_ymm
.section .note.GNU-stack,"",@progbits
