; ==============================================================================
; Name        : gtkstatusbar.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Statusbar example with dynamic message pushing
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

section .bss
     window:
     .handle:          resq      1
     vbox:
     .handle:          resq      1
     fixed:
     .handle:          resq      1
     statusbar:
     .handle:          resq      1
     .context_id:      resq      1
     button1:
     .handle:          resq      1
     button2:
     .handle:          resq      1
     loader:           resq      1
     pixbuffer:        resq      1
     msg_buffer:       resb      256

section .data
     logo:             incbin    "../resources/pictures/logo.png"
     logo_size:        equ       $ - logo

     window.title:     db        "GtkStatusbar", 0
     signal:
     .destroy:         db        "destroy", 0
     .clicked:         db        "clicked", 0
     button1.caption:  db        "OK", 0
     button2.caption:  db        "APPLY", 0
     statusbar.context:db        "click_context", 0
     statusbar.fmt:    db        "Button %s clicked", 0
     lang:
     .var:             db        "LANG", 0
     .val:             db        "C", 0

section .text
     global _start

_start:
     ; 1. Stack Setup & Locale Hack
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

     push       rdi
     push       rsi
     mov        rdi, lang.var
     mov        rsi, lang.val
     mov        rdx, 1
     call       setenv
     pop        rsi
     pop        rdi

     call       gtk_init

     ; 2. UI Setup
     call       gdk_pixbuf_loader_new
     mov        qword [loader], rax
     mov        rdi, rax
     mov        rsi, logo
     mov        rdx, logo_size
     xor        rcx, rcx
     call       gdk_pixbuf_loader_write
     mov        rdi, qword [loader]
     call       gdk_pixbuf_loader_get_pixbuf
     mov        qword [pixbuffer], rax

     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax
     mov        rdi, rax
     mov        rsi, window.title
     call       gtk_window_set_title
     mov        rdi, qword [window.handle]
     mov        rsi, 280
     mov        rdx, 150
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     mov        rdi, GTK_ORIENTATION_VERTICAL
     mov        rsi, 2
     call       gtk_box_new
     mov        qword [vbox.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [vbox.handle]
     call       gtk_container_add

     call       gtk_fixed_new
     mov        qword [fixed.handle], rax
     mov        rdi, qword [vbox.handle]
     mov        rsi, qword [fixed.handle]
     mov        rdx, TRUE
     mov        rcx, TRUE
     mov        r8d, 1
     call       gtk_box_pack_start

     call       gtk_statusbar_new
     mov        qword [statusbar.handle], rax
     mov        rdi, rax
     mov        rsi, statusbar.context
     call       gtk_statusbar_get_context_id
     mov        qword [statusbar.context_id], rax

     mov        rdi, qword [vbox.handle]
     mov        rsi, qword [statusbar.handle]
     mov        rdx, FALSE
     mov        rcx, TRUE
     mov        r8d, 1
     call       gtk_box_pack_start

     ; Buttons
     mov        rdi, button1.caption
     call       gtk_button_new_with_label
     mov        qword [button1.handle], rax
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button1.handle]
     mov        rdx, 50
     mov        rcx, 50
     call       gtk_fixed_put
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [statusbar.handle]
     mov        rdx, button_pressed
     mov        rsi, signal.clicked
     mov        rdi, qword [button1.handle]
     call       g_signal_connect_data

     mov        rdi, button2.caption
     call       gtk_button_new_with_label
     mov        qword [button2.handle], rax
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button2.handle]
     mov        rdx, 150
     mov        rcx, 50
     call       gtk_fixed_put
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [statusbar.handle]
     mov        rdx, button_pressed
     mov        rsi, signal.clicked
     mov        rdi, qword [button2.handle]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main
     call       exit

button_pressed:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     push       r12
     push       r13
     mov        r12, rdi
     mov        r13, rdx
     call       gtk_button_get_label
     mov        rdi, msg_buffer
     mov        rsi, 256
     mov        rdx, statusbar.fmt
     mov        rcx, rax
     xor        eax, eax
     call       snprintf
     mov        rdi, r13
     mov        rsi, [statusbar.context_id]
     mov        rdx, msg_buffer
     call       gtk_statusbar_push
     pop        r13
     pop        r12
     mov        rsp, rbp
     pop        rbp
     ret
