%include "boot.inc"

SECTION LOADER vstart=LOADER_BASE_ADDR
LOAD_STACK_TOP equ LOADER_BASE_ADDR

    jmp loader_start 

    GDT_BASE: dd 0x00000000
                dd 0x00000000
    CODE_DESC: dd 0x0000ffff
                dd DESC_CODE_HIGH4
    DATA_DESC: dd 0x0000ffff
                dd DESC_DATA_HIGH4
    VIDEO_DESC: dd 0x80000007
                dd DESC_VIDEO_HIGH4
    GDT_SIZE equ $-GDT_BASE
    GDT_LIMIT equ GDT_SIZE
    times 60 dq 0

    SECTEROR_CODE equ (0x1<<3)+TI_GDT+RPL0
    SECRETOR_DATA equ (0x2<<3)+TI_GDT+RPL0
    SECTEROR_VIDIO equ (0x3<<3)+TI_GDT+RPL0

    gdt_ptr dw GDT_LIMIT
                dd GDT_BASE
    loadermsg db '2 loader in real'

    loader_start:
    mov sp,LOADER_BASE_ADDR
    mov bp,loadermsg
    mov cx,17
    mov ax,0x1301
    mov bx,0x001f
    mov dx,0x1800
    int 0x10


;------进入保护模式--------
    in al,0x92
    or al,00000010b
    out 0x92,al 

    lgdt [gdt_ptr]

    mov eax,cr0
    or eax,0x00000001
    mov cr0,eax

    jmp dword SECTEROR_CODE:p_mode_start

[bits 32]
    p_mode_start:
    mov ax,SECRETOR_DATA
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov esp,LOAD_STACK_TOP
    mov ax,SECTEROR_VIDIO
    mov gs,ax

    mov byte [gs:160],'P'

;    jmp $




;---------创建页目录和页表-----------
setup_page:
    ;先清空页目录中的字节，因为内存中可能会出现一些随机字节
    mov ecx,4096
    mov esi,0
.clear_page_dir:
    mov byte [PAGE_DIR_TABLE_POS+esi],0
    inc esi
    loop .clear_page_dir

    ;创建页目录项(PDE)
    