; ==============================================================================
; Name        : gtkseparators.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkSeparator example using a vertical box container to layout wrapped text labels
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
     logo:          incbin    "../resources/pictures/logo.png"
     logo.size:     equ       $ - logo

     window:
     .handle:       dq        0
     .title:        db        "GtkSeparators", 0

     signal:
     .destroy:      db        "destroy", 0

     label1:
     .handle:       dq        0
     .caption:      db        "Zinc is a moderately reactive, blue gray metal that tarnishes in moist air", 10
                    db        "and burns in air with a bright bluish-green flame, giving off fumes of zinc oxide.", 10
                    db        "It reacts with acids, alkalis and other non-metals. If not completely pure, ", 10
                    db        "zinc reacts with dilute acids to release hydrogen.", 0

     label2:
     .handle:       dq        0
     .caption:      db        "Copper is an essential trace nutrient to all high plants and animals. In animals, ", 10
                    db        "including humans, it is found primarily in the bloodstream, as a co-factor in various ", 10
                    db        "enzymes, and in copper-based pigments. ", 10
                    db        "However, in sufficient amounts, copper can be poisonous and even fatal to organisms.", 0

     box:
     .handle:       dq        0

     separator:
     .handle:       dq        0

     loader:        dq        0
     pixbuffer:     dq        0

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

     ; 2. Generate Pixbuf
     call       gdk_pixbuf_loader_new
     mov        qword [loader], rax
     mov        rdi, qword [loader]
     mov        rsi, logo
     mov        rdx, logo.size
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
     mov        rsi, 200
     mov        rdx, 10
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon
     mov        rdi, qword [window.handle]
     mov        rsi, FALSE
     call       gtk_window_set_resizable
     mov        rdi, qword [window.handle]
     mov        rsi, 20
     call       gtk_container_set_border_width

     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [window.handle]
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     ; 4. Build Layout
     mov        rdi, GTK_ORIENTATION_VERTICAL
     mov        rsi, 1
     call       gtk_box_new
     mov        qword [box.handle], rax
     mov        rdi, qword [window.handle]
     mov        rsi, qword [box.handle]
     call       gtk_container_add

     ; Label 1
     mov        rdi, label1.caption
     call       gtk_label_new
     mov        qword [label1.handle], rax
     mov        rdi, qword [label1.handle]
     mov        rsi, TRUE
     call       gtk_label_set_line_wrap
     mov        rdi, qword [box.handle]
     mov        rsi, qword [label1.handle]
     xor        rdx, rdx ; FALSE
     mov        rcx, TRUE
     xor        r8d, r8d
     call       gtk_box_pack_start

     ; Separator
     mov        rdi, GTK_ORIENTATION_HORIZONTAL
     call       gtk_separator_new
     mov        qword [separator.handle], rax
     mov        rdi, qword [box.handle]
     mov        rsi, qword [separator.handle]
     xor        rdx, rdx
     mov        rcx, TRUE
     mov        r8d, 10
     call       gtk_box_pack_start

     ; Label 2
     mov        rdi, label2.caption
     call       gtk_label_new
     mov        qword [label2.handle], rax
     mov        rdi, qword [label2.handle]
     mov        rsi, TRUE
     call       gtk_label_set_line_wrap
     mov        rdi, qword [box.handle]
     mov        rsi, qword [label2.handle]
     xor        rdx, rdx
     mov        rcx, TRUE
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main
     xor        rdi, rdi
     call       exit
