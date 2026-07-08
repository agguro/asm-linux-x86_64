; ==============================================================================
; Name        : gtkfixed.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Layout management example using a fixed coordinate positioning container
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
     .handle:         dq        0
     .title:          db        "gtkfixed", 0

     button1:
     .handle:         dq        0
     .label:          db        "button1", 0

     button2:
     .handle:         dq        0
     .label:          db        "button2", 0

     button3:
     .handle:         dq        0
     .label:          db        "button3", 0

     fixed:
     .handle:         dq        0

     signal:
     .destroy:        db        "destroy", 0

section .text
     global _start

_start:
     ; 1. Stack Alignment conform System V AMD64 ABI
     mov        rdi, [rsp]                ; argc
     lea        rsi, [rsp + 8]            ; argv
     mov        r12, rdi
     mov        r13, rsi

     and        rsp, -16
     sub        rsp, 16
     lea        rdi, [rsp]
     mov        [rdi], r12
     lea        rsi, [rsp + 8]
     mov        [rsi], r13

     call       gtk_init

     ; 2. Window Construction
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, qword [window.handle]
     mov        rsi, 290
     mov        rdx, 200
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     ; Create Fixed Layout Container
     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     ; 3. Instantiate Buttons
     mov        rdi, button1.label
     call       gtk_button_new_with_label
     mov        qword [button1.handle], rax

     mov        rdi, button2.label
     call       gtk_button_new_with_label
     mov        qword [button2.handle], rax

     mov        rdi, button3.label
     call       gtk_button_new_with_label
     mov        qword [button3.handle], rax

     ; Pack button1 into layout grid at (150, 50)
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button1.handle]
     mov        rdx, 150
     mov        rcx, 50
     call       gtk_fixed_put

     ; Pack button2 into layout grid at (15, 15)
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button2.handle]
     mov        rdx, 15
     mov        rcx, 15
     call       gtk_fixed_put

     ; Pack button3 into layout grid at (100, 100)
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button3.handle]
     mov        rdx, 100
     mov        rcx, 100
     call       gtk_fixed_put

     ; Apply sizing
     mov        rdi, qword [button1.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request

     mov        rdi, qword [button2.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request

     mov        rdi, qword [button3.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request

     ; 4. Signal Connections & Main Loop
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

     xor        rdi, rdi
     call       exit