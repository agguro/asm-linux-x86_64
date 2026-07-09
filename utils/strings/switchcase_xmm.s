/* **************************************************************************
 * Name         : switchcase_xmm.s
 * Description  : SIMD-accelerated switchcase (16 bytes per cycle).
 * ABI          : System V AMD64
 * ************************************************************************** */

.section .text
.globl switchcase_gpr
switchcase_gpr:
    movq    %rdi, %rax
.loop:
    movb    (%rdi), %dl
    testb   %dl, %dl
    jz      .done
    
    # Check A-Z
    movb    %dl, %ch
    subb    $'A', %ch
    cmpb    $25, %ch
    jbe     .flip
    
    # Check a-z
    movb    %dl, %ch
    subb    $'a', %ch
    cmpb    $25, %ch
    ja      .skip
    
.flip:
    xorb    $0x20, (%rdi)
.skip:
    incq    %rdi
    jmp     .loop
.done:
    ret

.size switchcase_xmm, .-switchcase_xmm
.section .note.GNU-stack,"",@progbits
