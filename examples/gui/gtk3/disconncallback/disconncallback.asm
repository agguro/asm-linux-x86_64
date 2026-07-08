; ==============================================================================
; Name        : disconncallback.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : Disconnecting a callback dynamically using a checkbox
; ABI Status  : Compliant (Stack-aligned, Callee-saved preserved)
; ==============================================================================

bits 64

[list -]
     %define   GTK_WIN_POS_CENTER       1
     %define   GTK_WINDOW_TOPLEVEL      0
     %define   NULL                     0
     %define   TRUE                     1
     %define   FALSE                    0

     extern    exit
     extern    gtk_button_new_with_label
     extern    gtk_container_add
     extern    gtk_fixed_new
     extern    gtk_fixed_put
     extern    gtk_init
     extern    gtk_main
     extern    gtk_main_quit
     extern    gtk_widget_set_size_request
     extern    gtk_widget_show_all
     extern    gtk_window_new
     extern    gtk_window_set_default_size
     extern    gtk_window_set_position
     extern    gtk_window_set_title
     extern    g_print
     extern    g_signal_connect_data
     extern    gtk_check_button_new_with_label
     extern    gtk_toggle_button_get_active
     extern    gtk_toggle_button_set_active
     extern    g_signal_handler_disconnect
[list +]

section .data
     window:
     .handle:       dq   0
     .title:        db   "Disconnect", 0

     fixed:
     .handle:       dq   0

     button:
     .handle:       dq   0
     .label:        db   "Click", 0

     checkbox:
     .handle:       dq   0
     .label:        db   "Connect", 0

     signal:
     .clicked:      db   "clicked", 0
     .destroy:      db   "destroy", 0

     message:
     .clicked:      db   "Clicked", 10, 0

     handler:
     .id:           dq   0

section .text
     global _start

_start:
     ; -------------------------------------------------------------------------
     ; 1. Retrieve argc/argv and enforce System V AMD64 ABI Stack Alignment
     ; -------------------------------------------------------------------------
     mov        rdi, [rsp]                ; argc
     lea        rsi, [rsp + 8]            ; argv

     mov        r12, rdi                  ; Back-up argc
     mov        r13, rsi                  ; Back-up argv

     and        rsp, -16                  ; Enforce 16-byte alignment
     sub        rsp, 16                   ; Reserved space for &argc and &argv

     lea        rdi, [rsp]                ; Move &argc to stack
     mov        [rdi], r12
     lea        rsi, [rsp + 8]            ; Move &argv to stack
     mov        [rsi], r13

     call       gtk_init

     ; -------------------------------------------------------------------------
     ; 2. Build and Configure Window Layout
     ; -------------------------------------------------------------------------
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, qword [window.handle]
     mov        rsi, 250
     mov        rdx, 150
     call       gtk_window_set_default_size

     mov        rdi, qword [window.handle]
     mov        rsi, window.title
     call       gtk_window_set_title

     ; Create Fixed Container
     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     ; -------------------------------------------------------------------------
     ; 3. Widgets Setup (Button & Checkbox)
     ; -------------------------------------------------------------------------
     ; Create Target Button
     mov        rdi, button.label
     call       gtk_button_new_with_label
     mov        qword [button.handle], rax

     mov        rdi, qword [button.handle]
     mov        rsi, 80
     mov        rdx, 30
     call       gtk_widget_set_size_request

     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [button.handle]
     mov        rdx, 30
     mov        rcx, 50
     call       gtk_fixed_put

     ; Create Toggle Checkbox
     mov        rdi, checkbox.label
     call       gtk_check_button_new_with_label
     mov        qword [checkbox.handle], rax

     mov        rdi, qword [checkbox.handle]
     mov        rsi, TRUE
     call       gtk_toggle_button_set_active

     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [checkbox.handle]
     mov        rdx, 130
     mov        rcx, 50
     call       gtk_fixed_put

     ; -------------------------------------------------------------------------
     ; 4. Signal Connections & Main Loop
     ; -------------------------------------------------------------------------
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, NULL
     mov        rdx, button_clicked
     mov        rsi, signal.clicked
     mov        rdi, qword [button.handle]
     call       g_signal_connect_data
     mov        qword [handler.id], rax

     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, qword [button.handle]
     mov        rdx, toggle_signal
     mov        rsi, signal.clicked
     mov        rdi, qword [checkbox.handle]
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

     xor        rdi, rdi
     call       exit

; -------------------------------------------------------------------------
; Callback: button_clicked
; -------------------------------------------------------------------------
button_clicked:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     mov        rdi, message.clicked
     xor        rax, rax
     call       g_print

     leave
     ret

; -------------------------------------------------------------------------
; Callback: toggle_signal
; -------------------------------------------------------------------------
toggle_signal:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16

     push       r14
     push       r15

     mov        r14, rdi
     mov        r15, rsi

     mov        rdi, r14
     call       gtk_toggle_button_get_active
     and        rax, rax
     jz         .disconnect

.connect:
     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, NULL
     mov        rdx, button_clicked
     mov        rsi, signal.clicked
     mov        rdi, r15
     call       g_signal_connect_data
     mov        qword [handler.id], rax
     jmp        .done

.disconnect:
     mov        rdi, r15
     mov        rsi, qword [handler.id]
     call       g_signal_handler_disconnect

.done:
     pop        r15
     pop        r14
     leave
     ret
