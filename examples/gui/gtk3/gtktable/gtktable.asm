; ==============================================================================
; Name        : gtktable.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Grid layout using working stack-alignment
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
     table:
     .handle:          resq      1
     button:
     .handle:          resq      1
     buffer:           resb      2

section .data
     window.title:     db        "GtkTable", 0
     signal:
     .destroy:         db        "destroy", 0
     values:           db        "789/456*123-0.=+"
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
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, qword [window.handle]
     mov        rsi, 250
     mov        rdx, 180
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, 5
     call       gtk_container_set_border_width

     mov        rdi, 4
     mov        rsi, 4
     mov        rdx, TRUE
     call       gtk_table_new
     mov        qword [table.handle], rax

     mov        rdi, qword [table.handle]
     mov        rsi, 2
     call       gtk_table_set_row_spacings
     mov        rdi, qword [table.handle]
     mov        rsi, 2
     call       gtk_table_set_col_spacings

     ; Loop to create grid
     xor        rbx, rbx
.loop:
     mov        al, [values + rbx]
     mov        [buffer], al
     mov        rdi, buffer
     call       gtk_button_new_with_label
     mov        qword [button.handle], rax

     mov        rax, rbx
     xor        rdx, rdx
     mov        rcx, 4
     div        rcx

     mov        rdi, qword [table.handle]
     mov        rsi, qword [button.handle]
     mov        r8, rax                 ; top_attach
     mov        r9, rax
     inc        r9                      ; bottom_attach
     mov        rdx, rdx                ; left_attach (rdx from div)
     mov        rcx, rdx
     inc        rcx                     ; right_attach

     push       r9
     push       r8
     call       gtk_table_attach_defaults
     add        rsp, 16

     inc        rbx
     cmp        rbx, 16
     jl         .loop

     mov        rdi, qword [window.handle]
     mov        rsi, qword [table.handle]
     call       gtk_container_add

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
