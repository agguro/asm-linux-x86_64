; ==============================================================================
; Name        : colorselection.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Minimalist color selection dialog (Original Working Version)
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

extern exit

section .bss
     target_label:     resq    1

section .data
     window:
     .handle:          dq   0
     .title:           db   "Color Selection Dialog", 0

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
     
     result:           dd   0
     dialog:
     .handle:          dq   0
     .title:           db   "Select Color", 0
     
     GTK_STOCK_SELECT_COLOR: db "gtk-select-color", 0
     colorsel:         dq   0
     
     color:            times 16 db 0 

section .text
     global _start

_start:
     ; 1. Stack Alignment & GTK3 Init
     mov      rdi, [rsp]                ; argc
     lea      rsi, [rsp + 8]            ; argv
     mov      r12, rdi
     mov      r13, rsi

     and      rsp, -16
     sub      rsp, 16
     lea      rdi, [rsp]
     mov      [rdi], r12
     lea      rsi, [rsp + 8]
     mov      [rsi], r13
     call     gtk_init

     ; 2. GUI Construction
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

     mov        rdi, TRUE
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

     mov        rdi, GTK_STOCK_SELECT_COLOR
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
     mov        r8, 5
     call       gtk_box_pack_start

     ; 3. Signals
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [label.handle]
     mov        rdx, select_color
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
     call       gtk_widget_show_all
     call       gtk_main
     call       exit

; ==============================================================================
; Callback: select_color
; ==============================================================================
select_color:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        qword [target_label], rsi

     mov        rdi, dialog.title
     call       gtk_color_selection_dialog_new
     mov        qword [dialog.handle], rax

     mov        rdi, qword [dialog.handle]
     mov        rsi, qword [window.handle]
     call       gtk_window_set_transient_for
    
     mov        rdi, qword [dialog.handle]
     call       gtk_dialog_run
     mov        dword [result], eax

     cmp        eax, GTK_RESPONSE_OK
     jne        .exit_callback

     mov        rdi, qword [dialog.handle]
     call       gtk_color_selection_dialog_get_color_selection
     
     mov        rdi, rax
     mov        rsi, color
     call       gtk_color_selection_get_current_color

     mov        rdi, qword [target_label]
     mov        rsi, GTK_STATE_NORMAL
     mov        rdx, color
     call       gtk_widget_modify_fg

.exit_callback:
     mov        rdi, qword [dialog.handle]
     call       gtk_widget_destroy
     leave
     ret
