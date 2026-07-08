; ==============================================================================
; Name        : undoredo.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkToolbar demonstration toggling sensitivity of operations
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
     pixbuffer:        resq      1
     error:            resq      1
     box:
     .handle:          resq      1
     toolbar:
     .handle:          resq      1
     tool:
     .undo:            resq      1
     .redo:            resq      1
     .sep:             resq      1
     .quit:            resq      1

section .data
     mainwindow:
     .title:           db        "Undo/Redo Toolbar", 0
     
     signal:
     .clicked:         db        "clicked", 0
     .destroy:         db        "destroy", 0

     icon:
     .file:            db        "resources/pictures/logo.png", 0

     toolbaritem.text:
     .undo:            db        "gtk-undo", 0
     .undoname:        db        "undo", 0
     .redo:            db        "gtk-redo", 0
     .redoname:        db        "redo", 0
     .quit:            db        "gtk-quit", 0

     state.count:      dd        2

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
     mov        qword [window.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, 1
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, 250
     mov        rdx, 200
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, mainwindow.title
     call       gtk_window_set_title

     mov        rdi, icon.file
     mov        rsi, error
     call       gdk_pixbuf_new_from_file
     mov        qword [pixbuffer], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     mov        rdi, GTK_ORIENTATION_VERTICAL
     xor        rsi, rsi
     call       gtk_box_new
     mov        qword [box.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [box.handle]
     call       gtk_container_add

     ; 3. Assemble Toolbar
     call       gtk_toolbar_new
     mov        qword [toolbar.handle], rax
     mov        rdi, qword [toolbar.handle]
     xor        rsi, rsi
     call       gtk_toolbar_set_style
     mov        rdi, qword [toolbar.handle]
     mov        rsi, 2
     call       gtk_container_set_border_width

     %macro add_tool 3
        mov     rdi, %1
        call    gtk_tool_button_new_from_stock
        mov     qword [%2], rax
        mov     rdi, qword [%2]
        mov     rsi, %3
        call    gtk_widget_set_name
        mov     rdi, qword [toolbar.handle]
        mov     rsi, qword [%2]
        mov     rdx, -1
        call    gtk_toolbar_insert
     %endmacro

     add_tool toolbaritem.text.undo, tool.undo, toolbaritem.text.undoname
     add_tool toolbaritem.text.redo, tool.redo, toolbaritem.text.redoname
     
     call       gtk_separator_tool_item_new
     mov        qword [tool.sep], rax
     mov        rdi, qword [toolbar.handle]
     mov        rsi, qword [tool.sep]
     mov        rdx, -1
     call       gtk_toolbar_insert

     mov        rdi, toolbaritem.text.quit
     call       gtk_tool_button_new_from_stock
     mov        qword [tool.quit], rax
     mov        rdi, qword [toolbar.handle]
     mov        rsi, qword [tool.quit]
     mov        rdx, -1
     call       gtk_toolbar_insert

     mov        rdi, qword [box.handle]
     mov        rsi, qword [toolbar.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     mov        r8d, 5
     call       gtk_box_pack_start

     ; 4. Signals
     %macro connect_sig 4
        xor     r9d, r9d
        xor     r8d, r8d
        mov     rcx, %3
        mov     rdx, %4
        mov     rsi, signal.clicked
        mov     rdi, %1
        call    g_signal_connect_data
     %endmacro

     connect_sig [tool.undo], 0, qword [tool.redo], proc_undo_redo
     connect_sig [tool.redo], 0, qword [tool.undo], proc_undo_redo
     connect_sig [tool.quit], 0, 0, gtk_main_quit
     
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

; Callback
proc_undo_redo:
     push r12
     push r13
     push r14
     push rbp
     mov rbp, rsp
     and rsp, -16

     mov r14, rdi
     
     mov rdi, r14
     call gtk_widget_get_name
     mov rdi, rax
     mov rsi, toolbaritem.text.undoname
     call strcmp
     test eax, eax
     jz .undo
     
.redo:
     inc dword [state.count]
     jmp .eval
.undo:
     dec dword [state.count]

.eval:
     mov r12d, dword [state.count]
     
     mov rdi, qword [tool.undo]
     xor rsi, rsi
     cmp r12d, 0
     setg sil
     call gtk_widget_set_sensitive
     
     mov rdi, qword [tool.redo]
     xor rsi, rsi
     cmp r12d, 5
     setl sil
     call gtk_widget_set_sensitive

.done:
     leave
     pop r14
     pop r13
     pop r12
     ret
