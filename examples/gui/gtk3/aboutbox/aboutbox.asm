; ==============================================================================
; Name        : aboutbox.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Derived From: ZetCode GTK3 Examples
; Description : An aboutbox example with a centered text label
; ABI Status  : Stack-aligned (Original working configuration)
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
     logo:           incbin    "../resources/pictures/logo.png"
     .size:          equ       $ - logo
     picture:        incbin    "../resources/pictures/picture.png"
     .size:          equ       $ - picture

     window:
     .handle:        dq        0
     .title:         db        "About box example",0

     box:
     .handle:        dq        0

     label:
     .handle:        dq        0
     .text:          db        "click here",0

     signal:
     .destroy:       db        "destroy",0
     .buttonpress:   db        "button-press-event",0

     dialog:
     .title:         db        "About this example",0
     .version:       db        "1.0 - demo",0
     .copyright:     db        "(c) agguro - 2015",0
     .comments:      db        "This is an example to create an about dialogbox",0
     .website:       db        "https://github.com/agguro",0

     loader:         dq        0
     pixbuffer:
     .icon:          dq        0
     .image:         dq        0

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

     ; 2. Main Window Configuration
     mov      rdi, GTK_WINDOW_TOPLEVEL
     call     gtk_window_new
     mov      qword [window.handle], rax

     mov      rdi, qword [window.handle]
     mov      rsi, GTK_WIN_POS_CENTER
     call     gtk_window_set_position

     mov      rdi, qword [window.handle]
     mov      rsi, 220
     mov      rdx, 150
     call     gtk_window_set_default_size

     mov      rdi, qword [window.handle]
     mov      rsi, window.title
     call     gtk_window_set_title

     mov      rdi, qword [window.handle]
     mov      rsi, 15
     call     gtk_container_set_border_width

     mov      rdi, qword [window.handle]
     mov      rsi, GDK_BUTTON_PRESS_MASK
     call     gtk_widget_add_events

     ; 3. Centered Label Integration
     mov      rdi, GTK_ORIENTATION_VERTICAL
     xor      rsi, rsi
     call     gtk_box_new
     mov      qword [box.handle], rax

     mov      rdi, qword [box.handle]
     mov      rsi, GTK_ALIGN_CENTER
     call     gtk_widget_set_halign

     mov      rdi, qword [box.handle]
     mov      rsi, GTK_ALIGN_CENTER
     call     gtk_widget_set_valign

     mov      rdi, qword [window.handle]
     mov      rsi, qword [box.handle]
     call     gtk_container_add

     mov      rdi, label.text
     call     gtk_label_new
     mov      qword [label.handle], rax

     mov      rdi, qword [box.handle]
     mov      rsi, qword [label.handle]
     xor      rdx, rdx
     xor      rcx, rcx
     xor      r8d, r8d
     call     gtk_box_pack_start

     ; 4. Load Main Application Icon
     call     gdk_pixbuf_loader_new
     mov      qword [loader], rax

     mov      rdi, qword [loader]
     mov      rsi, logo
     mov      edx, logo.size
     xor      rcx, rcx
     call     gdk_pixbuf_loader_write

     mov      rdi, qword [loader]
     call     gdk_pixbuf_loader_get_pixbuf
     mov      qword [pixbuffer.icon], rax

     mov      rdi, qword [window.handle]
     mov      rsi, qword [pixbuffer.icon]
     call     gtk_window_set_icon

     ; 5. Signal Handlers
     xor      r9d, r9d
     xor      r8d, r8d
     mov      rcx, qword [window.handle]
     mov      rdx, show_about
     mov      rsi, signal.buttonpress
     mov      rdi, qword [window.handle]
     call     g_signal_connect_data

     xor      r9d, r9d
     xor      r8d, r8d
     xor      rcx, rcx
     mov      rdx, gtk_main_quit
     mov      rsi, signal.destroy
     mov      rdi, qword [window.handle]
     call     g_signal_connect_data

     ; 6. Execution Loop
     mov      rdi, qword [window.handle]
     call     gtk_widget_show_all
     call     gtk_main

.L_exit:
     xor      rdi, rdi
     call     exit

; Callback: show_about
show_about:
     push     rbp
     mov      rbp, rsp
     push     r12
     and      rsp, -16

     call     gdk_pixbuf_loader_new
     mov      qword [loader], rax

     mov      rdi, qword [loader]
     mov      rsi, picture
     mov      edx, picture.size
     xor      rcx, rcx
     call     gdk_pixbuf_loader_write

     mov      rdi, qword [loader]
     call     gdk_pixbuf_loader_get_pixbuf
     mov      qword [pixbuffer.image], rax

     call     gtk_about_dialog_new
     mov      r12, rax

     mov      rdi, r12
     mov      rsi, qword [window.handle]
     call     gtk_window_set_transient_for

     mov      rdi, r12
     mov      rsi, dialog.title
     call     gtk_about_dialog_set_program_name

     mov      rdi, r12
     mov      rsi, dialog.version
     call     gtk_about_dialog_set_version

     mov      rdi, r12
     mov      rsi, dialog.copyright
     call     gtk_about_dialog_set_copyright

     mov      rdi, r12
     mov      rsi, dialog.comments
     call     gtk_about_dialog_set_comments

     mov      rdi, r12
     mov      rsi, dialog.website
     call     gtk_about_dialog_set_website

     mov      rdi, r12
     mov      rsi, qword [pixbuffer.image]
     call     gtk_about_dialog_set_logo

     mov      rdi, r12
     mov      rsi, qword [pixbuffer.icon]
     call     gtk_window_set_icon

     mov      rdi, r12
     call     gtk_dialog_run

     mov      rdi, r12
     call     gtk_widget_destroy

     mov      rax, 1
     pop      r12
     leave
     ret
