; ==============================================================================
; Name        : generator_template.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : template to use in all pseudo-random number generation programs
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

bits 64

[list -]
    %include "unistd.inc"
    %include "sys/time.inc"
[list +]

section .bss
    seed:   resq 1

section .text
    ; procedures that every .so should have
global init_entropy:function
global get_random_int32:function
global get_random_int64:function
global get_random_float32:function
global get_random_float64:function

; init_entropy: Initialize the random number generator with a seed
; in : rdi = seed (if 0 then use time as seed)

init_entropy:
    push    rbp
    mov     rbp, rsp
    and     rsp, -16            ; ABI: 16-byte align stack
    
    mov     rax, rdi
    test    rax, rax
    jnz     .store_seed

    ; create seed from time
    sub     rsp, 16
    mov     rdi, CLOCK_REALTIME
    mov     rsi, rsp
    syscall clock_gettime
    
    mov     rdx, [rsp]          ; seconds
    mov     rax, [rsp+8]        ; nanoseconds
    xor     rax, rdx            ; entropy mix
    add     rsp, 16

.store_seed:
    mov     [rel seed], rax     ; Store seed (RIP-relative)    
    mov     rsp, rbp
    pop     rbp
    ret

; get_random_number: Generate a pseudo-random 32-bit number
; in : none
; out: eax = 32-bit pseudo-random number

get_random_int32:
    ; the _do_math procedure should be implemented in the derived .so file
    call    _do_math
    shr     rax, 32
    ret

get_random_int64:
    ; the _do_math procedure should be implemented in the derived .so file
    call    _do_math
    ret

get_random_float32:  
    ; the _do_math procedure should be implemented in the derived .so file
    call    _do_math
    ; Keep only 23 bits for the mantissa
    and     rax, 0x007FFFFF
    ; Set the exponent to 1.0 (0x3F800000)
    or      rax, 0x3F800000
    ; Move to XMM0
    movd    xmm0, eax
    ; Subtract 1.0
    mov     eax, __float32__(1.0)
    movd    xmm1, eax
    subss   xmm0, xmm1
    ret

get_random_float64:
    ; the _do_math procedure should be implemented in the derived .so file
    call    _do_math
    ; Keep only 52 bits for the mantissa
    and     rax, 0x000FFFFFFFFFFFFF
    ; Set the exponent to 1.0 (0x3FF0000000000000)
    or      rax, 0x3FF0000000000000
    ; Move to XMM0
    movq    xmm0, rax
    ; Subtract 1.0
    mov     rax, __float64__(1.0)
    movq    xmm1, rax
    subsd   xmm0, xmm1
    ret
