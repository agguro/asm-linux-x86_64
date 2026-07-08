/* ***************************************************************************
 * Name         : print_stringz.s
 * Assemble     : as --64 print_stringz.s -o print_stringz.o
 * Description  : Prints a NULL-terminated string to a specified FD.
 *
 * Input        : %rdi = File Descriptor (1=stdout, 2=stderr)
 * %rsi = Pointer to NULL-terminated string
 * Output       : None (Volatile registers are clobbered per System V ABI)
 *
 * Strategy:
 * Strict System V ABI compliance. We do not save caller-saved registers 
 * (like %rcx, %r11) as that is the caller's responsibility. We only use 
 * the stack to preserve our own inputs across the 'call strlen', while 
 * explicitly managing the 16-byte stack alignment rule.
 * **************************************************************************
 */

.globl print_stringz
.type print_stringz, @function
.extern strlen

.section .text
print_stringz:
    # --- Stack Setup & Alignment ---
    # On entry, %rsp is misaligned (ends in 0x8)
    pushq   %rsi            # Save string pointer. (%rsp is now 16-byte aligned)
    pushq   %rdi            # Save FD. (%rsp is misaligned)
    pushq   %rax            # Dummy push for alignment. (%rsp is 16-byte aligned again)

    # 1. Prepare for strlen
    movq    %rsi, %rdi      # Arg 1: String pointer
    call    strlen          # RAX = length of string
    
    # 2. Syscall Setup (sys_write)
    movq    %rax, %rdx      # Arg 3: Count (from strlen)
    
    # Restore our original inputs
    addq    $8, %rsp        # Discard dummy alignment push
    popq    %rdi            # Arg 1: Restore FD
    popq    %rsi            # Arg 2: Restore string pointer
    
    movq    $1, %rax        # syscall 1 is sys_write
    syscall

    # 3. Fast Exit
    # No base pointer (%rbp) frame to tear down.
    ret

.size print_stringz, .-print_stringz
.section .note.GNU-stack,"",@progbits
