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


    ;---------加载内核----------
    mov eax,KERNEL_START_SECTOR
    mov ebx,KERNEL_BIN_BASE_ADDR
    mov ecx,200
    call rd_disk_m_32

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
    jmp SECTEROR_CODE:enter_kernel


    ; mov byte [gs:160],'V'
    ; jmp $

;    mov byte [gs:160],'P'

;    jmp $
enter_kernel:
    call kernel_init
    mov esp, 0xc009f000
    jmp KERNEL_ENTER_POINT


kernel_init:
    xor eax,eax
    xor ebx,ebx  ;ebx程序头表的地址
    xor ecx,ecx  ;cx程序头表中program header的数量
    xor edx,edx  ;dx记录program header尺寸，即e_phentsize的大小
    mov dx, [KERNEL_BIN_BASE_ADDR+42]
    mov ebx, [KERNEL_BIN_BASE_ADDR+28]
    add ebx,KERNEL_BIN_BASE_ADDR
    mov cx, [KERNEL_BIN_BASE_ADDR+44]
.each_segment:
    cmp byte [ebx+0],PT_NULL
    je .PTNULL
    push dword [ebx+16]
    mov eax,[ebx+4]
    add eax,KERNEL_BIN_BASE_ADDR
    push eax
    push dword [ebx+8]
    call mem_cpy
    add esp,12
.PTNULL:
    add ebx,edx
    loop .each_segment
    ret

mem_cpy:
    cld
    push ebp
    mov esp,ebp
    push ecx
    mov edi, [ebp+8]
    mov esi, [ebp+12]
    mov ecx, [ebp+16]
    rep movsb
    pop ecx
    pop ebp
    ret


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



rd_disk_m_32:	   
;-------------------------------------------------------------------------------
							 ; eax=LBA扇区号
							 ; ebx=将数据写入的内存地址
							 ; ecx=读入的扇区数
      mov esi,eax	   ; 备份eax
      mov di,cx		   ; 备份扇区数到di
;读写硬盘:
;第1步：设置要读取的扇区数
      mov dx,0x1f2
      mov al,cl
      out dx,al            ;读取的扇区数

      mov eax,esi	   ;恢复ax

;第2步：将LBA地址存入0x1f3 ~ 0x1f6

      ;LBA地址7~0位写入端口0x1f3
      mov dx,0x1f3                       
      out dx,al                          

      ;LBA地址15~8位写入端口0x1f4
      mov cl,8
      shr eax,cl
      mov dx,0x1f4
      out dx,al

      ;LBA地址23~16位写入端口0x1f5
      shr eax,cl
      mov dx,0x1f5
      out dx,al

      shr eax,cl
      and al,0x0f	   ;lba第24~27位
      or al,0xe0	   ; 设置7～4位为1110,表示lba模式
      mov dx,0x1f6
      out dx,al

;第3步：向0x1f7端口写入读命令，0x20 
      mov dx,0x1f7
      mov al,0x20                        
      out dx,al

;;;;;;; 至此,硬盘控制器便从指定的lba地址(eax)处,读出连续的cx个扇区,下面检查硬盘状态,不忙就能把这cx个扇区的数据读出来

;第4步：检测硬盘状态
  .not_ready:		   ;测试0x1f7端口(status寄存器)的的BSY位
      ;同一端口,写时表示写入命令字,读时表示读入硬盘状态
      nop
      in al,dx
      and al,0x88	   ;第4位为1表示硬盘控制器已准备好数据传输,第7位为1表示硬盘忙
      cmp al,0x08
      jnz .not_ready	   ;若未准备好,继续等。

;第5步：从0x1f0端口读数据
      mov ax, di	   ;以下从硬盘端口读数据用insw指令更快捷,不过尽可能多的演示命令使用,
			   ;在此先用这种方法,在后面内容会用到insw和outsw等

      mov dx, 256	   ;di为要读取的扇区数,一个扇区有512字节,每次读入一个字,共需di*512/2次,所以di*256
      mul dx
      mov cx, ax	   
      mov dx, 0x1f0
  .go_on_read:
      in ax,dx		
      mov [ebx], ax
      add ebx, 2
			  ; 由于在实模式下偏移地址为16位,所以用bx只会访问到0~FFFFh的偏移。
			  ; loader的栈指针为0x900,bx为指向的数据输出缓冲区,且为16位，
			  ; 超过0xffff后,bx部分会从0开始,所以当要读取的扇区数过大,待写入的地址超过bx的范围时，
			  ; 从硬盘上读出的数据会把0x0000~0xffff的覆盖，
			  ; 造成栈被破坏,所以ret返回时,返回地址被破坏了,已经不是之前正确的地址,
			  ; 故程序出会错,不知道会跑到哪里去。
			  ; 所以改为ebx代替bx指向缓冲区,这样生成的机器码前面会有0x66和0x67来反转。
			  ; 0X66用于反转默认的操作数大小! 0X67用于反转默认的寻址方式.
			  ; cpu处于16位模式时,会理所当然的认为操作数和寻址都是16位,处于32位模式时,
			  ; 也会认为要执行的指令是32位.
			  ; 当我们在其中任意模式下用了另外模式的寻址方式或操作数大小(姑且认为16位模式用16位字节操作数，
			  ; 32位模式下用32字节的操作数)时,编译器会在指令前帮我们加上0x66或0x67，
			  ; 临时改变当前cpu模式到另外的模式下.
			  ; 假设当前运行在16位模式,遇到0X66时,操作数大小变为32位.
			  ; 假设当前运行在32位模式,遇到0X66时,操作数大小变为16位.
			  ; 假设当前运行在16位模式,遇到0X67时,寻址方式变为32位寻址
			  ; 假设当前运行在32位模式,遇到0X67时,寻址方式变为16位寻址.

      loop .go_on_read
      ret
