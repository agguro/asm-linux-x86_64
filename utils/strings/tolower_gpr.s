/* **************************************************************************
 * Function     : tolower_gpr
 * Description  : Converts string to lowercase using branchless GPR logic.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Pointer to string
 * Output       : %rax = Pointer to start of string
 * * Performance: Branchless GPR (General Purpose Register)
 * ************************************************************************** */

.section .text
.globl tolower_gpr
.type tolower_gpr, @function

tolower_gpr:
    movq    %rdi, %rax          # Save original pointer for return
.loop:
    movb    (%rdi), %dl         # Load character
    testb   %dl, %dl            # Check NULL
    jz      .done
    
    # Range check: 'A' (65) to 'Z' (90)
    cmpb    $'A', %dl
    setae   %cl                 # cl = 1 if char >= 'A'
    cmpb    $'Z', %dl
    setbe   %ch                 # ch = 1 if char <= 'Z'
    andb    %ch, %cl            # cl = 1 if ('A' <= char <= 'Z')
    negb    %cl                 # cl = 0xFF (mask) if alpha, 0x00 if not
    
    # Set bit 5 if mask is 0xFF
    andb    $0x20, %cl          # cl = 0x20 if alpha, 0x00 if not
    orb     %cl, (%rdi)         # Set bit 5 in-place if alpha
    
    incq    %rdi
    jmp     .loop
.done:
    ret

.size tolower_gpr, .-tolower_gpr
.section .note.GNU-stack,"",@progbits
