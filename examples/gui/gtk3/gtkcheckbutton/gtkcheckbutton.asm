; ==============================================================================
; Name        : gtkcheckbutton.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkCheckButton example with dynamic window title switching
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
     parent_window:    resq      1

section .data
     logo:             incbin    "../resources/pictures/logo.png"
     logo_size:        equ       $ - logo

     window:
     .handle:          dq        0
     .title:           db        "GtkCheckButton", 0
     .endtitle:        db        "", 0

     fixed:
     .handle:          dq        0

     checkbutton:
     .handle:          dq        0
     .caption:         db        "Show title", 0

     signal:
     .destroy:         db        "destroy", 0
     .clicked:         db        "clicked", 0

     loader:           dq        0
     pixbuffer:        dq        0

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
     mov        edx, logo_size
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

     mov        rdi, qword [window.handle]
     mov        rsi, qword [pixbuffer]
     call       gtk_window_set_icon

     ; Connect Window Destroy Signal
     xor        r9d, r9d                  ; GConnectFlags = 0
     xor        r8d, r8d                  ; GClosureNotify = NULL
     xor        rcx, rcx                  ; user_data = NULL
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     ; Create Fixed Container Layout
     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     ; -------------------------------------------------------------------------
     ; 4. Instantiate CheckButton Control
     ; -------------------------------------------------------------------------
     mov        rdi, checkbutton.caption
     call       gtk_check_button_new_with_label
     mov        qword [checkbutton.handle], rax

     mov        rdi, qword [checkbutton.handle]
     mov        rsi, TRUE
     call       gtk_toggle_button_set_active

     mov        rdi, qword [checkbutton.handle]
     mov        rsi, TRUE
     call       gtk_widget_set_can_focus

     ; Connect Clicked Signal
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [window.handle]
     mov        rdx, toggle_title
     mov        rsi, signal.clicked
     mov        rdi, qword [checkbutton.handle]
     call       g_signal_connect_data

     ; Pack widget into fixed container
     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [checkbutton.handle]
     mov        rdx, 50
     mov        rcx, 50
     call       gtk_fixed_put

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit

; -------------------------------------------------------------------------
; Callback: toggle_title
; -------------------------------------------------------------------------
toggle_title:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        qword [parent_window], rsi
     call       gtk_toggle_button_get_active

     mov        rdi, qword [parent_window]
     mov        rsi, window.title
     cmp        eax, TRUE
     je         .set_title
     mov        rsi, window.endtitle

.set_title:
     call       gtk_window_set_title

     leave
     ret
