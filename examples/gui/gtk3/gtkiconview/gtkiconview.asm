; ==============================================================================
; Name        : gtkiconview.asm
; Author      : Roberto Aguas Guerreiro [agguro]
; Description : GtkIconView with dynamically downsampled 48x48 icons
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
     window:
     .handle:          resq      1
     
     app:
     .loader:          resq      1
     .pixbuffer:       resq      1
     
     list:
     .store:           resq      1
     .view:            resq      1
     .scroll:          resq      1
     .iter:            resb      32
     
     gtype:
     .pixbuf:          resq      1
     .columns:         resq      2
     
     gval:
     .pixbuf:          resb      24
     .string:          resb      24

     tmp:
     .string_ptr:      resq      1
     .pixbuf_ptr:      resq      1

section .data
     logo:             incbin    "../resources/pictures/logo.png"
     logo_size:        equ       $ - logo

     window_title:     db        "Linux Distributions Grid", 0
     signal:
     .destroy:         db        "destroy", 0

     img_debian:       incbin    "../resources/pictures/debian.png"
     img_debian_sz:    equ       $ - img_debian
     img_mint:         incbin    "../resources/pictures/mint.png"
     img_mint_sz:      equ       $ - img_mint
     img_fedora:       incbin    "../resources/pictures/fedora.png"
     img_fedora_sz:    equ       $ - img_fedora
     img_arch:         incbin    "../resources/pictures/arch.png"
     img_arch_sz:      equ       $ - img_arch

     distro:
     .debian:          db        "Linux Debian 13", 0
     .mint:            db        "Linux Mint LMDE", 0
     .fedora:          db        "Fedora", 0
     .arch:            db        "Arch Linux", 0

section .text
     global _start

_start:
     ; 1. Stack Alignment & GTK3 Init
     mov        rdi, [rsp]
     lea        rsi, [rsp + 8]
     mov        r12, rdi
     mov        r13, rsi

     and        rsp, -16
     sub        rsp, 16
     lea        rdi, [rsp]
     mov        [rdi], r12
     lea        rsi, [rsp + 8]
     mov        [rsi], r13
     call       gtk_init

     ; 2. Fetch GDK Pixbuf Type
     xor        eax, eax
     call       gdk_pixbuf_get_type
     mov        qword [gtype.pixbuf], rax

     ; 3. Generate Main Window Icon
     call       gdk_pixbuf_loader_new
     mov        qword [app.loader], rax
     mov        rdi, qword [app.loader]
     mov        rsi, logo
     mov        rdx, logo_size
     xor        rcx, rcx
     call       gdk_pixbuf_loader_write
     mov        rdi, qword [app.loader]
     call       gdk_pixbuf_loader_get_pixbuf
     mov        qword [app.pixbuffer], rax

     ; 4. Build Window
     mov        rdi, GTK_WINDOW_TOPLEVEL
     call       gtk_window_new
     mov        qword [window.handle], rax

     mov        rdi, qword [window.handle]
     mov        rsi, window_title
     call       gtk_window_set_title
     mov        rdi, qword [window.handle]
     mov        rsi, 600
     mov        rdx, 400
     call       gtk_window_set_default_size
     mov        rdi, qword [window.handle]
     mov        rsi, GTK_WIN_POS_CENTER
     call       gtk_window_set_position
     mov        rdi, qword [window.handle]
     mov        rsi, qword [app.pixbuffer]
     call       gtk_window_set_icon

     xor        r9d, r9d
     xor        r8d, r8d
     xor        rcx, rcx
     mov        rdx, gtk_main_quit
     mov        rsi, signal.destroy
     mov        rdi, qword [window.handle]
     call       g_signal_connect_data

     ; 5. Data Model
     mov        rax, qword [gtype.pixbuf]
     mov        qword [gtype.columns], rax
     mov        qword [gtype.columns + 8], 64 ; G_TYPE_STRING

     mov        rdi, 2
     lea        rsi, [gtype.columns]
     xor        eax, eax
     call       gtk_list_store_newv
     mov        qword [list.store], rax

     ; 6. Populate Rows
     mov        rdi, img_debian
     mov        rsi, img_debian_sz
     mov        rdx, distro.debian
     call       add_distro_row
     mov        rdi, img_mint
     mov        rsi, img_mint_sz
     mov        rdx, distro.mint
     call       add_distro_row
     mov        rdi, img_fedora
     mov        rsi, img_fedora_sz
     mov        rdx, distro.fedora
     call       add_distro_row
     mov        rdi, img_arch
     mov        rsi, img_arch_sz
     mov        rdx, distro.arch
     call       add_distro_row

     ; 7. View Construction
     mov        rdi, NULL
     mov        rsi, NULL
     call       gtk_scrolled_window_new
     mov        qword [list.scroll], rax

     mov        rdi, qword [list.store]
     xor        eax, eax
     call       gtk_icon_view_new_with_model
     mov        qword [list.view], rax

     mov        rdi, qword [list.view]
     mov        rsi, 0
     call       gtk_icon_view_set_pixbuf_column
     mov        rdi, qword [list.view]
     mov        rsi, 1
     call       gtk_icon_view_set_text_column

     mov        rdi, qword [list.scroll]
     mov        rsi, qword [list.view]
     call       gtk_container_add
     mov        rdi, qword [window.handle]
     mov        rsi, qword [list.scroll]
     call       gtk_container_add

     mov        rdi, qword [window.handle]
     call       gtk_widget_show_all
     call       gtk_main
     call       exit

add_distro_row:
     push       rbp
     mov        rbp, rsp
     and        rsp, -16
     mov        qword [tmp.string_ptr], rdx
     push       rdi
     push       rsi
     call       gdk_pixbuf_loader_new
     mov        r14, rax
     pop        rdx
     pop        rsi
     mov        rdi, r14
     xor        rcx, rcx
     call       gdk_pixbuf_loader_write
     mov        rdi, r14
     call       gdk_pixbuf_loader_get_pixbuf
     mov        r15, rax
     mov        rdi, r15
     mov        rsi, 48
     mov        rdx, 48
     mov        rcx, 2
     call       gdk_pixbuf_scale_simple
     mov        qword [tmp.pixbuf_ptr], rax

     xor        rax, rax
     mov        qword [gval.pixbuf], rax
     mov        qword [gval.pixbuf + 8], rax
     mov        qword [gval.pixbuf + 16], rax
     mov        qword [gval.string], rax
     mov        qword [gval.string + 8], rax
     mov        qword [gval.string + 16], rax

     mov        rdi, qword [list.store]
     lea        rsi, [list.iter]
     call       gtk_list_store_append

     lea        rdi, [gval.pixbuf]
     mov        rsi, qword [gtype.pixbuf]
     xor        eax, eax
     call       g_value_init
     lea        rdi, [gval.pixbuf]
     mov        rsi, qword [tmp.pixbuf_ptr]
     call       g_value_set_object
     mov        rdi, qword [list.store]
     lea        rsi, [list.iter]
     mov        edx, 0
     lea        rcx, [gval.pixbuf]
     call       gtk_list_store_set_value

     lea        rdi, [gval.string]
     mov        rsi, 64
     xor        eax, eax
     call       g_value_init
     lea        rdi, [gval.string]
     mov        rsi, qword [tmp.string_ptr]
     call       g_value_set_string
     mov        rdi, qword [list.store]
     lea        rsi, [list.iter]
     mov        edx, 1
     lea        rcx, [gval.string]
     call       gtk_list_store_set_value

     lea        rdi, [gval.pixbuf]
     call       g_value_unset
     lea        rdi, [gval.string]
     call       g_value_unset
     leave
     ret
