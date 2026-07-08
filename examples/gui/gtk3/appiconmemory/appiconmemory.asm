; ==============================================================================
; Name        : appiconmemory.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Derived From: ZetCode GTK3 Examples
; Description : Setting an application icon from memory and display the same 
;               icon as image in a window
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
     logo:          incbin    "../resources/pictures/logo.png"
     .size:         equ       $ - logo

     window:
     .handle:       dq        0
     .title:        db        "window with application icon",0
     .class:        db        "appiconmemory",0

     signal:
     .destroy:      db        "destroy",0

     loader:        dq        0
     pixbuffer:     dq        0
     image:         dq        0

section .text
     global _start

_start:
     ; -------------------------------------------------------------------------
     ; 1. Retrieve argc/argv and enforce System V AMD64 ABI Stack Alignment
     ; -------------------------------------------------------------------------
     mov      rdi, [rsp]                ; argc
     lea      rsi, [rsp + 8]            ; argv

     mov      r12, rdi                  ; Back-up argc
     mov      r13, rsi                  ; Back-up argv

     and      rsp, -16                  ; Enforce 16-byte alignment
     sub      rsp, 16                   ; Reserved space for &argc and &argv

     lea      rdi, [rsp]                ; Move &argc to stack
     mov      [rdi], r12
     lea      rsi, [rsp + 8]            ; Move &argv to stack
     mov      [rsi], r13

     call     gtk_init

     ; Set application ID for desktop environment matching
     mov      rdi, window.class
     call     g_set_prgname

     ; -------------------------------------------------------------------------
     ; 2. Generate Pixbuf from Embedded Asset in RAM
     ; -------------------------------------------------------------------------
     call     gdk_pixbuf_loader_new
     mov      qword [loader], rax

     mov      rdi, qword [loader]
     mov      rsi, logo
     mov      rdx, logo.size            ; Pass size as 64-bit value
     xor      rcx, rcx                  ; GError** = NULL
     call     gdk_pixbuf_loader_write

     mov      rdi, qword [loader]
     call     gdk_pixbuf_loader_get_pixbuf
     mov      qword [pixbuffer], rax

     ; -------------------------------------------------------------------------
     ; 3. Build Window & Image Components
     ; -------------------------------------------------------------------------
     mov      rdi, GTK_WINDOW_TOPLEVEL
     call     gtk_window_new
     mov      qword [window.handle], rax

     ; Map Window Manager Class for taskbar matching (KDE/Wayland fallback)
     mov      rdi, qword [window.handle]
     mov      rsi, window.class
     mov      rdx, window.class
     call     gtk_window_set_wmclass

     ; Create GTK Image component from RAM-based pixbuf
     mov      rdi, qword [pixbuffer]
     call     gtk_image_new_from_pixbuf
     mov      qword [image], rax

     ; Pack image into the main window container
     mov      rdi, qword [window.handle]
     mov      rsi, qword [image]
     call     gtk_container_add

     ; Set Window Properties
     mov      rdi, qword [window.handle]
     mov      rsi, window.title
     call     gtk_window_set_title

     mov      rdi, qword [window.handle]
     mov      rsi, 230
     mov      rdx, 150
     call     gtk_window_set_default_size

     mov      rdi, qword [window.handle]
     mov      rsi, GTK_WIN_POS_CENTER
     call     gtk_window_set_position

     ; Set runtime window icon decoration
     mov      rdi, qword [window.handle]
     mov      rsi, qword [pixbuffer]
     call     gtk_window_set_icon

     ; -------------------------------------------------------------------------
     ; 4. Signals & Event Loop
     ; -------------------------------------------------------------------------
     xor      r9d, r9d                  ; GConnectFlags = 0
     xor      r8d, r8d                  ; GClosureNotify = NULL
     xor      rcx, rcx                  ; user_data = NULL
     mov      rdx, gtk_main_quit
     mov      rsi, signal.destroy
     mov      rdi, qword [window.handle]
     call     g_signal_connect_data

     ; Show window and all child elements
     mov      rdi, qword [window.handle]
     call     gtk_widget_show_all

     call     gtk_main

.L_exit:
     xor      rdi, rdi
     call     exit
