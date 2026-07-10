# ==============================================================================
# File: bin2hexascii_conv.s
# Description: Branchless binary to hex-ASCII conversion.
# Architecture: x86_64 (System V ABI)
# ==============================================================================

.text

# ------------------------------------------------------------------------------
# bin2hexascii_uint4
# In  : %dil (4-bit binary)
# Out : %al (8-bit ASCII)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint4
.type bin2hexascii_uint4, @function
bin2hexascii_uint4:
    .cfi_startproc
    movzbl  %dil, %eax
    andb    $0x0F, %al
    cmpb    $10, %al
    setge   %cl
    movzbl  %cl, %ecx
    imull   $7, %ecx, %ecx
    addb    $'0', %al
    addb    %cl, %al
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bin2hexascii_uint8
# In  : %dil (8-bit binary)
# Out : %ax (16-bit ASCII)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint8
.type bin2hexascii_uint8, @function
bin2hexascii_uint8:
    .cfi_startproc
    movzbl  %dil, %edi
    movl    %edi, %eax
    shrb    $4, %al
    andb    $0x0F, %dil
    
    cmpb    $10, %al
    setge   %cl
    movzbl  %cl, %ecx
    imull   $7, %ecx, %ecx
    addb    $'0', %al
    addb    %cl, %al
    
    cmpb    $10, %dil
    setge   %cl
    movzbl  %cl, %ecx
    imull   $7, %ecx, %ecx
    addb    $'0', %dil
    addb    %cl, %dil
    
    shll    $8, %eax
    movb    %dil, %al
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bin2hexascii_uint16
# In  : %di (16-bit binary)
# Out : %eax (32-bit ASCII)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint16
.type bin2hexascii_uint16, @function
bin2hexascii_uint16:
    .cfi_startproc
    movzwl  %di, %eax
    movl    %eax, %edx
    shll    $8, %edx
    orl     %edx, %eax
    andl    $0x00FF00FF, %eax
    movl    %eax, %edx
    shll    $4, %edx
    orl     %edx, %eax
    andl    $0x0F0F0F0F, %eax
    
    movl    %eax, %edx
    addl    $0x06060606, %edx
    andl    $0x10101010, %edx
    shrl    $4, %edx
    imull   $7, %edx, %edx
    
    addl    $0x30303030, %eax
    addl    %edx, %eax
    bswapl  %eax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bin2hexascii_uint32
# In  : %edi (32-bit binary)
# Out : %rax (64-bit ASCII)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint32
.type bin2hexascii_uint32, @function
bin2hexascii_uint32:
    .cfi_startproc
    movl    %edi, %eax
    movq    %rax, %rdx
    shlq    $16, %rdx
    orq     %rdx, %rax
    movabsq $0x0000FFFF0000FFFF, %rcx
    andq    %rcx, %rax
    movq    %rax, %rdx
    shlq    $8, %rdx
    orq     %rdx, %rax
    movabsq $0x00FF00FF00FF00FF, %rcx
    andq    %rcx, %rax
    movq    %rax, %rdx
    shlq    $4, %rdx
    orq     %rdx, %rax
    movabsq $0x0F0F0F0F0F0F0F0F, %rcx
    andq    %rcx, %rax
    
    movq    %rax, %rdx
    addq    $0x0606060606060606, %rdx
    andq    $0x1010101010101010, %rdx
    shrq    $4, %rdx
    imulq   $7, %rdx, %rdx
    
    addq    $0x3030303030303030, %rax
    addq    %rdx, %rax
    bswapq  %rax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bin2hexascii_uint64
# In  : %rdi (64-bit binary)
# Out : %rax (High 8 chars), %rdx (Low 8 chars)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint64
.type bin2hexascii_uint64, @function
bin2hexascii_uint64:
    .cfi_startproc
    movq    %rdi, %rax
    shrq    $32, %rdi
    
    # Process Low Half (RAX)
    movl    %eax, %ecx
    shll    $16, %ecx
    orl     %ecx, %eax
    andl    $0x00FF00FF, %eax
    movl    %eax, %ecx
    shll    $8, %ecx
    orl     %ecx, %eax
    andl    $0x0F0F0F0F, %eax
    movl    %eax, %edx
    addl    $0x06060606, %edx
    andl    $0x10101010, %edx
    shrl    $4, %edx
    leal    (%rdx, %rdx, 2), %ecx
    leal    (%rdx, %rcx, 2), %edx
    addl    $0x30303030, %eax
    addl    %edx, %eax
    bswapl  %eax
    movl    %eax, %edx 
    
    # Process High Half (RDI)
    movl    %edi, %eax
    movl    %eax, %ecx
    shll    $16, %ecx
    orl     %ecx, %eax
    andl    $0x00FF00FF, %eax
    movl    %eax, %ecx
    shll    $8, %ecx
    orl     %ecx, %eax
    andl    $0x0F0F0F0F, %eax
    movl    %eax, %edx
    addl    $0x06060606, %edx
    andl    $0x10101010, %edx
    shrl    $4, %edx
    leal    (%rdx, %rdx, 2), %ecx
    leal    (%rdx, %rcx, 2), %edx
    addl    $0x30303030, %eax
    addl    %edx, %eax
    bswapl  %eax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bin2hexascii_uint128
# In  : %xmm0 (128-bit binary), %rdi (Output Buffer)
# Out : %rdi (Buffer filled)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint128
.type bin2hexascii_uint128, @function
bin2hexascii_uint128:
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
# bin2hexascii_uint256
# In  : %ymm0 (256-bit binary), %rdi (Output Buffer)
# Out : %rdi (Buffer filled)
# ------------------------------------------------------------------------------
.globl bin2hexascii_uint256
.type bin2hexascii_uint256, @function
bin2hexascii_uint256:
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