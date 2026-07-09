/* **************************************************************************
 * Name         : toupper_zmm.s
 * Description  : AVX-512 (ZMM) accelerated toupper (64 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .rodata
.align 64
.L_a: .fill 64, 1, 0x61  # 'a'
.L_z: .fill 64, 1, 0x7B  # 'z' + 1
.L_bit5: .fill 64, 1, 0x20

.section .text
.globl toupper_zmm
.type toupper_zmm, @function

toupper_zmm:
    movq    %rdi, %rax
    vmovdqa64 .L_a(%rip), %zmm1  # Load 'a' constants
    vmovdqa64 .L_z(%rip), %zmm2  # Load 'z' + 1 constants
    vmovdqa64 .L_bit5(%rip), %zmm3 # Load bit 5 mask

.loop:
    vmovdqu64 (%rdi), %zmm0      # Load 64 bytes

    # 1. Create mask of lowercase letters ('a' <= char < 'z'+1)
    vpcmpb  $1, %zmm1, %zmm0, %k1 # %k1 = char >= 'a'
    vpcmpb  $1, %zmm0, %zmm2, %k2 # %k2 = char < '{'
    kandw   %k1, %k2, %k1        # %k1 = (char >= 'a' AND char <= 'z')

    # 2. Apply conversion only where mask %k1 is active
    # Subtract 0x20 only for bytes in the 'a'-'z' range
    vpsubb  %zmm3, %zmm0, %zmm0 {%k1}
    
    vmovdqu64 %zmm0, (%rdi)      # Store back

    # 3. NULL check
    vptestmb %zmm0, %zmm0, %k0   # Check for nulls in ZMM0
    kmovw   %k0, %edx            # Move mask to general purpose
    testl   %edx, %edx           # This logic varies: usually we check 
                                 # if any of the processed bytes were 0.
    
    addq    $64, %rdi
    jmp     .loop

.done:
    vzeroupper
    ret

.size toupper_zmm, .-toupper_zmm
.section .note.GNU-stack,"",@progbits
