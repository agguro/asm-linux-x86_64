/* **************************************************************************
 * Name         : trimester.s
 * Assemble     : as --64 trimester.s -o trimester.o
 * Description  : Calculates in which trimester a month falls.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Month number (1-12)
 * Output       : %rax = Trimester number (1-3)
 *
 * Strategy:
 * month        nr   binary (-1)   shift >> 2   inc (+1)  = Trimester
 * ----------   --   -----------   ----------   --------  -----------
 * january       1      0000           00          01          1
 * february      2      0001           00          01          1
 * march         3      0010           00          01          1
 * april         4      0011           00          01          1
 * may           5      0100           01          10          2
 * june          6      0101           01          10          2
 * july          7      0110           01          10          2
 * august        8      0111           01          10          2
 * september     9      1000           10          11          3
 * october      10      1001           10          11          3
 * november     11      1010           10          11          3
 * december     12      1011           10          11          3
 *
 * Leaf function. Zero stack frame. O(1) execution.
 * ************************************************************************** */

.section .text
.globl trimester
.type trimester, @function

trimester:
    # We map the ABI input (%rdi) to the ABI output (%rax) immediately.
    movq    %rdi, %rax      # %rax = month
    
    decq    %rax            # t = month - 1
    shrq    $2, %rax        # t = t / 4
    incq    %rax            # t = t + 1
    
    ret                     # Fast exit

.size trimester, .-trimester
.section .note.GNU-stack,"",@progbits
