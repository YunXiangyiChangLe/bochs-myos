SECTION MBR vstart=0x7c00
    mov ax,cs
    mov ds,ax
    mov es,ax
    mov ss,ax
    mov fs,ax
    mov sp,0x7c00
    mov ax,0xb800
    mov gs,ax

;清屏
    mov ax,0x600
    mov bx,0x700
    mov cx,0x0
    mov dx,0x184f
    int 0x10

; ;获取光标位置
;     mov ah,3
;     mov bh,0
;     int 0x10

; ;打印字符串
;     mov ax,message
;     mov bp,ax
;     mov cx,9
;     mov ax,0x1301
;     mov bx,0x2
;     int 0x10


    mov byte [gs:0x00],'1'
    mov byte [gs:0x01],0xA4

    mov byte [gs:0x02],' '
    mov byte [gs:0x03],0xA4

    mov byte [gs:0x04],'M'
    mov byte [gs:0x05],0xA4

    mov byte [gs:0x06],'B'
    mov byte [gs:0x07],0xA4

    mov byte [gs:0x08],'R'
    mov byte [gs:0x09],0xA4



    jmp $

    message db "hello MBR"
    times 510-($-$$) db 0
    db 0x55,0xaa