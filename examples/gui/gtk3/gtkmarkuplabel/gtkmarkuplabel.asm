; ==============================================================================
; Name        : gtkmarkuplabel.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkLabel example demonstrating Pango markup text styling
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
     logo:             incbin    "../resources/pictures/logo.png"
     logo_size:        equ       $ - logo

     window:
     .handle:          dq        0
     .title:           db        "GtkMarkupLabel", 0

     signal:
     .destroy:         db        "destroy", 0

     label:
     .handle:          dq        0
     .caption:         db        "Cold was my soul", 10, "Untold was the pain", 10 , "I faced when you left me", 10, "A rose in the rain....", 10
                       db        "So I swore to the razor", 10, "That never, enchained", 10, "Would your dark nails of faith", 10, "<i>Be pushed through my veins again</i>", 10, 10
                       db        "Bared on your tomb", 10, "<b>I&#39;m a prayer for your loneliness</b>", 10, "And would you ever soon", 10, "Come above onto me?", 10, "<u>For once upon a time</u>", 10
                       db        "On the binds of your lowliness", 10, "<b><i><u>I could always find the slot for your sacred key</u></i></b>", 0

     loader:           dq        0
     pixbuffer:        dq        0

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

     ; 2. Generate Pixbuf from Embedded Asset
     call       gdk_pixbuf_loader_new
     mov        qword [loader], rax

     mov        rdi, qword [loader]
     mov        rsi, logo
     mov        edx, logo_size
     xor        rcx, rcx
     call       gdk_pixbuf_loader_write

     mov        rdi, qword [loader]
     call       gdk_pixbuf_loader_get_pixbuf
     mov        qword [pixbuffer], rax

     ; 3. Build Window
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, qword [window.handle]
     mov        rsi, 500
     mov        rdx, 300
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     ; Connect Window Destroy Signal
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [window.handle]
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     ; 4. Instantiate and Configure Markup Label
     xor        rdi, rdi                  ; NULL
     call       gtk_label_new
     mov        qword [label.handle], rax

     mov        rdi, qword [label.handle]
     mov        rsi, label.caption
     call       gtk_label_set_markup

     mov        rdi, qword [label.handle]
     mov        rsi, 2                    ; GTK_JUSTIFY_CENTER
     call       gtk_label_set_justify

     mov        rdi, qword [window.handle]
     mov        rsi, qword [label.handle]
     call       gtk_container_add

     ; 5. Execution Loop
     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit
