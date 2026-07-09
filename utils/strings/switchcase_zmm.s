/* **************************************************************************
 * Name         : switchcase_zmm.s
 * Description  : AVX-512 accelerated switchcase (64 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .rodata
.align 64
.L_A:      .fill 64, 1, 0x40  # 'A' - 1
.L_Z:      .fill 64, 1, 0x5B  # 'Z' + 1
.L_a:      .fill 64, 1, 0x60  # 'a' - 1
.L_z:      .fill 64, 1, 0x7B  # 'z' + 1
.Lbit5:    .fill 64, 1, 0x20  # Bit 5 mask

.section .text
.globl switchcase_zmm
.type switchcase_zmm, @function

switchcase_zmm:
    movq    %rdi, %rax
    vmovdqa64 .L_A(%rip), %zmm1
    vmovdqa64 .L_Z(%rip), %zmm2
    vmovdqa64 .L_a(%rip), %zmm3
    vmovdqa64 .L_z(%rip), %zmm4
    vmovdqa64 .L_bit5(%rip), %zmm5

.loop:
    vmovdqu64 (%rdi), %zmm0

    # 1. Mask A-Z
    vpcmpb  $6, %zmm1, %zmm0, %k1  # char > 'A'-1
    vpcmpb  $1, %zmm0, %zmm2, %k2  # char < 'Z'+1
    kandw   %k1, %k2, %k1          # %k1 = A-Z

    # 2. Mask a-z
    vpcmpb  $6, %zmm3, %zmm0, %k3  # char > 'a'-1
    vpcmpb  $1, %zmm0, %zmm4, %k4  # char < 'z'+1
    kandw   %k3, %k4, %k3          # %k3 = a-z

    # 3. Combine masks (k1 = (A-Z) OR (a-z))
    korw    %k1, %k3, %k1

    # 4. XOR bit 5 only where k1 is set
    vpxorq  %zmm5, %zmm0, %zmm0 {%k1}
    
    vmovdqu64 %zmm0, (%rdi)

    # 5. Null check
    vptestmb %zmm0, %zmm0, %k0
    kmovw   %k0, %edx
    testl   %edx, %edx
    jnz     .done

    addq    $64, %rdi
    jmp     .loop

.done:
    vzeroupper
    ret

.size switchcase_zmm, .-switchcase_zmm
.section .note.GNU-stack,"",@progbits
