; ==============================================================================
; Name        : toolbar.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : A window incorporating a native GtkToolbar
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
     .new:             resq      1
     .open:            resq      1
     .save:            resq      1
     .sep:             resq      1
     .quit:            resq      1

section .data
     mainwindow:
     .title:           db        "toolbar", 0
     
     signal:
     .clicked:         db        "clicked", 0
     .destroy:         db        "destroy", 0

     icon:
     .file:            db        "resources/pictures/logo.png", 0

     toolbaritem.text:
     .new:             db        "gtk-new", 0
     .open:            db        "gtk-open", 0
     .save:            db        "gtk-save", 0
     .quit:            db        "gtk-quit", 0

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
     xor        rsi, rsi ; GTK_TOOLBAR_ICONS
     call       gtk_toolbar_set_style
     mov        rdi, qword [toolbar.handle]
     mov        rsi, 2
     call       gtk_container_set_border_width

     %macro add_tool 2
        mov     rdi, %1
        call    gtk_tool_button_new_from_stock
        mov     qword [%2], rax
        mov     rdi, qword [toolbar.handle]
        mov     rsi, qword [%2]
        mov     rdx, -1
        call    gtk_toolbar_insert
     %endmacro

     add_tool toolbaritem.text.new, tool.new
     add_tool toolbaritem.text.open, tool.open
     add_tool toolbaritem.text.save, tool.save
     
     call       gtk_separator_tool_item_new
     mov        qword [tool.sep], rax
     mov        rdi, qword [toolbar.handle]
     mov        rsi, qword [tool.sep]
     mov        rdx, -1
     call       gtk_toolbar_insert

     add_tool toolbaritem.text.quit, tool.quit

     mov        rdi, qword [box.handle]
     mov        rsi, qword [toolbar.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     mov        r8d, 5
     call       gtk_box_pack_start

     ; 4. Signals
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.clicked
     mov        rdi, qword [tool.quit]
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
     xor        rdi, rdi
     call       exit
