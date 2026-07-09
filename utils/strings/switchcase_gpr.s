/* **************************************************************************
 * Function     : switchcase_gpr
 * Description  : Toggles case for alpha characters using branchless GPR logic.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Pointer to string
 * Output       : %rax = Pointer to start of string
 * * Performance: Branchless GPR (General Purpose Register)
 * ************************************************************************** */

.section .text
.globl switchcase_gpr
.type switchcase_gpr, @function

switchcase_gpr:
    movq    %rdi, %rax          # Save original pointer for return
.loop:
    movb    (%rdi), %dl         # Load character
    testb   %dl, %dl            # Check NULL
    jz      .done
    
    # 1. Check A-Z range
    movb    %dl, %cl            # Copy char
    subb    $'A', %cl           # cl = char - 'A'
    cmpb    $25, %cl            # Is it 0-25?
    setbe   %ch                 # ch = 1 if 'A'-'Z'
    
    # 2. Check a-z range
    movb    %dl, %r8b          # Copy char
    subb    $'a', %r8b          # r8b = char - 'a'
    cmpb    $25, %r8b           # Is it 0-25?
    setbe   %r9b                # r9b = 1 if 'a'-'z'
    
    # 3. Combine masks: (A-Z) OR (a-z)
    orb     %r9b, %ch           # ch = 1 if alpha
    negb    %ch                 # ch = 0xFF if alpha, 0x00 if not
    
    # 4. Toggle bit 5 if mask is 0xFF
    andb    $0x20, %ch          # ch = 0x20 if alpha, 0x00 if not
    xorb    %ch, (%rdi)         # Flip bit 5 in-place if alpha
    
    incq    %rdi
    jmp     .loop
.done:
    ret

.size switchcase_gpr, .-switchcase_gpr
.section .note.GNU-stack,"",@progbits
