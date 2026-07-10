# ==============================================================================
# File: bcd2bin_conv.s
# Description: Optimized BCD to Binary conversion (uint4 - uint64).
# Strategy: Inlined Horner's Method with shift-and-add (LEA) multiplication.
# ==============================================================================

.section .rodata
.align 32
.Lmask_0F:      .fill 32, 1, 0x0F
.Lpowers:       .word 1, 10, 100, 1000, 10000, 10000, 10000, 10000
                .word 1, 10, 100, 1000, 10000, 10000, 10000, 10000
.Lpowers_lo:    .word 1, 10, 100, 1000, 10000, 10000, 10000, 10000
                .word 1, 10, 100, 1000, 10000, 10000, 10000, 10000

.text

# ------------------------------------------------------------------------------
# bcd2bin_uint4
# In  : %edi (4-bit BCD)
# Out : %eax (Binary)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint4
.type bcd2bin_uint4, @function
bcd2bin_uint4:
    .cfi_startproc
    movl    %edi, %eax
    andl    $0x0F, %eax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2bin_uint8
# In  : %dil (8-bit BCD)
# Out : %eax (Binary)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint8
.type bcd2bin_uint8, @function
bcd2bin_uint8:
    .cfi_startproc
    movzbl  %dil, %eax
    movl    %eax, %edx
    andl    $0x0F, %eax
    shrl    $4, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    addl    %edx, %eax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2bin_uint16
# In  : %di (16-bit BCD)
# Out : %eax (Binary)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint16
.type bcd2bin_uint16, @function
bcd2bin_uint16:
    .cfi_startproc
    movzwl  %di, %edi
    movl    %edi, %eax
    shrl    $8, %eax
    movl    %eax, %edx
    andl    $0x0F, %eax
    shrl    $4, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    addl    %edx, %eax
    leal    (%rax, %rax, 4), %edx
    shll    $1, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    movl    %edi, %eax
    andl    $0x0F, %eax
    movl    %edi, %ecx
    shrl    $4, %ecx
    andl    $0x0F, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %eax
    addl    %edx, %eax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2bin_uint32
# In  : %edi (32-bit BCD)
# Out : %eax (Binary)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint32
.type bcd2bin_uint32, @function
bcd2bin_uint32:
    .cfi_startproc
    movl    %edi, %r8d
    shrl    $16, %edi
    movzwl  %di, %edi
    movl    %edi, %eax
    shrl    $8, %eax
    movl    %eax, %edx
    andl    $0x0F, %eax
    shrl    $4, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    addl    %edx, %eax
    leal    (%rax, %rax, 4), %edx
    shll    $1, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    movl    %edi, %eax
    andl    $0x0F, %eax
    movl    %edi, %ecx
    shrl    $4, %ecx
    andl    $0x0F, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %eax
    addl    %edx, %eax
    leal    (%rax, %rax, 4), %r9d
    shll    $1, %r9d
    leal    (%r9d, %r9d, 4), %r9d
    shll    $1, %r9d
    leal    (%r9d, %r9d, 4), %r9d
    shll    $1, %r9d
    leal    (%r9d, %r9d, 4), %r9d
    shll    $1, %r9d
    movl    %r8d, %eax
    andl    $0xFFFF, %eax
    movl    %eax, %edi
    shrl    $8, %eax
    movl    %eax, %edx
    andl    $0x0F, %eax
    shrl    $4, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    addl    %edx, %eax
    leal    (%rax, %rax, 4), %edx
    shll    $1, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    movl    %edi, %eax
    andl    $0x0F, %eax
    movl    %edi, %ecx
    shrl    $4, %ecx
    andl    $0x0F, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %eax
    addl    %edx, %eax
    addl    %r9d, %eax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2bin_uint64
# In  : %rdi (64-bit BCD)
# Out : %rax (Binary)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint64
.type bcd2bin_uint64, @function
bcd2bin_uint64:
    .cfi_startproc
    movq    %rdi, %r8
    shrq    $32, %rdi
    movl    %edi, %eax
    shrl    $16, %eax
    movzwl  %ax, %eax
    movl    %eax, %edx
    shrl    $8, %edx
    movl    %edx, %ecx
    andl    $0x0F, %edx
    shrl    $4, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    movzwl  %ax, %eax
    movl    %eax, %ecx
    shrl    $4, %ecx
    andl    $0x0F, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %edx
    andl    $0x0F, %eax
    addl    %eax, %edx
    movl    %edx, %eax
    movq    $100000000, %rcx
    imulq   %rcx, %rax
    movq    %rax, %r9
    movl    %r8d, %edi
    movl    %edi, %eax
    shrl    $16, %eax
    movzwl  %ax, %eax
    movl    %eax, %edx
    shrl    $8, %edx
    movl    %edx, %ecx
    andl    $0x0F, %edx
    shrl    $4, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    leal    (%rdx, %rdx, 4), %edx
    shll    $1, %edx
    movzwl  %di, %eax
    movl    %eax, %ecx
    shrl    $4, %ecx
    andl    $0x0F, %ecx
    leal    (%rcx, %rcx, 4), %ecx
    shll    $1, %ecx
    addl    %ecx, %edx
    andl    $0x0F, %eax
    addl    %eax, %edx
    movl    %edx, %eax
    addq    %r9, %rax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2bin_uint128
# In  : %rdi:%rsi (128-bit BCD)
# Out : %rax:%rdx (Binary)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint128
.type bcd2bin_uint128, @function
bcd2bin_uint128:
    .cfi_startproc
    movq    %rsi, %xmm0
    pinsrq  $1, %rdi, %xmm0
    movdqa  .Lmask_0F(%rip), %xmm2
    movdqa  %xmm0, %xmm1
    psrlw   $4, %xmm1
    pand    %xmm2, %xmm1
    pand    %xmm2, %xmm0
    pmullw  .Lpowers(%rip), %xmm0
    pmullw  .Lpowers(%rip), %xmm1
    psllw   $4, %xmm1
    paddw   %xmm1, %xmm0
    phaddw  %xmm0, %xmm0
    phaddw  %xmm0, %xmm0
    phaddw  %xmm0, %xmm0
    movq    %xmm0, %rax
    pextrq  $1, %xmm0, %rdx
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# bcd2bin_uint256
# In  : %ymm0 (256-bit BCD), %rdi (Output Buffer)
# Out : %rdi (Buffer filled)
# ------------------------------------------------------------------------------
.globl bcd2bin_uint256
.type bcd2bin_uint256, @function
bcd2bin_uint256:
    .cfi_startproc
    vpand   .Lmask_0F(%rip), %ymm0, %ymm2
    vpsrlw  $4, %ymm0, %ymm1
    vpand   .Lmask_0F(%rip), %ymm1, %ymm1
    vpmullw .Lpowers_lo(%rip), %ymm2, %ymm2
    vpmullw .Lpowers_lo(%rip), %ymm1, %ymm1
    vpsllw  $4, %ymm1, %ymm1
    vpaddw  %ymm1, %ymm2, %ymm0
    vextracti128 $1, %ymm0, %xmm1
    vpaddw  %xmm1, %xmm0, %xmm0
    vphaddw %xmm0, %xmm0, %xmm0
    vphaddw %xmm0, %xmm0, %xmm0
    vphaddw %xmm0, %xmm0, %xmm0
    vphaddw %xmm0, %xmm0, %xmm0
    vmovq   %xmm0, (%rdi)
    vzeroupper
    ret
    .cfi_endproc
                
.section .note.GNU-stack,"",@progbits
