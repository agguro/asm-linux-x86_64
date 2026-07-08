; ==============================================================================
; Name        : libchaos.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Dummy .so file for pseudo-random number generation
;             : this isn't used.
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

.section .text
.global _do_math

# _do_math:
# in : none
# out: rax = internal state for the generator
_do_math:
    # Just returning the dummy value as requested.
    # The template will grab this RAX and handle the 32-bit truncation
    # if the user calls get_random_int32.
    movabs  $0xDEADBEEFCAFEBABE, %rax
    ret
