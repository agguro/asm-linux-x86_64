; ==============================================================================
; Name        : gtkbutton.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Gtk widgets example with memory-loaded application icon
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
     .size:         equ       $ - logo

     window:
     .handle:       dq        0
     .title:        db        "GtkButton", 0

     fixed:
     .handle:       dq        0

     button:
     .handle:       dq        0
     .caption:      db        "Quit", 0

     signal:
     .destroy:      db        "destroy", 0
     .clicked:      db        "clicked", 0

     loader:        dq        0
     pixbuffer:     dq        0

section .text
     global _start

_start:
     ; -------------------------------------------------------------------------
     ; 1. Retrieve argc/argv and enforce System V AMD64 ABI Stack Alignment
     ; -------------------------------------------------------------------------
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

     ; -------------------------------------------------------------------------
     ; 2. Generate Pixbuf from Embedded Asset in RAM
     ; -------------------------------------------------------------------------
     call       gdk_pixbuf_loader_new
     mov        qword [loader], rax

     mov        rdi, qword [loader]
     mov        rsi, logo
     mov        rdx, logo.size
     xor        rcx, rcx                  ; GError** = NULL
     call       gdk_pixbuf_loader_write

     mov        rdi, qword [loader]
     call       gdk_pixbuf_loader_get_pixbuf
     mov        qword [pixbuffer], rax

     ; -------------------------------------------------------------------------
     ; 3. Build and Configure Window Layout
     ; -------------------------------------------------------------------------
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

     ; Apply memory-loaded icon
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

     ; Create Fixed Container layout block
     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     ; -------------------------------------------------------------------------
     ; 4. Instantiate Button Control Component
     ; -------------------------------------------------------------------------
     mov        rdi, button.caption
     call       gtk_button_new_with_label
     mov        qword [button.handle], rax

     ; Apply explicit button layout size dimensions
     mov        rdi, qword [button.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request

     ; Connect Clicked Signal to close main loop
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [window.handle]
     mov        rdx, gtk_main_quit
     mov        rsi, signal.clicked
     mov        rdi, qword [button.handle]
     call       g_signal_connect_data

     ; Pack button into the fixed layout manager container at coordinates (50, 50)
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button.handle]
     mov        rdx, 50                   ; x-coordinate
     mov        rcx, 50                   ; y-coordinate
     call       gtk_fixed_put

     ; Render all active layout elements
     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all

     call       gtk_main

Exit:
     xor        rdi, rdi                  ; Exit code = 0
     call       exit
