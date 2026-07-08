; Name        : timer.asm
;
; Build       : nasm -felf64 -o timer.o -l timer.lst timer.asm
;               ld -s -m elf_x86_64 timer.o -o timer -lc --dynamic-linker /lib64/ld-linux-x86-64.so.2 -lgtk-3 -lgobject-2.0 -lglib-2.0 -lgdk_pixbuf-2.0 -lgdk-3 -lpango-1.0 -latk-1.0 -lgio-2.0
;
; Description : A glib-timeout timer example toggling window header state titles dynamically

bits 64

[list -]
     %define   GTK_WIN_POS_CENTER        1
     %define   GTK_WINDOW_TOPLEVEL       0
     %define   NULL                      0
     %define   TRUE                      1
     %define   FALSE                     0

     extern    exit
     extern    gtk_container_add
     extern    gtk_fixed_new
     extern    gtk_fixed_put
     extern    gtk_init
     extern    gtk_main
     extern    gtk_main_quit
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
     extern    g_timeout_add
[list +]

section .data
     window:
     .handle:       dq   0
     .title:        db   "timer inactive", 0

     fixed:
     .handle:       dq   0

     checkbox:
     .handle:       dq   0
     .label:        db   "toggle timer", 0

     signal:
     .clicked:      db   "clicked", 0
     .destroy:      db   "destroy", 0

     message:       db   "timer active", 10, 0
     active:        db   "timer active", 0
     inactive:      db   "timer inactive", 0

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
     ; 2. Build and Configure Window Components
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

     call       gtk_fixed_new
     mov        qword [fixed.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, qword [fixed.handle]
     call       gtk_container_add

     mov        rdi, checkbox.label
     call       gtk_check_button_new_with_label
     mov        qword [checkbox.handle], rax

     mov        rdi, qword [checkbox.handle]
     mov        rsi, FALSE
     call       gtk_toggle_button_set_active

     mov        rdi, qword [fixed.handle]
     mov        rsi, qword [checkbox.handle]
     mov        rdx, 130                  ; x-coordinate
     mov        rcx, 50                   ; y-coordinate
     call       gtk_fixed_put

     ; -------------------------------------------------------------------------
     ; 3. Signal Connections, Timeout Hook, & Main Loop
     ; -------------------------------------------------------------------------
     xor        r9d, r9d                  ; GConnectFlags = 0
     xor        r8d, r8d                  ; GClosureNotify = NULL
     mov        rcx, NULL                 ; user_data = NULL
     mov        rdx, toggle_signal
     mov        rsi, signal.clicked
     mov        rdi, qword [checkbox.handle]
     call       g_signal_connect_data

     xor        r9d, r9d
     xor        r8d, r8d
     mov        rcx, NULL
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all

     ; Hook Glib runtime timeout trigger (interval = 1000ms)
     mov        rdi, 1000
     mov        rsi, time_handler
     mov        rdx, qword [window.handle] ; Pass correct structured destination handle
     call       g_timeout_add

     call       gtk_main

     xor        rdi, rdi                  ; Exit code = 0
     call       exit

; -------------------------------------------------------------------------
; Callback: time_handler (Fires every 1000ms)
; -------------------------------------------------------------------------
time_handler:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16                  ; Force 16-byte alignment

     mov        rdi, qword [checkbox.handle]
     call       gtk_toggle_button_get_active
     cmp        rax, TRUE
     jnz        .done

     mov        rdi, message
     xor        rax, rax
     call       g_print

.done:
     mov        rax, TRUE                 ; Return TRUE to keep the timer pooling active
     leave
     ret

; -------------------------------------------------------------------------
; Callback: toggle_signal
; -------------------------------------------------------------------------
toggle_signal:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16                  ; Force 16-byte alignment

     ; RDI contains the calling GtkCheckButton pointer
     call       gtk_toggle_button_get_active
     and        rax, rax
     jz         .disconnect

.connect:
     mov        rdi, qword [window.handle]
     mov        rsi, active
     call       gtk_window_set_title
     jmp        .exit

.disconnect:
     mov        rdi, qword [window.handle]
     mov        rsi, inactive
     call       gtk_window_set_title

.exit:
     leave
     ret
