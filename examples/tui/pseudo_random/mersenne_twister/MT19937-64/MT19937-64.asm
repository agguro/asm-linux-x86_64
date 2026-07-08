;name: MT19937-64.asm
bits 64

%include "unistd.inc"
%include "sys/time.inc"

%define NUMBER   1000000
%define MT_SIZE  312
%define M_OFFSET 156
%define INIT_MULTIPLIER 6364136223846793005
%define MATRIX_A 0xB5026F5AA96619E9
%define MASK_B   0x71D67FFFEDA60000
%define MASK_C   0xFFF7EEE000000000

section .bss
    index:
    .start:  resq 1
    .end:
    .len: equ index.end-index.start
    MT:
    .start:  resq MT_SIZE
    .end:
    .len: equ MT.end-MT.start
    decimalbuffer:
    .start:  resb 32
    .end:
    .len: equ decimalbuffer.end-decimalbuffer.start
    testdata:
    .start:  resq NUMBER
    .end:
    .len: equ testdata.end-testdata.start

section .rodata
    sTitle:
    .start:  db "Implementation of the 64 bits Mersenne Twister.",10,"by Agguro - Adapted",10
    .end:
    .len: equ sTitle.end-sTitle.start
    sEOL:
    .start:  db 10
    .end:
    .len: equ sEOL.end-sEOL.start
    sSeparator:
    .start:  db ","
    .end:
    .len: equ sSeparator.end-sSeparator.start
    sSpace:
    .start:  db " "
    .end:
    .len: equ sSpace.end-sSpace.start
    sPeriod:
    .start:  db "."
    .end:
    .len: equ sPeriod.end-sPeriod.start
    sSec:
    .start:  db "s"
    .end:
    .len: equ sSec.end-sSec.start
    sExecTime:
    .start:  db "Execution time to generate and store 1000000 integers: "
    .end:
    .len: equ sExecTime.end-sExecTime.start

section .data
    TIMESPEC starttime
    TIMESPEC endtime
    zero dq 0
 
section .text
global _start
_start:
    mov       rsi,sTitle
    mov       rdx,sTitle.len
    call      Write
    xor       rdi,rdi
    call      Initialize
    mov       rcx,NUMBER
    mov       rdi,testdata
    call      GetTime
    mov       qword[starttime.tv_sec],rdx
    mov       qword[starttime.tv_nsec],rax
.next:
    push      rdi
    call      ExtractNumber
    pop       rdi
    stosq
    loop      .next
    call      GetTime
    mov       qword[endtime.tv_sec],rdx
    mov       qword[endtime.tv_nsec],rax
    mov       rsi,testdata
    mov       rcx,NUMBER
.nextNumber:
    mov       rax,[rsi]
    add       rsi,8
    push      rsi
    call      ConvertToDecimal
    push      rcx
    push      rsi
    push      rdx
    mov       rcx,rdx
    sub       rcx,20
    jz        .noalignment
    neg       rcx
.space:
    mov       rsi,sSpace
    call      WriteChar
    loop      .space
.noalignment:
    pop       rdx
    pop       rsi
    pop       rcx
    call      Write
    mov       rax,rcx
    dec       rax
    mov       rbx,10
    xor       rdx,rdx
    idiv      rbx
    cmp       rdx,0
    jne       .sameline
    mov       rsi,sEOL
    jmp       .printchar
.sameline:
    mov       rsi,sSeparator
.printchar:
    call      WriteChar
    pop       rsi
    loop      .nextNumber
    mov       rsi,sEOL
    mov       rdx,1
    call      Write
    mov       rsi,sExecTime
    mov       rdx,sExecTime.len
    call      Write
    mov       rax,qword[endtime.tv_nsec]
    sub       rax,qword[starttime.tv_nsec]
    cmp       rax,0
    jge       .calculate
    neg       rax
    sub       qword[endtime.tv_sec],1
.calculate:
    push      rax
    mov       rax,qword[endtime.tv_sec]
    sub       rax,qword[starttime.tv_sec]
    call      ConvertToDecimal
    call      Write
    mov       rsi,sPeriod
    mov       rdx,1
    call      Write
    pop       rax
    call      ConvertToDecimal
    cmp       rdx,9
    je        .noleadingzero
    mov       rcx,9
    sub       rcx,rdx
.leadingzero:
    dec       rsi
    inc       rdx
    mov       byte[rsi],"0"
    loop      .leadingzero
.noleadingzero:
    call      Write
    mov       rsi,sSec
    mov       rdx,1
    call      Write
    mov       rsi,sEOL
    mov       rdx,1
    call      Write
    syscall   exit,0

