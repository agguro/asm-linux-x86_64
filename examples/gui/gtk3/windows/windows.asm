; Name        : windows.asm
; Build       : nasm -felf64 --noexecstack -o windows.o windows.asm
; Link        : ld -s -m elf_x86_64 \
;                   windows.o \
;                   -o windows \
;                   -lc \
;                   --dynamic-linker /lib64/ld-linux-x86-64.so.2 \
;                   -lgtk-3 -lgobject-2.0 -lglib-2.0 -lgdk_pixbuf-2.0 -lgdk-3 -lpango-1.0 -latk-1.0 -lgio-2.0

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

; -------------------------------------------------------------------------
; Macro Definition
; -------------------------------------------------------------------------
%macro table_attach 9
    mov rdi, [table_handle]
    mov rsi, %1
    mov rdx, %2
    mov rcx, %3
    mov r8, %4
    mov r9, %5
    push %6    ; ypad
    push %7    ; xpad
    push %8    ; yoptions
    push %9    ; xoptions
    call gtk_table_attach
    add rsp, 32
%endmacro

section .data
     window_title:     db    "Windows", 0
     label_caption:    db    "Windows", 0
     btn_activate_cap: db    "Activate", 0
     btn_close_cap:    db    "Close", 0
     btn_help_cap:     db    "Help", 0
     btn_ok_cap:       db    "OK", 0
     signal_destroy:   db    "destroy", 0
     signal_clicked:   db    "clicked", 0
     fp_0_0:           dd    0.0
     fp_1_0:           dd    1.0

section .bss
     window_handle:    resq    1
     table_handle:     resq    1
     vbox_handle:      resq    1
     label_handle:     resq    1
     text_view_handle: resq    1
     btn_act_handle:   resq    1
     btn_close_handle: resq    1
     btn_help_handle:  resq    1
     btn_ok_handle:    resq    1
     h_align:          resq    1
     h_align2:         resq    1

section .text
     global _start

