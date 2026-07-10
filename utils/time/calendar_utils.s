# ==============================================================================
# File: calendar_utils.s
# Description: Date/Calendar utility routines.
# Architecture: x86_64 (System V ABI)
# ==============================================================================

.text

# ------------------------------------------------------------------------------
# is_weekend
# In  : %rdi (1=Mon, ..., 7=Sun)
# Out : %al (0=Weekday, 1=Weekend)
# ------------------------------------------------------------------------------
.globl is_weekend
.type is_weekend, @function
is_weekend:
    .cfi_startproc
    movq    %rdi, %rax
    incb    %al
    incb    %al
    shrb    $3, %al
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# daysinmonth
# In  : %rdi (Month 1-12)
# Out : %rax (Days: 28, 30, or 31)
# ------------------------------------------------------------------------------
.globl daysinmonth
.type daysinmonth, @function
daysinmonth:
    .cfi_startproc
    movq    %rdi, %rcx
    movq    %rcx, %rax
    shrq    $3, %rax
    xorq    %rcx, %rax
    andq    $1, %rax
    orq     $30, %rax
    cmpq    $2, %rcx
    sete    %cl
    movzbq  %cl, %rcx
    shlq    $1, %rcx
    xorq    %rcx, %rax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# is_leapyear
# In  : %rdi (Year)
# Out : %rax (1=True, 0=False)
# ------------------------------------------------------------------------------
.globl is_leapyear
.type is_leapyear, @function
is_leapyear:
    .cfi_startproc
    xorq    %rax, %rax
    testq   $3, %rdi
    jnz     .Ldone
    movq    %rdi, %rax
    xorq    %rdx, %rdx
    movq    $100, %r8
    divq    %r8
    testq   %rdx, %rdx
    jz      .Lcheck_400
    movq    $1, %rax
    ret
.Lcheck_400:
    testq   $3, %rax
    setz    %al
    movzbq  %al, %rax
.Ldone:
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# quadrimester
# In  : %rdi (Month 1-12)
# Out : %rax (1-3)
# ------------------------------------------------------------------------------
.globl quadrimester
.type quadrimester, @function
quadrimester:
    .cfi_startproc
    movq    %rdi, %rax
    decq    %rax
    shrq    $2, %rax
    incq    %rax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# semester
# In  : %rdi (Month 1-12)
# Out : %rax (1-2)
# ------------------------------------------------------------------------------
.globl semester
.type semester, @function
semester:
    .cfi_startproc
    movq    %rdi, %rax
    incq    %rax
    shrq    $3, %rax
    incq    %rax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# easter_shifted_month
# In  : %rdi (Month 1-12)
# Out : %rax (Shifted result)
# ------------------------------------------------------------------------------
.globl easter_shifted_month
.type easter_shifted_month, @function
easter_shifted_month:
    .cfi_startproc
    movq    %rdi, %rax
    andq    $0xF, %rax
    subw    $3, %ax
    andw    $0xF40F, %ax
    notb    %ah
    andb    %ah, %al
    incb    %al
    andq    $0xF, %rax
    ret
    .cfi_endproc

# ------------------------------------------------------------------------------
# trimester
# In  : %rdi (Month 1-12)
# Out : %rax (1-3)
# ------------------------------------------------------------------------------
.globl trimester
.type trimester, @function
trimester:
    .cfi_startproc
    movq    %rdi, %rax
    decq    %rax
    shrq    $2, %rax
    incq    %rax
    ret
    .cfi_endproc

.section .note.GNU-stack,"",@progbits