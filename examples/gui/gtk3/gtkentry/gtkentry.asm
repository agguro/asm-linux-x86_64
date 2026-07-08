; ==============================================================================
; Name        : gtkentry.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkEntry with real-time preview label updates
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
     target_label:     resq      1

section .data
     logo:             incbin    "../resources/pictures/logo.png"
     logo_size:        equ       $ - logo

     window:
     .handle:          dq        0
     .title:           db        "GtkEntry", 0

     signal:
     .destroy:         db        "destroy", 0
     .clicked:         db        "clicked", 0
     .changed:         db        "changed", 0

     vbox:
     .handle:          dq        0

     hbox:
     .handle:          dq        0

     name_label:
     .handle:          dq        0
     .text:            db        "Name: ", 0

     entry:
     .handle:          dq        0

     button_ok:
     .handle:          dq        0
     .text:            db        "OK", 0

     label_out:
     .handle:          dq        0
     .text:            db        "(Your text will appear here)", 0

     loader:           dq        0
     pixbuffer:        dq        0

section .text
     global _start

_start:
     ; 1. Stack Alignment & GTK3 Init
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

     ; 2. Generate Pixbuf
     call       gdk_pixbuf_loader_new
     mov        qword [loader], rax
     mov        rdi, qword [loader]
     mov        rsi, logo
     mov        edx, logo_size
     xor        rcx, rcx
     call       gdk_pixbuf_loader_write
     mov        rdi, qword [loader]
     call       gdk_pixbuf_loader_get_pixbuf
     mov        qword [pixbuffer], rax

     ; 3. Build Window
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title
     mov        rdi, qword [window.handle]
     mov        rsi, 400
     mov        rdx, 150
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon
     
     mov        rdi, qword [window.handle]
     mov        rsi, 15
     call       gtk_container_set_border_width

     ; 4. Build Containers
     mov        rdi, GTK_ORIENTATION_VERTICAL
     mov        rsi, 15
     call       gtk_box_new
     mov        qword [vbox.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [vbox.handle]
     call       gtk_container_add

     mov        rdi, GTK_ORIENTATION_HORIZONTAL
     mov        rsi, 8
     call       gtk_box_new
     mov        qword [hbox.handle], rax

     ; 5. Instantiate Widgets
     mov        rdi, name_label.text
     call       gtk_label_new
     mov        qword [name_label.handle], rax

     call       gtk_entry_new
     mov        qword [entry.handle], rax

     mov        rdi, button_ok.text
     call       gtk_button_new_with_label
     mov        qword [button_ok.handle], rax

     ; Pack HBox
     mov        rdi, qword [hbox.handle]
     mov        rsi, qword [name_label.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, qword [hbox.handle]
     mov        rsi, qword [entry.handle]
     mov        rdx, TRUE
     mov        rcx, TRUE
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, qword [hbox.handle]
     mov        rsi, qword [button_ok.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, qword [vbox.handle]
     mov        rsi, qword [hbox.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, label_out.text
     call       gtk_label_new
     mov        qword [label_out.handle], rax
     mov        rdi, qword [vbox.handle]
     mov        rsi, qword [label_out.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     mov        r8d, 10
     call       gtk_box_pack_start

     ; 6. Signal Connections
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [label_out.handle]
     mov        rdx, on_entry_changed
     mov        rsi, signal.changed
     mov        rdi, qword [entry.handle]
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
     call       exit

; Callback: on_entry_changed (Live update)
on_entry_changed:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     
     mov        qword [target_label], rsi
     mov        rdi, qword [entry.handle]
     call       gtk_entry_get_text
     
     mov        rdi, qword [target_label]
     mov        rsi, rax
     call       gtk_label_set_text
     
     leave
     ret
