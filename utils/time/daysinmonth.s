/* **************************************************************************
 * Name         : daysinmonth.s
 * Assemble     : as --64 daysinmonth.s -o daysinmonth.o
 * Description  : Calculates the number of days in a given month.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Month number (1-12)
 * Output       : %rax = Days in month (28, 30, or 31)
 *
 * Strategy:
 * 1. Base Logic: Days = (((Month >> 3) ^ Month) & 1) | 30
 * 2. February Exception: Handled branchlessly using 'sete'.
 * * Leaf function. Zero stack frame. No Partial Register Stalls.
 * ************************************************************************** */

.section .text
.globl daysinmonth
.type daysinmonth, @function

daysinmonth:
    movq    %rdi, %rcx      # %rcx = working copy of the month
    
    # --- 1. The 30/31 Day Base Calculation ---
    movq    %rcx, %rax      # %rax = month
    shrq    $3, %rax        # %rax = month >> 3
    xorq    %rcx, %rax      # %rax = (month >> 3) ^ month
    andq    $1, %rax        # Isolate bit 0
    orq     $30, %rax       # %rax is now 30 or 31
    
    # --- 2. The February Exception (Branchless) ---
    cmpq    $2, %rcx        # Is it February (month == 2)?
    sete    %cl             # %cl = 1 if February, else 0
    movzbq  %cl, %rcx       # Zero-extend to 64-bit (%rcx = 1 or 0)
    shlq    $1, %rcx        # %rcx = 2 (if Feb) or 0 (otherwise)
    
    # Apply the February offset via your original XOR logic
    # If Feb: 30 ^ 2 = 28. If not: XOR 0 does nothing.
    xorq    %rcx, %rax      
    
    ret                     # Fast exit

.size daysinmonth, .-daysinmonth
.section .note.GNU-stack,"",@progbits
