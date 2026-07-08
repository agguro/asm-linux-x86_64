; ==============================================================================
; Name        : gtkalignment.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Layout management forcing buttons to the bottom-right corner
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
     .handle:         dq   0
     .title:          db   "GtkAlignment", 0

     bttnOK:
     .handle:         dq   0
     .label:          db   "OK", 0

     bttnClose:
     .handle:         dq   0
     .label:          db   "Close", 0

     signal:
     .destroy:        db   "destroy", 0

     vbox:
     .handle:         dq   0

     hbox:
     .handle:         dq   0

     valign:
     .handle:         dq   0

     halign:
     .handle:         dq   0

     ; Float constants for gtk_alignment_new (gfloat = 32-bit float)
     float_0:         dd   0.0
     float_1:         dd   1.0

section .text
     global _start

_start:
     ; -------------------------------------------------------------------------
     ; 1. Stack Alignment conform System V AMD64 ABI
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
     ; 2. Build Structural Containers
     ; -------------------------------------------------------------------------
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     ; Top-level vertical layout box
     mov        rdi, GTK_ORIENTATION_VERTICAL
     xor        rsi, rsi
     call       gtk_box_new
     mov        qword [vbox.handle], rax

     ; Horizontal button rows pack box
     mov        rdi, GTK_ORIENTATION_HORIZONTAL
     mov        rsi, 5                    ; Spacing between buttons = 5px
     call       gtk_box_new
     mov        qword [hbox.handle], rax

     ; Vertical alignment (xalign=0.0, yalign=1.0 [Bottom], xscale=1.0, yscale=0.0)
     movss      xmm0, dword [float_0]
     movss      xmm1, dword [float_1]
     movss      xmm2, dword [float_1]
     movss      xmm3, dword [float_0]
     call       gtk_alignment_new
     mov        qword [valign.handle], rax

     ; Horizontal alignment (xalign=1.0 [Right], yalign=0.0, xscale=0.0, yscale=0.0)
     movss      xmm0, dword [float_1]
     movss      xmm1, dword [float_0]
     movss      xmm2, dword [float_0]
     movss      xmm3, dword [float_0]
     call       gtk_alignment_new
     mov        qword [halign.handle], rax

     ; -------------------------------------------------------------------------
     ; 3. Instantiate and Pack Widgets
     ; -------------------------------------------------------------------------
     mov        rdi, bttnOK.label
     call       gtk_button_new_with_label
     mov        qword [bttnOK.handle], rax

     mov        rdi, bttnClose.label
     call       gtk_button_new_with_label
     mov        qword [bttnClose.handle], rax

     ; Enforce standardized size limits
     mov        rdi, qword [bttnOK.handle]
     mov        rsi, 70
     mov        rdx, 30
     call       gtk_widget_set_size_request

     mov        rdi, qword [bttnClose.handle]
     mov        rsi, 70
     mov        rdx, 30
     call       gtk_widget_set_size_request

     ; Pack into HBox
     mov        rdi, qword [hbox.handle]
     mov        rsi, qword [bttnOK.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, qword [hbox.handle]
     mov        rsi, qword [bttnClose.handle]
     xor        rdx, rdx
     xor        rcx, rcx
     xor        r8d, r8d
     call       gtk_box_pack_start

     ; -------------------------------------------------------------------------
     ; 4. Pipeline Tree (vbox -> valign -> halign -> hbox)
     ; -------------------------------------------------------------------------
     mov        rdi, qword [halign.handle]
     mov        rsi, qword [hbox.handle]
     call       gtk_container_add

     mov        rdi, qword [valign.handle]
     mov        rsi, qword [halign.handle]
     call       gtk_container_add

     mov        rdi, qword [vbox.handle]
     mov        rsi, qword [valign.handle]
     mov        rdx, TRUE                 ; expand
     mov        rcx, TRUE                 ; fill
     xor        r8d, r8d
     call       gtk_box_pack_start

     mov        rdi, qword [window.handle]
     mov        rsi, qword [vbox.handle]
     call       gtk_container_add

     ; -------------------------------------------------------------------------
     ; 5. Final Configuration
     ; -------------------------------------------------------------------------
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, 300
     mov        rdx, 250
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     mov        rdi, qword [window.handle]
     mov        rsi, 10
     call       gtk_container_set_border_width

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main

     xor        rdi, rdi
     call       exit
