; ==============================================================================
; Name        : move-event.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Observing and displaying window dimensions and positions
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

struc GdkEventConfigure
     .type:         resd      1
     .padding0:     resd      1
     .window:       resq      1
     .send_event:   resb      1
     .padding1:     resb      3
     .x:            resd      1
     .y:            resd      1
     .width:        resd      1
     .height:       resd      1
endstruc

section .data
     mainwindow:
     .handle:       dq        0
     .title:        db        "Simple", 0

     signal:
     .destroy:      db        "destroy", 0
     .configure:    db        "configure-event", 0

     message:
     .format:       db        "left: %d, top: %d, width: %d, height: %d", 0
     .buffer:       times 128 db 0

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

     ; 2. Build Window
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [mainwindow.handle], rax

     mov        rdi, qword [mainwindow.handle]
     mov        rsi, mainwindow.title
     call       gtk_window_set_title
     mov        rdi, qword [mainwindow.handle]
     mov        rsi, 500
     mov        rdx, 300
     call       gtk_window_set_default_size
     mov        rdi, qword [mainwindow.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [mainwindow.handle]
     mov        rsi, 1 << 1 ; GDK_STRUCTURE_MASK
     call       gtk_widget_add_events

     ; 3. Signal Connections
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [mainwindow.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, frame_callback
     mov        rsi, signal.configure
     mov        rdi, qword [mainwindow.handle]
     call       g_signal_connect_data

     mov        rdi, qword [mainwindow.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit

; Callback: frame_callback
frame_callback:
     push       r14
     push       r15
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        r15, rdi
     mov        r14, rsi

     mov        r9d, dword [r14 + GdkEventConfigure.height]
     mov        r8d, dword [r14 + GdkEventConfigure.width]
     mov        ecx, dword [r14 + GdkEventConfigure.y]
     mov        edx, dword [r14 + GdkEventConfigure.x]

     mov        rdi, message.buffer
     mov        rsi, message.format
     xor        rax, rax
     call       sprintf

     mov        rdi, r15
     mov        rsi, message.buffer
     call       gtk_window_set_title

     leave
     pop        r15
     pop        r14
     xor        rax, rax ; FALSE
     ret