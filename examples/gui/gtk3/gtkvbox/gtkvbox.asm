; ==============================================================================
; Name        : gtkvbox.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkBox layout management with dynamic window title updates
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
     .handle:          dq        0
     .title:           db        "GtkVBox", 0

     vbox:
     .handle:          dq        0

     settings:
     .handle:          dq        0
     .label:           db        "Settings", 0

     accounts:
     .handle:          dq        0
     .label:           db        "Accounts", 0

     loans:
     .handle:          dq        0
     .label:           db        "Loans", 0

     cash:
     .handle:          dq        0
     .label:           db        "Cash", 0

     debts:
     .handle:          dq        0
     .label:           db        "Debts", 0

     signal:
     .destroy:         db        "destroy", 0
     .clicked:         db        "clicked", 0

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

     ; 2. Window Construction
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title
     mov        rdi, qword [window.handle]
     mov        rsi, 230
     mov        rdx, 250
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, 5
     call       gtk_container_set_border_width

     mov        rdi, GTK_ORIENTATION_VERTICAL
     mov        rsi, 1
     call       gtk_box_new
     mov        qword [vbox.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [vbox.handle]
     call       gtk_container_add

     ; 3. Instantiate Buttons
     mov        rdi, settings.label
     call       gtk_button_new_with_label
     mov        qword [settings.handle], rax

     mov        rdi, accounts.label
     call       gtk_button_new_with_label
     mov        qword [accounts.handle], rax

     mov        rdi, loans.label
     call       gtk_button_new_with_label
     mov        qword [loans.handle], rax

     mov        rdi, cash.label
     call       gtk_button_new_with_label
     mov        qword [cash.handle], rax

     mov        rdi, debts.label
     call       gtk_button_new_with_label
     mov        qword [debts.handle], rax

     ; 4. Pack Buttons and Connect Signals
     %macro pack_button 1
        mov     rdi, qword [vbox.handle]
        mov     rsi, qword [%1.handle]
        mov     rdx, TRUE
        mov     rcx, TRUE
        xor     r8d, r8d
        call    gtk_box_pack_start

        xor     r9d, r9d
        xor     r8d, r8d
        mov     rcx, qword [window.handle]
        mov     rdx, on_button_clicked
        mov     rsi, signal.clicked
        mov     rdi, qword [%1.handle]
        call    g_signal_connect_data
     %endmacro

     pack_button settings
     pack_button accounts
     pack_button loans
     pack_button cash
     pack_button debts

     ; 5. Signals & Main Loop
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

; Callback: on_button_clicked
on_button_clicked:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     
     ; rdi = button handle, rsi = window handle (user_data)
     push       rsi
     call       gtk_button_get_label
     pop        rdi ; Restore window handle into rdi
     mov        rsi, rax ; Label text into rsi
     call       gtk_window_set_title
     
     leave
     ret