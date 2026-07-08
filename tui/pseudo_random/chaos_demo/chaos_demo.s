; ==============================================================================
; Name        : libchaos.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Demonstration of pseudo-random number generation 
;             : use with libchaos.so.
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ============================================================================== 

.include "unistd.s"

.section .data
buffer:     .quad 0, 0
            .byte 10
.equ buffer_len, . - buffer

.section .text
.global _start

_start:
    # 1. Autoseed
    xorq    %rdi, %rdi
    call    init_entropy

    call    get_random_number
    movq    %rax, %rdi
    call    qwordbin2hexascii

    # Store result in buffer
    movq    %rax, buffer(%rip)
    movq    %rdx, buffer+8(%rip)

    movq    $write, %rax
    movq    $stdout, %rdi
    leaq    buffer(%rip), %rsi
    movq    $buffer_len, %rdx
    syscall

    # 2. Custom seed
    movabs  $0x1234567890ABCDEF, %rdi
    call    init_entropy

    call    get_random_number
    movq    %rax, %rdi
    call    qwordbin2hexascii

    movq    %rax, buffer(%rip)
    movq    %rdx, buffer+8(%rip)
    movq    $write, %rax
    movq    $stdout, %rdi
    leaq    buffer(%rip), %rsi
    movq    $buffer_len, %rdx
    syscall

    movq    $exit, %rax
    xorq    %rdi, %rdi
    syscall

.size _start, . - _start

qwordbin2hexascii:
    # 1. Prologue: Save only Callee-saved GPRs (ABI Requirement)
    pushq   %rbx
    pushq   %r12
    pushq   %r13
    pushq   %r14
    pushq   %r15
    # (Note: rbp is only strictly needed if you are using it for addressing;
    # since we are leaf-like here, we can skip rbp or push it if preferred)

    # 2. Conversion: Start with qword from rdi
    movq    %rdi, %rax

    # Unpack qword in rax into two dwords in rdx and rax
    movl    %eax, %edx
    shrq    $32, %rax

    # Unpack dwords into words
    movq    %rax, %r8
    movq    %rdx, %r9
    shlq    $16, %r8
    shlq    $16, %r9
    orq     %r8, %rax
    orq     %r9, %rdx
    movabs  $0x0000FFFF0000FFFF, %rcx
    andq    %rcx, %rax
    andq    %rcx, %rdx

    # Unpack words into bytes
    movq    %rax, %r8
    movq    %rdx, %r9
    shlq    $8, %r8
    shlq    $8, %r9
    orq     %r8, %rax
    orq     %r9, %rdx
    movabs  $0x00FF00FF00FF00FF, %rcx
    andq    %rcx, %rax
    andq    %rcx, %rdx

    # Unpack bytes into nibbles
    movq    %rax, %r8
    movq    %rdx, %r9
    shlq    $4, %r8
    shlq    $4, %r9
    orq     %r8, %rax
    orq     %r9, %rdx
    movabs  $0x0F0F0F0F0F0F0F0F, %rcx
    andq    %rcx, %rax
    andq    %rcx, %rdx

    # Load unpacked qwords into xmm registers (volatile)
    movq    %rdx, %xmm0
    pinsrq  $1, %rax, %xmm0

    shlq    $4, %rcx
    movq    %rcx, %xmm1
    pinsrq  $1, %rcx, %xmm1

    movabs  $0x0606060606060606, %rax
    movq    %rax, %xmm2
    pinsrq  $1, %rax, %xmm2

    # Perform hex conversion
    paddb   %xmm2, %xmm0
    pand    %xmm0, %xmm1
    psubb   %xmm2, %xmm0
    psrlw   $1, %xmm1
    psubb   %xmm1, %xmm0
    psrlw   $3, %xmm1
    psubb   %xmm1, %xmm0
    psrlw   $1, %xmm2
    paddb   %xmm2, %xmm1
    psllw   $4, %xmm1
    paddb   %xmm1, %xmm0

    # Move results out and swap endianness
    movq    %xmm0, %rdx
    movhlps %xmm0, %xmm0
    movq    %xmm0, %rax
    bswapq  %rdx
    bswapq  %rax

    # 3. Epilogue: Restore Callee-saved GPRs
    popq    %r15
    popq    %r14
    popq    %r13
    popq    %r12
    popq    %rbx
    ret

.section .note.GNU-stack,"",@progbits
