; ==============================================================================
; Name        : gtkframe.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkFrame examples demonstrating different shadow types
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
     .title:           db        "GtkFrame", 0

     table:
     .handle:          dq        0

     frame:
     .handle:          dq        0

     frame1:
     .shadow:          dd        0 ; GTK_SHADOW_IN
     .label:           db        "Shadow In", 0

     frame2:
     .shadow:          dd        2 ; GTK_SHADOW_OUT
     .label:           db        "Shadow Out", 0

     frame3:
     .shadow:          dd        3 ; GTK_SHADOW_ETCHED_IN
     .label:           db        "Shadow Etched In", 0

     frame4:
     .shadow:          dd        4 ; GTK_SHADOW_ETCHED_OUT
     .label:           db        "Shadow Etched Out", 0

     signal:
     .destroy:         db        "destroy", 0

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

     ; 2. Generate Pixbuf
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
     mov        rdx, 400
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     ; Create container grid
     mov        rdi, 4
     mov        rsi, 4
     mov        rdx, TRUE
     call       gtk_table_new
     mov        qword [table.handle], rax

     mov        rdi, qword [table.handle]
     mov        rsi, 10
     call       gtk_table_set_row_spacings
     mov        rdi, qword [table.handle]
     mov        rsi, 10
     call       gtk_table_set_col_spacings

     mov        rdi, qword [window.handle]
     mov        rsi, qword [table.handle]
     call       gtk_container_add

     ; 4. Instantiate Frames
     ; Frame 1
     mov        rdi, frame1.label
     call       gtk_frame_new
     mov        qword [frame.handle], rax
     mov        rdi, qword [frame.handle]
     mov        esi, dword [frame1.shadow]
     call       gtk_frame_set_shadow_type
     mov        rdi, qword [table.handle]
     mov        rsi, qword [frame.handle]
     mov        rdx, 1
     mov        rcx, 2
     mov        r8, 1
     mov        r9, 2
     call       gtk_table_attach_defaults

     ; Frame 2
     mov        rdi, frame2.label
     call       gtk_frame_new
     mov        qword [frame.handle], rax
     mov        rdi, qword [frame.handle]
     mov        esi, dword [frame2.shadow]
     call       gtk_frame_set_shadow_type
     mov        rdi, qword [table.handle]
     mov        rsi, qword [frame.handle]
     mov        rdx, 2
     mov        rcx, 3
     mov        r8, 1
     mov        r9, 2
     call       gtk_table_attach_defaults

     ; Frame 3
     mov        rdi, frame3.label
     call       gtk_frame_new
     mov        qword [frame.handle], rax
     mov        rdi, qword [frame.handle]
     mov        esi, dword [frame3.shadow]
     call       gtk_frame_set_shadow_type
     mov        rdi, qword [table.handle]
     mov        rsi, qword [frame.handle]
     mov        rdx, 1
     mov        rcx, 2
     mov        r8, 2
     mov        r9, 3
     call       gtk_table_attach_defaults

     ; Frame 4
     mov        rdi, frame4.label
     call       gtk_frame_new
     mov        qword [frame.handle], rax
     mov        rdi, qword [frame.handle]
     mov        esi, dword [frame4.shadow]
     call       gtk_frame_set_shadow_type
     mov        rdi, qword [table.handle]
     mov        rsi, qword [frame.handle]
     mov        rdx, 2
     mov        rcx, 3
     mov        r8, 2
     mov        r9, 3
     call       gtk_table_attach_defaults

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit
