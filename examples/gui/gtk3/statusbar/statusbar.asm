; ==============================================================================
; Name        : statusbar.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : A window incorporating a checkmenu item toggling the visibility 
;               of a statusbar widget
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
     viewmenu:
     .handle:          resq      1
     view:
     .handle:          resq      1
     tog_stat:
     .handle:          resq      1
     statusbar:
     .handle:          resq      1

section .data
     mainwindow:
     .title:           db        "menu", 0
     
     signal:
     .destroy:         db        "destroy", 0
     .activate:        db        "activate", 0

     icon:
     .file:            db        "resources/pictures/logo.png", 0

     menuitem.text:
     .view:            db        "View", 0
     .viewstatusbar:   db        "View statusbar", 0

section .text
     global _start

_start:
     ; 1. Retrieve argc/argv and enforce System V AMD64 ABI Stack Alignment
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

     ; 2. Build Window Layout & Frame Structures
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

     ; 3. Assemble Menu Sockets & Statusbar Element
     call       gtk_menu_bar_new
     mov        qword [menubar.handle], rax

     call       gtk_menu_new
     mov        qword [viewmenu.handle], rax

     mov        rdi, menuitem.text.view
     call       gtk_menu_item_new_with_label
     mov        qword [view.handle], rax

     mov        rdi, menuitem.text.viewstatusbar
     call       gtk_check_menu_item_new_with_label
     mov        qword [tog_stat.handle], rax

     mov        rdi, qword [tog_stat.handle]
     mov        rsi, TRUE
     call       gtk_check_menu_item_set_active

     mov        rdi, qword [view.handle]
     mov        rsi, qword [viewmenu.handle]
     call       gtk_menu_item_set_submenu

     mov        rdi, qword [viewmenu.handle]
     mov        rsi, qword [tog_stat.handle]
     call       gtk_menu_shell_append

     mov        rdi, qword [menubar.handle]
     mov        rsi, qword [view.handle]
     call       gtk_menu_shell_append

     mov        rdi, qword [box.handle]
     mov        rsi, qword [menubar.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     mov        r8d, 3
     call       gtk_box_pack_start

     call       gtk_statusbar_new
     mov        qword [statusbar.handle], rax

     mov        rdi, qword [statusbar.handle]
     xor        rsi, rsi
     mov        rdx, menuitem.text.viewstatusbar
     call       gtk_statusbar_push

     mov        rdi, qword [box.handle]
     mov        rsi, qword [statusbar.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     mov        r8d, 1
     call       gtk_box_pack_end

     ; 4. Signal Connections & Runtime Execution Loops
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, Quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [statusbar.handle]
     mov        rdx, Toggle_Statusbar
     mov        rsi, signal.activate
     mov        rdi, qword [tog_stat.handle]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit

; Callbacks
Quit:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     call       gtk_main_quit
     leave
     ret

Toggle_Statusbar:
     push       r12
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        r12, rsi
     mov        rdi, qword [tog_stat.handle]
     call       gtk_check_menu_item_get_active
     mov        rdi, r12

     test       rax, rax
     jz         .hide
.show:
     call       gtk_widget_show
     jmp        .done
.hide:
     call       gtk_widget_hide
.done:
     leave
     pop        r12
     ret
