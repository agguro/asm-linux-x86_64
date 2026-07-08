; ==============================================================================
; Name        : centeredwindow.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Derived From: ZetCode GTK3 Examples
; Description : A simple window with the basic functionalities and a title, 
;               centered on screen
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

bits 64

[list -]
     %include "gtk3/defines.inc"
     %include "gtk3/gtk.inc"
     %include "gtk3/g.inc"
     %include "gtk3/gdk.inc"
     %include "gtk3/gobject.inc"
     %include "c/defines.inc"
     %include "c/c.inc"
[list +]

section .data
    window:
    .handle:    dq    0
    .title:     db    "A centered window",0

    signal:
    .destroy:   db    "destroy",0

section .text
    global _start

_start:
    ; 1. Stack Alignment & GTK3 Init
    mov         rdi, [rsp]                ; argc
    lea         rsi, [rsp + 8]            ; argv

    mov         r12, rdi                  ; Back-up argc
    mov         r13, rsi                  ; Back-up argv

    and         rsp, -16                  ; Enforce 16-byte alignment
    sub         rsp, 16                   ; Reserved space

    lea         rdi, [rsp]                ; Move &argc to stack
    mov         [rdi], r12
    lea         rsi, [rsp + 8]            ; Move &argv to stack
    mov         [rsi], r13

    call        gtk_init

    ; 2. Build and Configure Window
    mov         rdi, GTK_WINDOW_TOPLEVEL
    call        gtk_window_new
    mov         qword [window.handle], rax

    ; Set Window Properties
    mov         rdi, qword [window.handle]
    mov         rsi, window.title
    call        gtk_window_set_title

    mov         rdi, qword [window.handle]
    mov         rsi, 230
    mov         rdx, 150
    call        gtk_window_set_default_size

    mov         rdi, qword [window.handle]
    mov         rsi, GTK_WIN_POS_CENTER
    call        gtk_window_set_position

    ; 3. Signals & Event Loop
    xor         r9d, r9d                  ; GConnectFlags = 0
    xor         r8d, r8d                  ; GClosureNotify = NULL
    xor         rcx, rcx                  ; user_data = NULL
    mov         rdx, gtk_main_quit        ; Pointer to the callback handler
    mov         rsi, signal.destroy       ; Pointer to the signal string
    mov         rdi, qword [window.handle]; Pointer to the widget instance
    call        g_signal_connect_data

    ; Show main window instance
    mov         rdi, qword [window.handle]
    call        gtk_widget_show

    call        gtk_main

.L_exit:
    xor         rdi, rdi                  ; Exit code = 0
    call        exit
