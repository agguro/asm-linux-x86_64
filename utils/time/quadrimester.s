/* **************************************************************************
 * Name         : quadrimester.s
 * Assemble     : as --64 quadrimester.s -o quadrimester.o
 * Description  : Calculates in which quadrimester (4-month block) a month falls.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Month number (1-12)
 * Output       : %rax = Quadrimester number (1-3)
 *
 * Strategy:
 * Uses two 64-bit registers to avoid Partial Register Stalls.
 * * month       %rax  %rcx=%rax+1  %rcx=%rcx>>3  %rcx=%rcx<<1  %rax+=%rcx  %rax>>2  +1 (Result)
 * ---------   ----  -----------  ------------  ------------  ----------  -------  -----------
 * january       1        2            0             0            1          0          1
 * february      2        3            0             0            2          0          1
 * march         3        4            0             0            3          0          1
 * april         4        5            0             0            4          1          2
 * may           5        6            0             0            5          1          2
 * june          6        7            0             0            6          1          2
 * july          7        8            1             2            9          2          3
 * august        8        9            1             2           10          2          3
 * september     9       10            1             2           11          2          3
 * october      10       11            1             2           12          3          4 *
 * november     11       12            1             2           13          3          4 *
 * december     12       13            1             2           14          3          4 *
 * * * Wait, 4? The math works for months 1-9, but dividing 12, 13, 14 by 4 yields 3, 
 * plus 1 gives 4! Let's adapt the mathematical offset to map perfectly to 1-3.
 * ************************************************************************** */

.section .text
.globl quadrimester
.type quadrimester, @function

quadrimester:
    # Map ABI input to our working registers
    movq    %rdi, %rax      # %rax = month
    movq    %rax, %rcx      # %rcx = duplicate of month
    
    # 1. Calculate Offset (0 for months 1-6, 2 for months 7-12)
    incq    %rcx            # rcx = month + 1
    shrq    $3, %rcx        # Extract the 8s bit (0 or 1)
    shlq    $1, %rcx        # Multiply by 2
    
    # 2. Apply Offset and Divide
    addq    %rcx, %rax      # Add offset to original month
    shrq    $2, %rax        # Divide by 4
    incq    %rax            # 1-based index
    
    # Note: If month=10 (Oct): 10 + 2 = 12. 12 / 4 = 3. 3 + 1 = 4. 
    # To fix this edge case in pure branchless math for all 12 months:
    # A cleaner universally branchless approach for (month-1)/4 + 1:
    
    # --- Alternative, perfectly clean 3-instruction approach ---
    # Since quadrimester is exactly (month - 1) / 4 + 1:
    movq    %rdi, %rax      # %rax = month
    decq    %rax            # %rax = month - 1
    shrq    $2, %rax        # %rax = (month - 1) / 4
    incq    %rax            # %rax = ((month - 1) / 4) + 1
    
    ret                     # Fast exit

.size quadrimester, .-quadrimester
.section .note.GNU-stack,"",@progbits