_start:
     ; -------------------------------------------------------------------------
     ; 1. Stack Alignment & GTK3 Init
     ; -------------------------------------------------------------------------
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

     ; -------------------------------------------------------------------------
     ; 2. Window Initialization
     ; -------------------------------------------------------------------------
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        [window_handle], rax

     mov        rdi, [window_handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position

     mov        rdi, [window_handle]
     mov        rsi, 300
     mov        rdx, 250
     call       gtk_widget_set_size_request

     mov        rdi, [window_handle]
     mov        rsi, FALSE
     call       gtk_window_set_resizable

     mov        rdi, [window_handle]
     mov        rsi, window_title
     call       gtk_window_set_title

     mov        rdi, [window_handle]
     mov        rsi, 15
     call       gtk_container_set_border_width

     ; Create Grid Table Layout (8 rows, 4 columns)
     mov        rdi, 8
     mov        rsi, 4
     mov        rdx, FALSE
     call       gtk_table_new
     mov        [table_handle], rax

     mov        rdi, [table_handle]
     mov        rsi, 3
     call       gtk_table_set_col_spacings

     ; -------------------------------------------------------------------------
     ; 3. Widget Elements
     ; -------------------------------------------------------------------------
     ; Title Label
     mov        rdi, label_caption
     call       gtk_label_new
     mov        [label_handle], rax

     xorps      xmm0, xmm0
     xorps      xmm1, xmm1
     xorps      xmm2, xmm2
     xorps      xmm3, xmm3
     movss      xmm0, [fp_0_0]
     movss      xmm1, [fp_0_0]
     movss      xmm2, [fp_0_0]
     movss      xmm3, [fp_0_0]
     call       gtk_alignment_new
     mov        [h_align], rax

     mov        rdi, [h_align]
     mov        rsi, [label_handle]
     call       gtk_container_add

     table_attach [h_align], 0, 1, 0, 1, 0, 0, GTK_FILL, GTK_FILL

     ; TextView Box
     call       gtk_text_view_new
     mov        [text_view_handle], rax

     mov        rdi, [text_view_handle]
     mov        rsi, FALSE
     call       gtk_text_view_set_editable

     mov        rdi, [text_view_handle]
     mov        rsi, FALSE
     call       gtk_text_view_set_cursor_visible

     table_attach [text_view_handle], 0, 2, 1, 8, 1, 1, (GTK_FILL|GTK_EXPAND), (GTK_FILL|GTK_EXPAND)

     ; -------------------------------------------------------------------------
     ; 4. Sidebar Action Buttons (Standardized Height & Width via VBox)
     ; -------------------------------------------------------------------------
     ; Create a Vertical Box container (homogeneous = FALSE, spacing = 6 pixels)
     mov        rdi, FALSE
     mov        rsi, 6
     call       gtk_vbox_new
     mov        [vbox_handle], rax

     ; Button 1: Activate
     mov        rdi, btn_activate_cap
     call       gtk_button_new_with_label
     mov        [btn_act_handle], rax
     mov        rdi, rax
     mov        rsi, 75           ; Shared explicit width
     mov        rdx, 28           ; Shared explicit height
     call       gtk_widget_set_size_request

     ; Button 2: Close
     mov        rdi, btn_close_cap
     call       gtk_button_new_with_label
     mov        [btn_close_handle], rax
     mov        rdi, rax
     mov        rsi, 75
     mov        rdx, 28
     call       gtk_widget_set_size_request

     ; Button 3: Help
     mov        rdi, btn_help_cap
     call       gtk_button_new_with_label
     mov        [btn_help_handle], rax
     mov        rdi, rax
     mov        rsi, 75
     mov        rdx, 28
     call       gtk_widget_set_size_request

     ; Button 4: OK
     mov        rdi, btn_ok_cap
     call       gtk_button_new_with_label
     mov        [btn_ok_handle], rax
     mov        rdi, rax
     mov        rsi, 75
     mov        rdx, 28
     call       gtk_widget_set_size_request

     ; Pack all buttons sequentially into the VBox (expand=FALSE, fill=FALSE, padding=0)
     mov        rdi, [vbox_handle]
     mov        rsi, [btn_act_handle]
     mov        rdx, FALSE
     mov        rcx, FALSE
     mov        r8, 0
     call       gtk_box_pack_start

     mov        rdi, [vbox_handle]
     mov        rsi, [btn_close_handle]
     mov        rdx, FALSE
     mov        rcx, FALSE
     mov        r8, 0
     call       gtk_box_pack_start

     mov        rdi, [vbox_handle]
     mov        rsi, [btn_help_handle]
     mov        rdx, FALSE
     mov        rcx, FALSE
     mov        r8, 0
     call       gtk_box_pack_start

     ; Give the bottom OK button a small structural vertical separation gap
     mov        rdi, [vbox_handle]
     mov        rsi, [btn_ok_handle]
     mov        rdx, FALSE
     mov        rcx, FALSE
     mov        r8, 20            ; Adds 20 pixels padding space above OK
     call       gtk_box_pack_start

     ; Attach the unified VBox wrapper to the right grid area (col 3->4, row 1->8)
     table_attach [vbox_handle], 3, 4, 1, 8, 0, 0, GTK_SHRINK, GTK_SHRINK

     ; -------------------------------------------------------------------------
     ; 5. Assembly Layout Attachments & Signals
     ; -------------------------------------------------------------------------
     mov        rdi, [window_handle]
     mov        rsi, [table_handle]
     call       gtk_container_add

     ; Connect Main Window Close Signal
     xor        r9, r9
     xor        r8, r8
     mov        rcx, [window_handle]
     mov        rdx, gtk_main_quit
     mov        rsi, signal_destroy
     mov        rdi, [window_handle]
     call       g_signal_connect_data

     ; Connect Close Button Click Event to Exit Code
     xor        r9, r9
     xor        r8, r8
     mov        rcx, [window_handle]
     mov        rdx, gtk_main_quit
     mov        rsi, signal_clicked
     mov        rdi, [btn_close_handle]

     call       g_signal_connect_data
     ; Show All and Execute Loop
     mov        rdi, [window_handle]
     call       gtk_widget_show_all
     call       gtk_main
     xor        rdi, rdi
     call       exit

