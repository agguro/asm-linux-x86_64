; ==============================================================================
; Name        : inc-dec.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Three widgets example updating a shared counter
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

%define   WIDTH    250
%define   HEIGHT   150

section .bss
     window:
     .handle:          resq      1
     frame:
     .handle:          resq      1
     plusbutton:
     .handle:          resq      1
     minusbutton:
     .handle:          resq      1
     label:
     .handle:          resq      1
     buffer:           resb      32
     loader:           resq      1
     pixbuffer:        resq      1

section .data
     title:            db        "increase - decrease", 0
     iconfile:         db        "resources/pictures/logo.png", 0
     signal:
     .destroy:         db        "destroy", 0
     .clicked:         db        "clicked", 0
     plussign:         db        "+", 0
     minussign:        db        "-", 0
     count:            dq        0
     mask:             db        "%d", 0

section .text
     global _start

_start:
     ; 1. Stack Alignment conform System V AMD64 ABI
     mov        rdi, [rsp]
     lea        rsi, [rsp + 8]
     mov        r12, rdi
     mov        r13, rsi

     and        rsp, -16
     sub        rsp, 16
     lea        rdi, [rsp]
     mov        [rdi], r12
     lea        rsi, [rsp + 8]
     mov        [rsi], r13

     call       gtk_init

     ; 2. Configure Window Frame
     mov        rdi, iconfile
     call       gdk_pixbuf_new_from_file
     mov        qword [pixbuffer], rax

     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, title
     call       gtk_window_set_title
     mov        rdi, qword [window.handle]
     mov        rsi, WIDTH
     mov        rdx, HEIGHT
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     call       gtk_fixed_new
     mov        qword [frame.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [frame.handle]
     call       gtk_container_add

     ; 3. Instantiate Control Buttons & Label
     mov        rdi, plussign
     call       gtk_button_new_with_label
     mov        qword [plusbutton.handle], rax
     mov        rdi, qword [plusbutton.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request
     mov        rdi, qword [frame.handle]
     mov        rsi, qword [plusbutton.handle]
     mov        rdx, 50
     mov        rcx, 20
     call       gtk_fixed_put

     mov        rdi, minussign
     call       gtk_button_new_with_label
     mov        qword [minusbutton.handle], rax
     mov        rdi, qword [minusbutton.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request
     mov        rdi, qword [frame.handle]
     mov        rsi, qword [minusbutton.handle]
     mov        rdx, 50
     mov        rcx, 80
     call       gtk_fixed_put

     mov        rdi, buffer
     mov        rsi, mask
     mov        rdx, qword [count]
     xor        rax, rax
     call       sprintf

     xor        rdi, rdi
     call       gtk_label_new
     mov        qword [label.handle], rax
     mov        rdi, qword [label.handle]
     mov        rsi, buffer
     call       gtk_label_set_text
     mov        rdi, qword [frame.handle]
     mov        rsi, qword [label.handle]
     mov        rdx, 190
     mov        rcx, 58
     call       gtk_fixed_put

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all

     ; 4. Signal Connections
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, Increase
     mov        rsi, signal.clicked
     mov        rdi, qword [plusbutton.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, Decrease
     mov        rsi, signal.clicked
     mov        rdi, qword [minusbutton.handle]
     call       g_signal_connect_data

     call       gtk_main
     xor        rdi, rdi
     call       exit

Increase:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     inc        qword [count]
     mov        rdi, buffer
     mov        rsi, mask
     mov        rdx, qword [count]
     xor        rax, rax
     call       sprintf
     mov        rdi, qword [label.handle]
     mov        rsi, buffer
     call       gtk_label_set_text
     leave
     ret

Decrease:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     dec        qword [count]
     mov        rdi, buffer
     mov        rsi, mask
     mov        rdx, qword [count]
     xor        rax, rax
     call       sprintf
     mov        rdi, qword [label.handle]
     mov        rsi, buffer
     call       gtk_label_set_text
     leave
     ret
