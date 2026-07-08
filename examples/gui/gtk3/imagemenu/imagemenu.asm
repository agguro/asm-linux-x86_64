; ==============================================================================
; Name        : imagemenu.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : A menu bar example implementing accelerators and mnemonics
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
     menubar:
     .handle:          resq      1
     filemenu:
     .handle:          resq      1
     menuitem:
     .file:            resq      1
     .new:             resq      1
     .open:            resq      1
     .sep:             resq      1
     .quit:            resq      1
     accel_group:      resq      1

section .data
     mainwindow:
     .title:           db        "menu", 0

     signal:
     .destroy:         db        "destroy", 0
     .activate:        db        "activate", 0

     icon:
     .file:            db        "resources/pictures/logo.png", 0

     menuitem.text:
     .file:            db        "_File", 0
     .new:             db        "gtk-new", 0
     .open:            db        "gtk-open", 0
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

     ; 2. Build Window Frame & Inject Icons
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
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

     ; 3. Build Menu Components & Acceleration Tables
     call       gtk_menu_bar_new
     mov        qword [menubar.handle], rax

     call       gtk_menu_new
     mov        qword [filemenu.handle], rax

     call       gtk_accel_group_new
     mov        qword [accel_group], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [accel_group]
     call       gtk_window_add_accel_group

     mov        rdi, menuitem.text.file
     call       gtk_menu_item_new_with_mnemonic
     mov        qword [menuitem.file], rax

     mov        rdi, menuitem.text.new
     mov        rsi, qword [accel_group]
     call       gtk_image_menu_item_new_from_stock
     mov        qword [menuitem.new], rax

     mov        rdi, menuitem.text.open
     mov        rsi, qword [accel_group]
     call       gtk_image_menu_item_new_from_stock
     mov        qword [menuitem.open], rax

     call       gtk_separator_menu_item_new
     mov        qword [menuitem.sep], rax

     mov        rdi, menuitem.text.quit
     mov        rsi, qword [accel_group]
     call       gtk_image_menu_item_new_from_stock
     mov        qword [menuitem.quit], rax

     mov        rdi, qword [menuitem.quit]
     mov        rsi, signal.activate
     mov        rdx, qword [accel_group]
     mov        rcx, 0x71 ; GDK_q
     mov        r8d, 4    ; GDK_CONTROL_MASK
     mov        r9d, 1    ; GTK_ACCEL_VISIBLE
     call       gtk_widget_add_accelerator

     mov        rdi, qword [menuitem.file]
     mov        rsi, qword [filemenu.handle]
     call       gtk_menu_item_set_submenu

     mov        rdi, qword [filemenu.handle]
     mov        rsi, qword [menuitem.new]
     call       gtk_menu_shell_append
     mov        rdi, qword [filemenu.handle]
     mov        rsi, qword [menuitem.open]
     call       gtk_menu_shell_append
     mov        rdi, qword [filemenu.handle]
     mov        rsi, qword [menuitem.sep]
     call       gtk_menu_shell_append
     mov        rdi, qword [filemenu.handle]
     mov        rsi, qword [menuitem.quit]
     call       gtk_menu_shell_append

     mov        rdi, qword [menubar.handle]
     mov        rsi, qword [menuitem.file]
     call       gtk_menu_shell_append

     mov        rdi, qword [box.handle]
     mov        rsi, qword [menubar.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     mov        r8d, 3
     call       gtk_box_pack_start

     ; 4. Signal Connections
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, Quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, Quit
     mov        rsi, signal.activate
     mov        rdi, qword [menuitem.quit]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main
     xor        rdi, rdi
     call       exit

Quit:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     call       gtk_main_quit
     leave
     ret
