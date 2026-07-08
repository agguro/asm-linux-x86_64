; ==============================================================================
; Name        : fontselection.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Minimalist bare-metal font selection dialogbox with dynamic 
;               layout refresh
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

bits 64

[list -]
     %include "gtk3/defines.inc"
     %include "gtk3/gtk.inc"
     %include "gtk3/g.inc"
     %include "gtk3/gdk.inc"
     %include "gtk3/gobject.inc"
     %include "gtk3/pango.inc"
     %include "c/defines.inc"
     %include "c/c.inc"
[list +]

section .bss
     target_label:     resq    1

section .data
     window:
     .handle:          dq   0
     .title:           db   "Font Selection Dialog", 0

     signal:
     .destroy:         db   "destroy", 0
     .clicked:         db   "clicked", 0

     label:
     .handle:          dq   0
     .caption:         db   "This is the demonstration text", 0

     box:
     .handle:          dq   0
     
     toolbar:
     .handle:          dq   0
     
     button:
     .handle:          dq   0

     font_name:        dq   0
     font_description: dq   0

     result:           dd   0
     dialog:
     .handle:          dq   0
     .title:           db   "Select Font", 0

     GTK_STOCK_SELECT_FONT:   db   "gtk-select-font", 0

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

     ; 2. GUI Component Composition
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, 500
     mov        rdx, 200
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, GTK_ORIENTATION_VERTICAL
     xor        rsi, rsi
     call       gtk_box_new
     mov        qword [box.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [box.handle]
     call       gtk_container_add

     call       gtk_toolbar_new
     mov        qword [toolbar.handle], rax

     mov        rdi, qword [toolbar.handle]
     mov        rsi, GTK_TOOLBAR_ICONS
     call       gtk_toolbar_set_style

     mov        rdi, qword [toolbar.handle]
     mov        rsi, 2
     call       gtk_container_set_border_width

     mov        rdi, GTK_STOCK_SELECT_FONT
     call       gtk_tool_button_new_from_stock
     mov        qword [button.handle], rax

     mov        rdi, qword [toolbar.handle]
     mov        rsi, qword [button.handle]
     mov        rdx, -1
     call       gtk_toolbar_insert

     mov        rdi, qword [box.handle]
     mov        rsi, qword [toolbar.handle]
     mov        rdx, FALSE
     mov        rcx, FALSE
     mov        r8d, 5
     call       gtk_box_pack_start

     mov        rdi, label.caption
     call       gtk_label_new
     mov        qword [label.handle], rax

     mov        rdi, qword [label.handle]
     mov        rsi, GTK_JUSTIFY_CENTER
     call       gtk_label_set_justify

     mov        rdi, qword [box.handle]
     mov        rsi, qword [label.handle]
     mov        rdx, TRUE
     mov        rcx, FALSE
     mov        r8d, 5
     call       gtk_box_pack_start

     ; 3. Signal Configuration
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [label.handle]
     mov        rdx, select_font
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
     call       gtk_window_set_modal

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all

     call       gtk_main

.L_exit:
     xor        rdi, rdi
     call       exit

; Callback: select_font
select_font:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        qword [target_label], rsi

     mov        rdi, dialog.title
     call       gtk_font_selection_dialog_new
     mov        qword [dialog.handle], rax

     mov        rdi, qword [dialog.handle]
     mov        rsi, qword [window.handle]
     call       gtk_window_set_transient_for

.L_dialog_loop:
     mov        rdi, qword [dialog.handle]
     call       gtk_dialog_run
     mov        dword [result], eax

     cmp        eax, GTK_RESPONSE_OK
     je         .L_set_font_and_close
     cmp        eax, GTK_RESPONSE_APPLY
     je         .L_set_font_apply
     jmp        .L_exit_callback

.L_set_font_apply:
     call       .applyFont_internal
     jmp        .L_dialog_loop

.L_set_font_and_close:
     call       .applyFont_internal
     jmp        .L_exit_callback

.applyFont_internal:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        rdi, qword [dialog.handle]
     call       gtk_font_selection_dialog_get_font_name
     mov        qword [font_name], rax

     mov        rdi, qword [font_name]
     call       pango_font_description_from_string
     mov        qword [font_description], rax

     mov        rdi, qword [target_label]
     mov        rsi, qword [font_description]
     call       gtk_widget_modify_font

     mov        rdi, qword [target_label]
     call       gtk_widget_queue_draw

     mov        rdi, qword [font_name]
     call       g_free

     leave
     ret

.L_exit_callback:
     mov        rdi, qword [dialog.handle]
     call       gtk_widget_destroy

     leave
     ret
