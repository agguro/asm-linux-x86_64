; ==============================================================================
; Name        : applicationicon.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Derived From: ZetCode GTK3 Examples
; Description : A simple window centered on screen using gtk_window_set_icon_from_file
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
     window:
     .handle:       dq        0
     .title:        db        "window with application icon",0
     .class:        db        "applicationicon",0

     signal:
     .destroy:      db        "destroy",0

     icon:
     .file:         db        "icon:/home/agguro/Projects/nasm-linux-archive/examples/gui/gtk3/applicationicon/resources/pictures/logo.png",0
     .error:        dq        0

     app:
     .id:           db        "applicationicon",0

     error:
     .nofile:       db        "%s not found or failed to load as icon.",10,0

section .text
     global _start

_start:
     ; 1. Retrieve argc/argv and enforce System V AMD64 ABI Stack Alignment
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
     mov      rdi, app.id
     call     g_set_prgname

     ; 2. Build and Configure Window
     mov      rdi, GTK_WINDOW_TOPLEVEL
     call     gtk_window_new
     mov      qword [window.handle], rax

     ; Map Window Manager Class for taskbar matching (KDE/Wayland fallback)
     mov      rdi, qword [window.handle]
     mov      rsi, window.class
     mov      rdx, window.class
     call     gtk_window_set_wmclass

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

     ; 3. Apply Icon File Natively Via GTK
     mov      rdi, qword [window.handle]
     mov      rsi, icon.file
     mov      rdx, icon.error
     call     gtk_window_set_icon_from_file

     ; Check return value (returns TRUE/1 on success)
     and      rax, rax
     jnz      .L_connect_signals

     ; Print warning if asset load failed
     mov      rsi, icon.file
     mov      rdi, error.nofile
     xor      rax, rax
     call     printf

     ; 4. Signals & Event Loop
.L_connect_signals:
     xor      r9d, r9d                  ; GConnectFlags = 0
     xor      r8d, r8d                  ; GClosureNotify = NULL
     xor      rcx, rcx                  ; user_data = NULL
     mov      rdx, gtk_main_quit
     mov      rsi, signal.destroy
     mov      rdi, qword [window.handle]
     call     g_signal_connect_data

     ; Show main window instance
     mov      rdi, qword [window.handle]
     call     gtk_widget_show

     call     gtk_main

.L_exit:
     xor      rdi, rdi                  ; Exit code 0
     call     exit
