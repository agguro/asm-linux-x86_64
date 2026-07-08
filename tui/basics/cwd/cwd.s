/*
 **************************************************************************
 * Name          : cwd.s
 * Description   : Linux alternative for pwd (GNU Style - No Dependencies).
 * Uses brk for dynamic buffer allocation to handle paths of 
 * arbitrary length.
 * **************************************************************************
 */

 .nolist
    .include "unistd.inc"
.list

.section .rodata
    .align 16
1:  .ascii "Error: out of memory"
2:  .ascii "\n"
    .equ ERR_MSG_LEN, . - 1b
    .equ LF_LEN,      . - 2b

.section .text
.globl _start
.type _start, @function
.extern strlen

_start:
    # 1. Get current break (starting point of heap)
    xorq    %rdi, %rdi
    movq    $brk, %rax
    syscall
    
    testq   %rax, %rax
    js      .Lerror
    
    movq    %rax, %r12          # %r12 = Start of buffer
    movq    %rax, %r9           # %r9 = Current end of buffer (break)

.Lrepeat:
    # 2. Grow the heap by 64 bytes
    leaq    64(%r9), %rdi       # Request 64 more bytes
    movq    $brk, %rax
    syscall
    
    # If the return value is the same as before, the OS refused to grow
    cmpq    %rax, %r9
    je      .Lcleanup
    
    movq    %rax, %r9           # Update tracking of our ceiling

    # 3. Try to get the Current Working Directory
    movq    %r12, %rdi          # Buffer pointer (start)
    movq    %r9, %rsi           # Calculate size (Ceiling - Start)
    subq    %r12, %rsi
    movq    $getcwd, %rax
    syscall
    
    # 4. Handle results
    testq   %rax, %rax
    jns     .Lprint_it          # Success: RAX is a pointer (positive)

    # Check specifically for -34 (ERANGE: result too large for buffer)
    cmpq    $-34, %rax
    je      .Lrepeat            # If too small, loop back and grow more
    jmp     .Lerror             # Otherwise, unexpected error

.Lprint_it:
    # getcwd returns the buffer address, we need the length for sys_write
    movq    %r12, %rdi
    call    strlen              # RAX = length of string in buffer
    
    # 5. Write the path to stdout
    movq    %rax, %rdx          # Length
    movq    %r12, %rsi          # Buffer address
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall

    # 6. Write the newline
    movq    $LF_LEN, %rdx
    leaq    2b(%rip), %rsi
    movq    $stdout, %rdi
    movq    $write, %rax
    syscall
    jmp     .Lexit

.Lcleanup:
    # Reset heap to original state before error
    movq    %r12, %rdi
    movq    $brk, %rax
    syscall

.Lerror:
    # Output error message to stderr
    movq    $ERR_MSG_LEN, %rdx
    leaq    1b(%rip), %rsi
    movq    $stderr, %rdi
    movq    $write, %rax
    syscall

.Lexit:
    movq    $exit, %rax
    xorq    %rdi, %rdi          # Exit code 0
    syscall

.size _start, . - _start
.section .note.GNU-stack,"",@progbits
