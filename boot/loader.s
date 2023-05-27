%include "boot.inc"

SECTION LOADER vstart=LOADER_BASE_ADDR
LOAD_STACK_TOP equ LOADER_BASE_ADDR

    jmp loader_start 

    GDT_BASE: dd 0x00000000
                dd 0x00000000
    CODE_DESC: dd 0x0000ffff
                dd DESC_CODE_HIGH4
    DATA_STACK_DESC: dd 0x0000ffff
                dd DESC_DATA_HIGH4
    VIDEO_DESC: dd 0x80000007
                dd DESC_VIDEO_HIGH4
    GDT_SIZE equ $-GDT_BASE
    GDT_LIMIT equ GDT_SIZE-1
    times 60 dq 0

    SECTEROR_CODE equ (0x1<<3)+TI_GDT+RPL0
    SECRETOR_DATA equ (0x2<<3)+TI_GDT+RPL0
    SECTEROR_VIDIO equ (0x3<<3)+TI_GDT+RPL0

    gdt_ptr dw GDT_LIMIT
                dd GDT_BASE
    loadermsg db '2 loader in real.'

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

    ;创建页目录及页表并初始化页内存图
    call setup_page
    sgdt [gdt_ptr]
    mov ebx,[gdt_ptr+2]
    or dword [ebx+0x18+4],0xc0000000
    add dword [gdt_ptr+2],0xc0000000
    add esp,0xc0000000

    mov eax,PAGE_DIR_TABLE_POS
    mov cr3,eax

    mov eax,cr0
    or eax,0x80000000
    mov cr0,eax

    lgdt [gdt_ptr]

    mov byte [gs:160],'V'
    jmp $

;    mov byte [gs:160],'P'

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
.creat_pde:
    mov eax,PAGE_DIR_TABLE_POS
    add eax,0x1000
    mov ebx,eax;第一个页表的位置

    or eax,PG_US_U|PG_RW_W|PG_P
    mov [PAGE_DIR_TABLE_POS+0x0],eax
    mov [PAGE_DIR_TABLE_POS+0xc00],eax
    sub eax,0x1000
    mov [PAGE_DIR_TABLE_POS+4092],eax

    ;创建页表项(PTE)
    mov ecx,256
    mov esi,0
    mov edx,PG_US_U|PG_RW_W|PG_P
.creat_pte:
    mov [ebx+esi*4],edx
    add edx,4096
    inc esi
    loop .creat_pte

    ;创建内核其他页表的PDE
    mov eax,PAGE_DIR_TABLE_POS
    add eax,0x2000
    or eax,PG_US_U|PG_RW_W|PG_P
    mov ebx,PAGE_DIR_TABLE_POS
    mov ecx,254
    mov esi,769
.creat_lernel_pde:
    mov [ebx+esi*4],eax
    inc esi
    add eax,0x1000
    loop .creat_lernel_pde
    ret