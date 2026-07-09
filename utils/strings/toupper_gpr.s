/* **************************************************************************
 * Function     : toupper_gpr
 * Description  : Converts string to uppercase using branchless GPR logic.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Pointer to string
 * Output       : %rax = Pointer to start of string
 * * Performance  : Branchless GPR (General Purpose Register)
 * ************************************************************************** */

.section .text
.globl toupper_gpr
.type toupper_gpr, @function

toupper_gpr:
    movq    %rdi, %rax          # Save original pointer for return
.loop:
    movb    (%rdi), %dl         # Load character
    testb   %dl, %dl            # Check NULL
    jz      .done
    
    # Range check: 'a' (97) to 'z' (122)
    cmpb    $'a', %dl
    setae   %cl                 # cl = 1 if >= 'a'
    cmpb    $'z', %dl
    setbe   %ch                 # ch = 1 if <= 'z'
    andb    %ch, %cl            # cl = 1 if ('a' <= char <= 'z')
    negb    %cl                 # cl = 0xFF (mask) if alpha, 0x00 if not
    
    # Clear bit 5 if mask is 0xFF
    andb    $0x20, %cl          # cl = 0x20 if alpha, 0x00 if not
    subb    %cl, (%rdi)         # Clear bit 5 in-place if alpha
    
    incq    %rdi
    jmp     .loop
.done:
    ret

.size toupper_gpr, .-toupper_gpr
.section .note.GNU-stack,"",@progbits