Write:
    push      rax
    push      rcx
    push      rdi
    syscall   write,stdout
    pop       rdi
    pop       rcx
    pop       rax
    ret

WriteChar:
    push      rdx
    mov       rdx,1
    call      Write
    pop       rdx
    ret

Initialize:
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rdi
    push    rsi
    mov     qword[index],MT_SIZE
    cmp     rdi,0
    jne     .start
    call    GenerateSeed
    .start:
    mov     [MT],rax
    mov     rcx,1
    .nexti:
    mov     rax,[MT+rcx*8-8]
    mov     rdx,rax
    shr     rdx,62
    xor     rax,rdx
    mov     rbx,INIT_MULTIPLIER
    mul     rbx
    add     rax,rcx
    mov     [MT+rcx*8],rax
    inc     rcx
    cmp     rcx,MT_SIZE
    jl      .nexti
    call    GenerateNumbers
    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

GenerateNumbers:
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    xor     rcx,rcx
  .repeat:
    mov     rax,[MT+rcx*8]
    and     rax,0xFFFFFFFF80000000
    mov     rbx,rcx
    inc     rbx
    cmp     rbx,MT_SIZE
    jl      .no_mod_i1
    xor     rbx,rbx
.no_mod_i1:
    mov     rdx,[MT+rbx*8]
    and     rdx,0x000000007FFFFFFF
    or      rax,rdx
    shr     rax,1
    test    dl,1
    jz      .no_matrix
    mov     rdx,MATRIX_A
    xor     rax,rdx
.no_matrix:
    mov     rbx,rcx
    add     rbx,M_OFFSET
    cmp     rbx,MT_SIZE
    jl      .no_mod_im
    sub     rbx,MT_SIZE
.no_mod_im:
    xor     rax,[MT+rbx*8]
    mov     [MT+rcx*8],rax
    inc     rcx
    cmp     rcx,MT_SIZE
    jl      .repeat
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

ExtractNumber:
    mov     rax,[index]
    cmp     rax,MT_SIZE
    jl      .getnumber
    call    GenerateNumbers
    mov     rax,0
.getnumber:
    mov     rbx,[MT+rax*8]
    inc     rax
    mov     [index],rax
    mov     rax,rbx
    shr     rbx,29
    mov     rdx,0x5555555555555555
    and     rbx,rdx
    xor     rax,rbx
    mov     rbx,rax
    shl     rbx,17
    mov     rdx,MASK_B
    and     rbx,rdx
    xor     rax,rbx
    mov     rbx,rax
    shl     rbx,37
    mov     rdx,MASK_C
    and     rbx,rdx
    xor     rax,rbx
    mov     rbx,rax
    shr     rbx,43
    xor     rax,rbx
    ret

GenerateSeed:
    sub     rsp,16
    syscall clock_gettime,CLOCK_REALTIME,rsp
    mov     rax,[rsp]
    mov     rbx,[rsp+8]
    imul    rax,rbx
    add     rsp,16
    ret

ConvertToDecimal:
    push    rdi
    push    rbx
    push    rax         ; Save original RAX
    
    ; --- Check for zero ---
    test    rax, rax
    jnz     .setup_div
    mov     byte [decimalbuffer+25], '0'
    mov     rsi, decimalbuffer+25
    mov     rdx, 1
    jmp     .done

.setup_div:
    mov     rdi, decimalbuffer + 25 ; Start further up in the 32-byte buffer
    mov     rbx, 10
.repeat:
    xor     rdx, rdx
    div     rbx
    add     dl, '0'
    mov     [rdi], dl
    dec     rdi
    test    rax, rax
    jnz     .repeat
    
    ; Resulting string starts at rdi + 1
    inc     rdi
    mov     rsi, rdi
    mov     rdx, decimalbuffer + 26
    sub     rdx, rsi

.done:
    pop     rax         ; Restore original RAX (not strictly needed, but clean)
    pop     rbx
    pop     rdi
    ret

;GetTime
;This subroutine returns the time in RDX:RAX
;IN  : none
;OUT : RDX = seconds
;      RAX = nanoseconds

GetTime:
    push    rsi
    push    rdi
    push    rcx
    sub     rsp, 16             ; Reserve 16 bytes of local scratch space
    
    ; Pass the address of the reserved space to the syscall
    mov     rdi, CLOCK_REALTIME
    mov     rsi, rsp            ; RSI now points to our 16 bytes of scratch space
    mov     rax, SYS_CLOCK_GETTIME
    syscall
    
    mov     rdx, [rsp]          ; Get seconds
    mov     rax, [rsp+8]        ; Get nanoseconds
    
    add     rsp, 16             ; Clean up the scratch space
    pop     rcx
    pop     rdi
    pop     rsi
    ret