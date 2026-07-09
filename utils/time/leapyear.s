/* **************************************************************************
 * Name         : leapyear.s
 * Assemble     : as --64 leapyear.s -o leapyear.o
 * Description  : Determines if a given year is a leap year.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Year
 * Output       : %rax = 1 (True) or 0 (False)
 *
 * Strategy:
 * 1. 75% of years fail the (Year % 4 == 0) test immediately via bitwise AND.
 * 2. If divisible by 4, check division by 100.
 * 3. Mathematical shortcut: If divisible by 100, the quotient (Year / 100)
 * must be divisible by 4 for the year to be divisible by 400.
 * Leaf function. Zero stack frame. Clobbers only volatile registers.
 * ************************************************************************** */

.section .text
.globl leapyear
.type leapyear, @function

leapyear:
    # --- Fast Path ---
    xorq    %rax, %rax      # Default return = 0 (Not a leap year)
    
    testq   $3, %rdi        # Is it divisible by 4? (Check lowest 2 bits)
    jnz     .Ldone          # If not, fast exit (Catches 75% of years instantly)
    
    # --- Century Check ---
    movq    %rdi, %rax      # Move year into RAX for division
    xorq    %rdx, %rdx      # Clear RDX for division
    movq    $100, %r8       # Divisor = 100 (Using volatile %r8, avoiding %rbx!)
    divq    %r8             # RAX = Quotient, RDX = Remainder
    
    testq   %rdx, %rdx      # Was the remainder 0?
    jz      .Lcheck_400     # If yes, it's a century year, requires 400 check
    
    # Divisible by 4, but NOT by 100 -> Leap Year
    movq    $1, %rax
    ret

    # --- The 400-Year Shortcut ---
.Lcheck_400:
    # Since we just divided by 100, RAX holds (Year / 100).
    # If (Year / 100) is divisible by 4, then Year is divisible by 400.
    testq   $3, %rax        # Is quotient divisible by 4?
    setz    %al             # AL = 1 if divisible (Z-flag set), else 0
    movzbq  %al, %rax       # Zero-extend AL to full 64-bit RAX
    
.Ldone:
    ret                     # Fast exit

.size leapyear, .-leapyear
.section .note.GNU-stack,"",@progbits
