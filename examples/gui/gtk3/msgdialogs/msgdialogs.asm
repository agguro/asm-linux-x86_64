; ==============================================================================
; Name        : msgdialogs.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Message dialog boxes mapping multiple alert variants
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
     dialog:
     .handle:          resq      1
     info:
     .handle:          resq      1
     error:
     .handle:          resq      1
     question:
     .handle:          resq      1
     warning:
     .handle:          resq      1

section .data
     window.title:     db        "Message dialogs", 0
     signal:
     .clicked:         db        "clicked", 0
     .destroy:         db        "destroy", 0

     info.data:
     .message:         db        "Download completed", 0
     .title:           db        "Information", 0
     .label:           db        "Info", 0

     error.data:
     .message:         db        "Error loading file", 0
     .title:           db        "Error", 0
     .label:           db        "Error", 0

     question.data:
     .message:         db        "Are you sure to quit?", 0
     .title:           db        "Question", 0
     .label:           db        "Question", 0

     warning.data:
     .message:         db        "Unallowed operation", 0
     .title:           db        "Warning", 0
     .label:           db        "Warning", 0

section .text
     global _start

_start:
     ; 1. Stack Alignment & GTK3 Init
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
     mov        qword [window.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, 1
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, 220
     mov        rdx, 150
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, 2
     mov        rsi, 2
     mov        rdx, 1
     call       gtk_table_new
     mov        qword [table.handle], rax
     mov        rdi, qword [table.handle]
     mov        rsi, 2
     call       gtk_table_set_row_spacings
     mov        rdi, qword [table.handle]
     mov        rsi, 2
     call       gtk_table_set_col_spacings

     ; Instantiate Buttons
     mov        rdi, info.data.label
     call       gtk_button_new_with_label
     mov        qword [info.handle], rax
     mov        rdi, warning.data.label
     call       gtk_button_new_with_label
     mov        qword [warning.handle], rax
     mov        rdi, question.data.label
     call       gtk_button_new_with_label
     mov        qword [question.handle], rax
     mov        rdi, error.data.label
     call       gtk_button_new_with_label
     mov        qword [error.handle], rax

     ; 3. Attach to Grid
     %macro attach_btn 6
        mov     rdi, qword [table.handle]
        mov     rsi, qword [%1.handle]
        mov     rdx, %2
        mov     rcx, %3
        mov     r8,  %4
        mov     r9,  %5
        push    3
        push    3
        push    %6
        push    %6
        call    gtk_table_attach
        add     rsp, 32
     %endmacro

     attach_btn info, 0, 1, 0, 1, 4
     attach_btn warning, 1, 2, 0, 1, 4
     attach_btn question, 0, 1, 1, 2, 4
     attach_btn error, 1, 2, 1, 2, 4

     mov        rdi, qword [window.handle]
     mov        rsi, qword [table.handle]
     call       gtk_container_add
     mov        rdi, qword [window.handle]
     mov        rsi, 15
     call       gtk_container_set_border_width

     ; 4. Signals
     %macro connect_sig 3
        xor     r9d, r9d
        xor     r8d, r8d
        mov     rcx, qword [window.handle]
        mov     rdx, %3
        mov     rsi, signal.clicked
        mov     rdi, qword [%1.handle]
        call    g_signal_connect_data
     %endmacro

     connect_sig info, signal.clicked, show_info
     connect_sig warning, signal.clicked, show_warning
     connect_sig question, signal.clicked, show_question
     connect_sig error, signal.clicked, show_error

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

; Callbacks
show_info:
     push rbp
     mov rbp, rsp
     and rsp, -16
     mov rdi, rsi
     mov rsi, 2
     mov rdx, 0
     mov rcx, 1
     mov r8, info.data.message
     xor rax, rax
     call gtk_message_dialog_new
     mov [dialog.handle], rax
     mov rdi, [dialog.handle]
     mov rsi, info.data.title
     call gtk_window_set_title
     mov rdi, [dialog.handle]
     call gtk_dialog_run
     mov rdi, [dialog.handle]
     call gtk_widget_destroy
     leave
     ret

show_error:
     push rbp
     mov rbp, rsp
     and rsp, -16
     mov rdi, rsi
     mov rsi, 2
     mov rdx, 3
     mov rcx, 1
     mov r8, error.data.message
     xor rax, rax
     call gtk_message_dialog_new
     mov [dialog.handle], rax
     mov rdi, [dialog.handle]
     mov rsi, error.data.title
     call gtk_window_set_title
     mov rdi, [dialog.handle]
     call gtk_dialog_run
     mov rdi, [dialog.handle]
     call gtk_widget_destroy
     leave
     ret

show_question:
     push rbp
     mov rbp, rsp
     and rsp, -16
     mov rdi, rsi
     mov rsi, 2
     mov rdx, 2
     mov rcx, 4
     mov r8, question.data.message
     xor rax, rax
     call gtk_message_dialog_new
     mov [dialog.handle], rax
     mov rdi, [dialog.handle]
     mov rsi, question.data.title
     call gtk_window_set_title
     mov rdi, [dialog.handle]
     call gtk_dialog_run
     mov rdi, [dialog.handle]
     call gtk_widget_destroy
     leave
     ret

show_warning:
     push rbp
     mov rbp, rsp
     and rsp, -16
     mov rdi, rsi
     mov rsi, 2
     mov rdx, 1
     mov rcx, 1
     mov r8, warning.data.message
     xor rax, rax
     call gtk_message_dialog_new
     mov [dialog.handle], rax
     mov rdi, [dialog.handle]
     mov rsi, warning.data.title
     call gtk_window_set_title
     mov rdi, [dialog.handle]
     call gtk_dialog_run
     mov rdi, [dialog.handle]
     call gtk_widget_destroy
     leave
     ret
