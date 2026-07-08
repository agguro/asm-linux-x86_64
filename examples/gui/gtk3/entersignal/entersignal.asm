; ==============================================================================
; Name        : entersignal.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Onenter and onleave signals and events example via CSS injection
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

struc GdkRGBA
     .red:     resq      1
     .green:   resq      1
     .blue:    resq      1
     .alpha:   resq      1
endstruc

section .data
     color:    istruc GdkRGBA
          at GdkRGBA.red,       dq   1.0
          at GdkRGBA.green,     dq   0.0
          at GdkRGBA.blue,      dq   0.0
          at GdkRGBA.alpha,     dq   1.0
     iend

     window:
     .handle:       dq   0
     .title:        db   "enter signal", 0

     fixed:
     .handle:       dq   0

     button:
     .handle:       dq   0
     .label:        db   "Button", 0

     signal:
     .enter:        db   "enter-notify-event", 0
     .leave:        db   "leave-notify-event", 0
     .destroy:      db   "destroy", 0

     cssprovider:
     .handle:       dq   0
     .cssred:       db   "GtkWindow {background-color: red;}"
     .cssredsize:   equ  $ - cssprovider.cssred

     display:
     .handle:       dq   0

     screen:
     .handle:       dq   0

section .text
     global _start

_start:
     ; 1. Stack Alignment & GTK3 Init
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

     ; 2. Global CSS Provider Initialization
     call       gtk_css_provider_new
     mov        qword [cssprovider.handle], rax

     call       gdk_display_get_default
     mov        qword [display.handle], rax

     mov        rdi, qword [display.handle]
     call       gdk_display_get_default_screen
     mov        qword [screen.handle], rax

     mov        rcx, 0                    ; GError** = NULL
     mov        rdx, cssprovider.cssredsize
     mov        rsi, cssprovider.cssred
     mov        rdi, qword [cssprovider.handle]
     call       gtk_css_provider_load_from_data

     ; 3. Build and Configure Window Layout
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, 230
     mov        rdx, 150
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     ; Create Target Button
     mov        rdi, button.label
     call       gtk_button_new_with_label
     mov        qword [button.handle], rax

     mov        rdi, qword [button.handle]
     mov        rsi, 80
     mov        rdx, 35
     call       gtk_widget_set_size_request

     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button.handle]
     mov        rdx, 50
     mov        rcx, 50
     call       gtk_fixed_put

     ; 4. Signal Connections & Main Loop
     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, onenter
     mov        rsi, signal.enter
     mov        rdi, qword [button.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, onleave
     mov        rsi, signal.leave
     mov        rdi, qword [button.handle]
     call       g_signal_connect_data

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

.L_exit:
     xor        rdi, rdi
     call       exit

; Callback: onenter
onenter:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        rdx, color
     mov        rsi, GTK_STATE_FLAG_PRELIGHT
     call       gtk_widget_override_color

     mov        rdx, GTK_STYLE_PROVIDER_PRIORITY_USER
     mov        rsi, qword [cssprovider.handle]
     mov        rdi, qword [screen.handle]
     call       gtk_style_context_add_provider_for_screen

     mov        rax, FALSE
     leave
     ret

; Callback: onleave
onleave:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        rdi, qword [screen.handle]
     mov        rsi, qword [cssprovider.handle]
     call       gtk_style_context_remove_provider_for_screen

     mov        rax, FALSE
     leave
     ret