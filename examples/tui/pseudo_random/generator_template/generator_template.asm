; ==============================================================================
; Name        : generator_template.s
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : template to use in all pseudo-random number generation programs
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

.section .bss
.align 8
    seed:   .quad 0

.section .rodata
.align 4
    one_f32: .float 1.0
.align 8
    one_f64: .double 1.0

.section .text
.global init_entropy
.global get_random_int32
.global get_random_int64
.global get_random_float32
.global get_random_float64

.include "unistd.inc"
.include "sys/time.inc"

init_entropy:
    pushq   %rbp
    movq    %rsp, %rbp
    andq    $-16, %rsp

    testq   %rdi, %rdi
    jnz     .store_seed

    subq    $16, %rsp
    movq    $0, %rdi            # CLOCK_REALTIME (Verify your constant)
    movq    %rsp, %rsi
    movq    $228, %rax          # syscall: clock_gettime
    syscall

    movq    (%rsp), %rdx        # seconds
    movq    8(%rsp), %rax       # nanoseconds
    xorq    %rdx, %rax          # entropy mix
    addq    $16, %rsp

.store_seed:
    movq    %rax, seed(%rip)
    movq    %rbp, %rsp
    popq    %rbp
    ret

get_random_int32:
    call    _do_math
    shrq    $32, %rax
    ret

get_random_int64:
    call    _do_math
    ret

get_random_float32:
    call    _do_math
    andq    $0x007FFFFF, %rax
    orq     $0x3F800000, %rax
    movd    %eax, %xmm0
    movss   one_f32(%rip), %xmm1
    subss   %xmm1, %xmm0
    ret

get_random_float64:
    call    _do_math
    andq    $0x000FFFFFFFFFFFFF, %rax
    orq     $0x3FF0000000000000, %rax
    movq    %rax, %xmm0
    movsd   one_f64(%rip), %xmm1
    subsd   %xmm1, %xmm0
    ret
