/* **************************************************************************
 * Name         : tolower_zmm.s
 * Description  : AVX-512 accelerated tolower (64 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .rodata
.align 64
.L_A:      .fill 64, 1, 0x40  # 'A' - 1
.L_Z:      .fill 64, 1, 0x5B  # 'Z' + 1
.Lbit5:    .fill 64, 1, 0x20  # Bit 5 mask

.section .text
.globl tolower_zmm
.type tolower_zmm, @function

tolower_zmm:
    movq    %rdi, %rax
    vmovdqa64 .L_A(%rip), %zmm1  # Compare constants
    vmovdqa64 .L_Z(%rip), %zmm2
    vmovdqa64 .L_bit5(%rip), %zmm3

.loop:
    vmovdqu64 (%rdi), %zmm0      # Load 64 bytes

    # 1. Create mask for 'A' <= char <= 'Z'
    vpcmpb  $6, %zmm1, %zmm0, %k1 # %k1 = char > 'A'-1 (Greater)
    vpcmpb  $1, %zmm0, %zmm2, %k2 # %k2 = char < 'Z'+1 (Less)
    kandw   %k1, %k2, %k1        # %k1 = (char >= 'A' AND char <= 'Z')

    # 2. Add 0x20 to uppercase letters only (masked)
    vpaddb  %zmm3, %zmm0, %zmm0 {%k1}
    
    vmovdqu64 %zmm0, (%rdi)      # Store 64 bytes

    # 3. Check for NULLs to stop (using 64-bit mask)
    vptestmb %zmm0, %zmm0, %k0   # k0 = bytes == 0
    kmovq   %k0, %rdx            # Move mask to GPR
    testq   %rdx, %rdx           # If k0 is non-zero, we hit a NULL
    jnz     .done
    
    addq    $64, %rdi
    jmp     .loop

.done:
    vzeroupper
    ret

.size tolower_zmm, .-tolower_zmm
.section .note.GNU-stack,"",@progbits
