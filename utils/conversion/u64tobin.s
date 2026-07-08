/* **************************************************************************
 * Name         : u64tobin.s
 * Assemble     : as --64 u64tobin.s -o u64tobin.o
 * Description  : Converts a 64-bit integer to a binary bitstring.
 *
 * Input        : %rdi = value
 * %rsi = buffer (minimum 65 bytes)
 * %rdx = mode (0=trim, -1=auto, >0=fixed width)
 * Output       : %rax = pointer to start of string in buffer
 * %rdx = width of the string used
 *
 * Strategy:
 * Leaf function: Zero stack usage. Utilizes volatile registers (r8-r11) 
 * to preserve original arguments and track states without pushing to memory.
 * ************************************************************************** */

.section .text
.globl u64tobin
.type u64tobin, @function

u64tobin:
    # --- Register Setup (No Stack!) ---
    movq    %rsi, %r10      # %r10 = Save original buffer start
    movq    %rdx, %r11      # %r11 = Save mode / target width

    # 1. Handle Auto-Detect Mode
    cmpq    $-1, %r11
    jne     .Lcheck_trim
    lzcntq  %rdi, %rcx      # Get number of leading zeros
    movq    $64, %r11
    subq    %rcx, %r11      # Width = 64 - zeros
    jnz     .Lconvert
    movq    $1, %r11        # If value is 0, width is 1
    jmp     .Lconvert

.Lcheck_trim:
    testq   %r11, %r11
    jnz     .Lconvert
    # Mode 0 (trim) logic is processed after conversion loop

.Lconvert:
    movq    %rdi, %rax      # %rax = Load working value
    movq    %rsi, %rdi      # %rdi = Set write pointer (overwriting original value)
    movq    $64, %rcx       # %rcx = Loop counter
    xorq    %r9, %r9        # %r9  = 'first 1' pointer (Replaces %rbx)

.Lloop:
    xorl    %r8d, %r8d
    shlq    $1, %rax        # Shift MSB into Carry Flag
    adcb    $'0', %r8b      # ASCII '0' + Carry
    movb    %r8b, (%rdi)    # Store bit
    
    cmpb    $'1', %r8b
    jne     .Lnext
    testq   %r9, %r9
    jnz     .Lnext
    movq    %rdi, %r9       # Capture pointer to first '1'

.Lnext:
    incq    %rdi
    loop    .Lloop
    movb    $0, (%rdi)      # Null terminator

    # --- Result Calculation ---
    testq   %r11, %r11
    jz      .Ltrim_logic    # If mode 0, find first '1'

    # Fixed Width Exit
    movq    $64, %rax
    subq    %r11, %rax
    addq    %r10, %rax      # %rax = Calculate final start pointer using %r10
    movq    %r11, %rdx      # %rdx = Return width
    ret                     # Fast exit

.Ltrim_logic:
    testq   %r9, %r9
    jnz     .Lfound_one
    
    # All Zeros Exit
    leaq    63(%r10), %rax  # %rax = Pointer to the last '0'
    movq    $1, %rdx        # %rdx = Width is 1
    ret                     # Fast exit

.Lfound_one:
    movq    %r9, %rax       # %rax = Pointer to first '1'
    leaq    64(%r10), %rdx
    subq    %r9, %rdx       # %rdx = Calculate effective width
    ret                     # Fast exit

.size u64tobin, .-u64tobin 
.section .note.GNU-stack,"",@progbits
