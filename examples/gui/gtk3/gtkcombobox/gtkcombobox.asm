; ==============================================================================
; Name        : gtkcombobox.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkComboBoxText example displaying selected text inside a label
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
     allocated_str:    resq      1

section .data
     logo:             incbin    "../resources/pictures/logo.png"
     logo_size:        equ       $ - logo

     window:
     .handle:          dq        0
     .title:           db        "GtkComboBox", 0

     signal:
     .destroy:         db        "destroy", 0
     .changed:         db        "changed", 0

     combobox:
     .handle:          dq        0
     .txt1:            db        "Ubuntu", 0
     .txt2:            db        "Mandriva", 0
     .txt3:            db        "Fedora", 0
     .txt4:            db        "Mint", 0
     .txt5:            db        "Gentoo", 0
     .txt6:            db        "Debian", 0

     label:
     .handle:          dq        0
     .caption:         db        "here comes your choice", 0

     fixed:
     .handle:          dq        0
     
     loader:           dq        0
     pixbuffer:        dq        0

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

     ; 2. Generate Pixbuf from Embedded Asset in RAM
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

     ; 3. Build and Configure Window Layout
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, qword [window.handle]
     mov        rsi, 500
     mov        rdx, 300
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     ; Connect Window Destroy Signal
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     ; Create Fixed Container Layout
     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     ; Create ComboBoxText Component
     call       gtk_combo_box_text_new
     mov        qword [combobox.handle], rax

     ; Populate Rows
     mov        rdi, qword [combobox.handle]
     mov        rsi, combobox.txt1
     call       gtk_combo_box_text_append_text
     mov        rdi, qword [combobox.handle]
     mov        rsi, combobox.txt2
     call       gtk_combo_box_text_append_text
     mov        rdi, qword [combobox.handle]
     mov        rsi, combobox.txt3
     call       gtk_combo_box_text_append_text
     mov        rdi, qword [combobox.handle]
     mov        rsi, combobox.txt4
     call       gtk_combo_box_text_append_text
     mov        rdi, qword [combobox.handle]
     mov        rsi, combobox.txt5
     call       gtk_combo_box_text_append_text
     mov        rdi, qword [combobox.handle]
     mov        rsi, combobox.txt6
     call       gtk_combo_box_text_append_text

     ; Pack Components
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [combobox.handle]
     mov        rdx, 50
     mov        rcx, 50
     call       gtk_fixed_put

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     mov        rdi, label.caption
     call       gtk_label_new
     mov        qword [label.handle], rax

     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [label.handle]
     mov        rdx, 50
     mov        rcx, 110
     call       gtk_fixed_put

     ; Connect Changed Signal
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [label.handle]
     mov        rdx, combo_select
     mov        rsi, signal.changed
     mov        rdi, qword [combobox.handle]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit

; -------------------------------------------------------------------------
; Callback: combo_select
; -------------------------------------------------------------------------
combo_select:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        qword [target_label], rsi
     call       gtk_combo_box_text_get_active_text
     mov        qword [allocated_str], rax

     mov        rdi, qword [target_label]
     mov        rsi, qword [allocated_str]
     call       gtk_label_set_text

     mov        rdi, qword [allocated_str]
     call       g_free

     leave
     ret
