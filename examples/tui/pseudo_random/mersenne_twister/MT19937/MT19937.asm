;name: MT19937-32.asm
;description: Mersenne twister algorithm to generate 32 bits unsigned integers.
;build: nasm -felf64 MT19937-32.asm -o MT19937-32.o
;       ld -melf_x86_64 -o MT19937-32 MT19937-32.o

bits 64

[list -]
    %include "unistd.inc"
    %include "sys/time.inc"
[list +]

; --- Constants for MT19937-32 ---
%define NUMBER          1000000
%define INIT_MULTIPLIER 0x6c078965      ; 1812433253
%define TEMPERING_MASK_B 0x9D2C5680     ; 2636928640
%define TEMPERING_MASK_C 0xEFC60000     ; 4022730752
%define STATE_ARRAY_SIZE 624
%define MATRIX_A_32     0x9908B0DF      ; 2567483615

;macro to build strings
%macro STRING 2
  %1:
    .start:  db %2
    .end:
    .len: equ %1.end-%1.start
%endmacro

section .bss
    index:
    .start:  resw 1
    .end:
    .len: equ index.end-index.start
    MT:
    .start:  resd STATE_ARRAY_SIZE
    .end:
    .len: equ MT.end-MT.start
    decimalbuffer:
    .start:  resb 20
    .end:
    .len: equ decimalbuffer.end-decimalbuffer.start
    testdata:
    .start:  resd NUMBER
    .end:
    .len: equ testdata.end-testdata.start

section .rodata
    sTitle:
    .start:  db "Implementation of the 32 bits Mersenne Twister.",10,"by Agguro - 2013",10
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
    stosd
    loop      .next
    call      GetTime
    mov       qword[endtime.tv_sec],rdx
    mov       qword[endtime.tv_nsec],rax
    mov       rsi,testdata
    mov       rcx,NUMBER
.nextNumber:
    xor       rax,rax
    lodsd
    push      rsi
    call      ConvertToDecimal
    push      rcx
    push      rsi
    push      rdx
    mov       rcx,rdx
    sub       rcx,12
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
.done:
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
    mov     word[index],0
    cmp     rdi,0
    jne     .start
    call    GenerateSeed
    .start:
    mov     rdi,MT
    mov     ecx,1
    stosd
    mov     rsi,rdi
    sub     rsi,4
    .nexti:
    push    rax
    shr     eax,30
    mov     ebx,eax
    pop     rax
    xor     eax,ebx
    mov     ebx,INIT_MULTIPLIER
    xor     rdx,rdx
    imul    ebx
    add     eax,ecx
    stosd
    inc     ecx
    cmp     ecx,STATE_ARRAY_SIZE-1
    jle     .nexti
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
    mov     rsi,MT
    mov     ebx,ecx
    shl     ebx,2
    mov     eax,dword[rsi+rbx]
    and     eax,0x80000000
    push    rax
    mov     eax,ecx
    inc     eax
    mov     ebx,STATE_ARRAY_SIZE
    xor     rdx,rdx
    idiv    ebx
    mov     ebx,edx
    shl     ebx,2
    mov     eax,dword[rsi+rbx]
    and     eax,0x7FFFFFFF
    pop     rbx
    add     eax,ebx
    push    rax
    shr     eax,1
    push    rax
    mov     eax,ecx
    add     eax,397
    mov     ebx,STATE_ARRAY_SIZE
    xor     rdx,rdx
    idiv    ebx
    mov     ebx,edx
    shl     ebx,2
    mov     eax,dword[rsi+rbx]
    pop     rbx
    xor     eax,ebx
    mov     ebx,ecx
    shl     ebx,2
    and     eax,0x7FFFFFFF
    mov     DWORD[rsi+rbx],eax
    pop     rax
    rcr     eax,1
    jnc     .done
    mov     eax,dword[rsi+rbx]
    xor     eax,MATRIX_A_32
    and     eax,0x7FFFFFFF
    mov     DWORD[rsi+rbx],eax
  .done:
    inc     rcx
    cmp     rcx,STATE_ARRAY_SIZE
    jne     .repeat
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

ExtractNumber:
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    xor     rax,rax
    mov     ax,word[index]
    push    rax
    inc     eax
    mov     ebx,STATE_ARRAY_SIZE
    xor     rdx,rdx
    idiv    ebx
    mov     word[index],dx
    pop     rbx
    cmp     ebx,0
    jne     .getnumber
    push    rbx
    call    GenerateNumbers
    pop     rbx
.getnumber:
    mov     rsi,MT
    shl     rbx,2
    mov     dword eax,[rsi+rbx]
    mov     edx,eax
    shr     edx,11
    xor     eax,edx
    mov     edx,eax
    shl     edx,7
    and     edx,TEMPERING_MASK_B
    xor     eax,edx
    mov     edx,eax
    shl     edx,15
    and     edx,TEMPERING_MASK_C
    xor     eax,edx
    mov     edx,eax
    shr     edx,18
    xor     eax,edx
    and     eax,0x7FFFFFFF
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    ret

GenerateSeed:
    push    rbp
    mov     rbp,rsp
    sub     rsp,16
    mov     rax,SYS_CLOCK_GETTIME
    syscall clock_gettime,CLOCK_REALTIME,rsp
    mov     rax,[rsp]
    mov     rbx,[rsp+8]
    imul    rax,rbx
    shl     rax,32
    shr     rax,32
    mov     rsp,rbp
    pop     rbp
    ret

ConvertToDecimal:
    push    rdi
    push    rbx
    push    rdx
    test    rax, rax
    jnz     .setup_div
    mov     byte [decimalbuffer+19], '0'
    mov     rsi, decimalbuffer+19
    mov     rdx, 1
    jmp     .done
.setup_div:
    mov     rdi,decimalbuffer+19
    mov     rbx,10
.repeat:
    xor     rdx,rdx
    div     rbx
    add     dl,'0'
    mov     [rdi],dl
    dec     rdi
    test    rax,rax
    jnz     .repeat
    inc     rdi
    mov     rsi,rdi
    mov     rdx,decimalbuffer+20
    sub     rdx,rsi
.done:
    pop     rdx
    pop     rbx
    pop     rdi
    ret

GetTime:
    push    rsi
    push    rdi
    push    rcx
    push    rbp
    mov     rbp,rsp
    sub     rsp,16
    syscall clock_gettime,CLOCK_REALTIME,rsp
    mov     rdx,[rsp]
    mov     rax,[rsp+8]
    mov     rsp,rbp
    pop     rbp
    pop     rcx
    pop     rdi
    pop     rsi
    ret