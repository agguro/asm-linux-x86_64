/* **************************************************************************
 * Name         : semester.s
 * Assemble     : as --64 semester.s -o semester.o
 * Description  : Calculates in which semester a month falls.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Month number (1-12)
 * Output       : %rax = Semester number (1-2)
 *
 * Strategy:
 * month        nr   binary (+1)   shift >> 3   inc (+1)  = Semester
 * ----------   --   -----------   ----------   --------  ----------
 * january       1      0010           00          01          1
 * february      2      0011           00          01          1
 * march         3      0100           00          01          1
 * april         4      0101           00          01          1
 * may           5      0110           00          01          1
 * june          6      0111           00          01          1
 * july          7      1000           01          10          2
 * august        8      1001           01          10          2
 * september     9      1010           01          10          2
 * october      10      1011           01          10          2
 * november     11      1100           01          10          2
 * december     12      1101           01          10          2
 *
 * Leaf function. Zero stack frame. O(1) execution.
 * ************************************************************************** */

.section .text
.globl semester
.type semester, @function

semester:
    # Map the ABI input (%rdi) to the ABI output (%rax)
    movq    %rdi, %rax      # %rax = month
 
    incq    %rax            # s = month + 1
    shrq    $3, %rax        # s = s / 8
    incq    %rax            # s = s + 1
    
    ret                     # Fast exit

.size semester, .-semester
.section .note.GNU-stack,"",@progbits
