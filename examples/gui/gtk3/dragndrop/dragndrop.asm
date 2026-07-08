; ==============================================================================
; Name        : dragndrop.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Drag and drop window movement demo
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

struc GdkEventButton
     .type:         resd      1
     .padding0:     resd      1
     .window:       resq      1
     .send_event:   resb      1
     .padding1:     resb      3
     .time:         resd      1
     .x:            resq      1
     .y:            resq      1
     .axes:         resq      1
     .state:        resd      1
     .button:       resd      1
     .device:       resq      1
     .x_root:       resq      1
     .y_root:       resq      1
endstruc

section .bss
     transient_widget: resq   1
     transient_event:  resq   1
     empty_grid:       resq   1

section .data
     window:
     .handle:       dq   0
     .title:        db   "Drag and Drop", 0

     signal:
     .buttonpress:  db   "button-press-event", 0
     .destroy:      db   "destroy", 0

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

     ; 2. Build and Configure Window Layout
     mov      rdi, GTK_WINDOW_TOPLEVEL
     call     gtk_window_new
     mov      qword [window.handle], rax

     mov      rdi, qword [window.handle]
     mov      rsi, GTK_WIN_POS_CENTER
     call     gtk_window_set_position

     mov      rdi, qword [window.handle]
     mov      rsi, 230
     mov      rdx, 150
     call     gtk_window_set_default_size

     mov      rdi, qword [window.handle]
     mov      rsi, window.title
     call     gtk_window_set_title

     call     gtk_grid_new
     mov      qword [empty_grid], rax
     mov      rdi, qword [window.handle]
     mov      rsi, qword [empty_grid]
     call     gtk_window_set_titlebar

     mov      rdi, qword [window.handle]
     mov      rsi, FALSE
     call     gtk_window_set_decorated

     mov      rdi, qword [window.handle]
     mov      rsi, GDK_BUTTON_PRESS_MASK
     call     gtk_widget_add_events

     ; 3. Signal Connections
     xor      r9d, r9d
     xor      r8d, r8d
     xor      rcx, rcx
     mov      rdx, onbuttonpress
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

     mov      rdi, qword [window.handle]
     call     gtk_widget_show_all
     call     gtk_main

.L_exit:
     xor      rdi, rdi
     call     exit

; Callback: onbuttonpress
onbuttonpress:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        qword [transient_widget], rdi
     mov        qword [transient_event], rsi

     mov        rax, qword [transient_event]
     mov        eax, dword [rax + GdkEventButton.type]
     cmp        eax, 4 ; GDK_BUTTON_PRESS
     jne        .exit

     mov        rax, qword [transient_event]
     mov        eax, dword [rax + GdkEventButton.button]
     cmp        eax, 1 ; LEFT_MOUSE_BUTTON
     jne        .exit

.startdragging:
     mov        rdi, qword [transient_widget]
     call       gtk_widget_get_toplevel
     mov        rdi, rax

     mov        rcx, qword [transient_event]
     mov        esi, dword [rcx + GdkEventButton.button]

     movq       xmm0, qword [rcx + GdkEventButton.x_root]
     cvttsd2si  edx, xmm0

     movq       xmm0, qword [rcx + GdkEventButton.y_root]
     cvttsd2si  ecx, xmm0

     mov        rax, qword [transient_event]
     mov        r8d, dword [rax + GdkEventButton.time]
     call       gtk_window_begin_move_drag

.exit:
     mov        rax, 1 ; TRUE
     leave
     ret
