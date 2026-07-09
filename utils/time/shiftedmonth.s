/* **************************************************************************
 * Name         : shiftedmonth.s
 * Assemble     : as --64 shiftedmonth.s -o shiftedmonth.o
 * Description  : Calculates the shifted month from a given month.
 * This number can be used to calculate Easter sundays.
 * Returns 0 if the masked input is not a legal shifted month.
 *
 * ABI          : System V AMD64 (Linux)
 * Input        : %rdi = Month number
 * Output       : %rax = Shifted month number
 *
 * Strategy:
 * AX <- month       AX <- AX - 3        AND AX, 0xF40F          NOT AH            AND AL,AH          INC AL
 * ---------------   ---------------     ---------------         -----------       -----------        -----------
 * 0000000000000001  1111111111111110    1111010000001110        00001011          00001010           00001011 (11)
 * 0000000000000010  1111111111111111    1111010000001111        00001011          00001011           00001100 (12)
 * 0000000000000011  0000000000000000    0000000000000000        11111111          00000000           00000001 (1)
 * 0000000000000100  0000000000000001    0000000000000001        11111111          00000001           00000010 (2)
 *
 * Leaf function. Zero stack frame. Uses 16-bit register overlapping (%ah, %al).
 * ************************************************************************** */

.section .text
.globl shiftedmonth
.type shiftedmonth, @function

shiftedmonth:
    # 1. Grab ABI Input
    movq    %rdi, %rax              # Load input month into return register
    andq    $0xF, %rax              # Take only lower 4 bits into concern
    
    # 2. Bit-Magic Calculation
    subw    $3, %ax                 # AX = AX - 3 
    andw    $0xF40F, %ax            # Mask 1111010000001111b
    notb    %ah                     # Invert AH
    andb    %ah, %al                # AL = AL AND AH
    incb    %al                     # AL = AL + 1
    
    # 3. Clean Output
    andq    $0xF, %rax              # Zero-extend the 4-bit result across the full 64-bit RAX
    ret                             # Fast exit

.size shiftedmonth, .-shiftedmonth
.section .note.GNU-stack,"",@progbits
