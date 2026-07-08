; ==============================================================================
; Name        : liblcg.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Linear Congruential Generator for pseudo-random number generation
;             ; using Marsaglia's recommended 32-bit parameters."
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
    global init_entropy
    global get_random_number

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

get_random_number:
    push    rbp
    mov     rbp, rsp
    
    ; Logic: Xn+1 = (69069 * Xn + 362437)
    mov     rax, [rel seed]
    mov     rbx, 69069
    mul     rbx                 ; RDX:RAX = RAX * RBX
    add     rax, 362437
    mov     [rel seed], rax
    
    shr     rax, 32             ; Extract high 32 bits
    
    mov     rsp, rbp
    pop     rbp
    ret