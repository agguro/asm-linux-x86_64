; ==============================================================================
; Name        : eventssignals.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Events and signals introduction wrapper
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
     .handle:       dq   0
     .title:        db   "GtkButton", 0

     fixed:
     .handle:       dq   0

     button:
     .handle:       dq   0
     .label:        db   "Click", 0

     signal:
     .clicked:      db   "clicked", 0
     .destroy:      db   "destroy", 0

     message:
     .clicked:      db   "Clicked", 10, 0

section .text
     global _start

_start:
     ; -------------------------------------------------------------------------
     ; 1. Retrieve argc/argv and enforce System V AMD64 ABI Stack Alignment
     ; -------------------------------------------------------------------------
     mov        rdi, [rsp]                ; argc
     lea        rsi, [rsp + 8]            ; argv

     mov        r12, rdi                  ; Back-up argc
     mov        r13, rsi                  ; Back-up argv

     and        rsp, -16                  ; Enforce 16-byte alignment
     sub        rsp, 16                   ; Reserved space for &argc and &argv

     lea        rdi, [rsp]                ; Move &argc to stack
     mov        [rdi], r12
     lea        rsi, [rsp + 8]            ; Move &argv to stack
     mov        [rsi], r13

     call       gtk_init

     ; -------------------------------------------------------------------------
     ; 2. Build and Configure Window Layout
     ; -------------------------------------------------------------------------
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, qword [window.handle]
     mov        rsi, 230
     mov        rdx, 150
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     ; Create Fixed Container
     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     ; Create Button
     mov        rdi, button.label
     call       gtk_button_new_with_label
     mov        qword [button.handle], rax

     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button.handle]
     mov        rdx, 50
     mov        rcx, 50
     call       gtk_fixed_put

     mov        rdi, qword [button.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request

     ; -------------------------------------------------------------------------
     ; 3. Signal Connections & Main Loop
     ; -------------------------------------------------------------------------
     xor        r9d, r9d                  ; GConnectFlags = 0
     xor        r8d, r8d                  ; GClosureNotify = NULL
     xor        rcx, rcx                  ; user_data = NULL
     mov        rdx, button_clicked
     mov        rsi, signal.clicked
     mov        rdi, qword [button.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all

     call       gtk_main

     xor        rdi, rdi                  ; Exit code = 0
     call       exit

; -------------------------------------------------------------------------
; Callback: button_clicked
; -------------------------------------------------------------------------
button_clicked:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16                  ; Enforce 16-byte stack alignment

     mov        rdi, message.clicked
     xor        rax, rax
     call       g_print

     leave
     ret
