; ==============================================================================
; Name        : libchaos.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Dummy .so file for pseudo-random number generation
;             : this isn't used.
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

bits 64

section .text
    ; procedures that every .so should have
global init_entropy:function
global  get_random_number:function

; init_entropy: Initialize the random number generator with a seed
; in : rdi = seed (if 0 then use time as seed)

init_entropy:
    ret

; get_random_number: Generate a pseudo-random 32-bit number
; in : none
; out: eax = 32-bit pseudo-random number

get_random_number:
    mov     rax, 0xDEADBEEFCAFEBABE     ; dummy 'random' to test
    ret