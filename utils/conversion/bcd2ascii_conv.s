# ==============================================================================
# File: bcd2ascii_conv.s
# Description: Packed BCD to ASCII conversion routines.
# Architecture: x86_64 (System V ABI)
# Strategy: Zero-stack, branchless parallel nibble processing.
# ==============================================================================


.section .rodata
.align 32
.Lmask_0F:      .fill 32, 1, 0x0F
.Lascii_0:      .fill 32, 1, 0x30
.Lalpha_adj:    .fill 32, 1, 7

.text

# ------------------------------------------------------------------------------
# bcd2ascii_uint4
# In  : %dil (4-bit BCD nibble)
# Out : %al (ASCII char)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint4
.type bcd2ascii_uint4, @function
bcd2ascii_uint4:
    movzbl  %dil, %eax
    andb    $0x0F, %al
    orb     $0x30, %al
    ret

# ------------------------------------------------------------------------------
# bcd2ascii_uint8
# In  : %dil (8-bit BCD byte)
# Out : %ax (Two ASCII chars)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint8
.type bcd2ascii_uint8, @function
bcd2ascii_uint8:
    movzbl  %dil, %eax
    movl    %eax, %edx
    shrb    $4, %dl     # High nibble
    andb    $0x0F, %al  # Low nibble
    orb     $0x30, %dl
    orb     $0x30, %al
    shll    $8, %edx
    orl     %edx, %eax
    ret

# ------------------------------------------------------------------------------
# bcd2ascii_uint16
# In  : %di (16-bit packed BCD)
# Out : %eax (Four ASCII chars)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint16
.type bcd2ascii_uint16, @function
bcd2ascii_uint16:
    movzwl  %di, %eax
    orl     $0x33330000, %eax
    roll    $4, %eax
    rorw    $4, %ax
    roll    $8, %eax
    rorw    $4, %ax
    rorb    $4, %al
    ret

# ------------------------------------------------------------------------------
# bcd2ascii_uint32
# In  : %edi (32-bit packed BCD)
# Out : %rax (Eight ASCII chars)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint32
.type bcd2ascii_uint32, @function
bcd2ascii_uint32:
    movl    %edi, %eax
    movl    %eax, %edx
    shll    $16, %edx
    orl     %edx, %eax
    andl    $0x00FF00FF, %eax
    
    movl    %eax, %edx
    shll    $8, %edx
    orl     %edx, %eax
    andl    $0x0F0F0F0F, %eax
    
    movl    %eax, %edx
    shll    $4, %edx
    orl     %edx, %eax
    andl    $0x0F0F0F0F, %eax
    
    addl    $0x30303030, %eax
    ret

# ------------------------------------------------------------------------------
# bcd2ascii_uint64
# In  : %rdi (64-bit packed BCD)
# Out : %rdx:%rax (16 ASCII chars)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint64
.type bcd2ascii_uint64, @function
bcd2ascii_uint64:
    movq    %rdi, %rax
    shrq    $32, %rdi
    
    # Process Low Half (RAX)
    movl    %eax, %r8d
    shll    $16, %r8d
    orl     %r8d, %eax
    andl    $0x00FF00FF, %eax
    movl    %eax, %r8d
    shll    $8, %r8d
    orl     %r8d, %eax
    andl    $0x0F0F0F0F, %eax
    movl    %eax, %r8d
    shll    $4, %r8d
    orl     %r8d, %eax
    andl    $0x0F0F0F0F, %eax
    addl    $0x30303030, %eax
    movl    %eax, %edx
    
    # Process High Half (RDI)
    movl    %edi, %eax
    movl    %eax, %r8d
    shll    $16, %r8d
    orl     %r8d, %eax
    andl    $0x00FF00FF, %eax
    movl    %eax, %r8d
    shll    $8, %r8d
    orl     %r8d, %eax
    andl    $0x0F0F0F0F, %eax
    movl    %eax, %r8d
    shll    $4, %r8d
    orl     %r8d, %eax
    andl    $0x0F0F0F0F, %eax
    addl    $0x30303030, %eax
    ret

# ------------------------------------------------------------------------------
# bcd2ascii_uint128
# In  : %xmm0 (128-bit BCD), %rdi (Output Buffer)
# Out : %rdi (Buffer filled)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint128
.type bcd2ascii_uint128, @function
bcd2ascii_uint128:
    .cfi_startproc
    vpand   .Lmask_0F(%rip), %xmm0, %xmm2
    vpsrlw  $4, %xmm0, %xmm1
    vpand   .Lmask_0F(%rip), %xmm1, %xmm1
    vpaddb  .Lascii_0(%rip), %xmm2, %xmm2
    vpaddb  .Lascii_0(%rip), %xmm1, %xmm1
    vpcmpgtb .Lascii_0(%rip), %xmm2, %xmm3
    vpand   .Lalpha_adj(%rip), %xmm3, %xmm3
    vpaddb  %xmm3, %xmm2, %xmm2
    vpcmpgtb .Lascii_0(%rip), %xmm1, %xmm3
    vpand   .Lalpha_adj(%rip), %xmm3, %xmm3
    vpaddb  %xmm3, %xmm1, %xmm1
    vmovdqu %xmm1, (%rdi)
    vmovdqu %xmm2, 16(%rdi)
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2ascii_uint256
# In  : %ymm0 (256-bit BCD), %rdi (Output Buffer)
# Out : %rdi (Buffer filled)
# ------------------------------------------------------------------------------
.globl bcd2ascii_uint256
.type bcd2ascii_uint256, @function
bcd2ascii_uint256:
    .cfi_startproc
    vpand   .Lmask_0F(%rip), %ymm0, %ymm2
    vpsrlw  $4, %ymm0, %ymm1
    vpand   .Lmask_0F(%rip), %ymm1, %ymm1
    vpaddb  .Lascii_0(%rip), %ymm2, %ymm2
    vpaddb  .Lascii_0(%rip), %ymm1, %ymm1
    vpcmpgtb .Lascii_0(%rip), %ymm2, %ymm3
    vpand   .Lalpha_adj(%rip), %ymm3, %ymm3
    vpaddb  %ymm3, %ymm2, %ymm2
    vpcmpgtb .Lascii_0(%rip), %ymm1, %ymm3
    vpand   .Lalpha_adj(%rip), %ymm3, %ymm3
    vpaddb  %ymm3, %ymm1, %ymm1
    vmovdqu %ymm1, (%rdi)
    vmovdqu %ymm2, 32(%rdi)
    vzeroupper
    ret
    .cfi_endproc

.section .note.GNU-stack,"",@progbits
