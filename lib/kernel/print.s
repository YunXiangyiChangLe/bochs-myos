%include "print.inc"


[bits 32]
section .text

;打印字符串
global put_str
put_str:
    push ebx
    push ecx
    xor ecx,ecx
    mov ebx,[esp+12]
.goon 
    mov cl,[ebx]
    cmp cl,0
    jz .str_over
    push ecx
    call put_char
    pop ecx
    inc ebx
    jmp .goon
.str_over
    pop ecx
    pop ebx
    ret


;打印单个字符
global put_char
put_char:
    ;备份32位环境
    pushad
    ;存储视频段选择子
    mov ax,SELECT_VIDEO
    mov gs,ax
    ;获取当前光标的位置
    ;先获取高8位
    mov dx,0x03d4
    mov al,0x0e
    out dx,al
    mov dx,0x03d5
    in al,dx
    mov ah,al 
    ;再获取低8位
    mov dx,0x03d4
    mov al,0x0f
    out dx,al
    mov dx,0x03d5
    in al,dx
    ;光标存入dx
    mov bx,ax
    mov ecx,[esp+36]
    cmp cl,0xd;回车CR是0xd，换行LF是0xa，backspace（BS）是0x8
    jz .is_carriage_return
    cmp cl,0xa
    jz .is_line_feed
    cmp cl,0x8
    jz .is_backspace
    jmp .put_other

.is_backspace:
    dec bx
    shl bx,1
    mov byte [gs:bx],0x20
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    jmp .set_cursor

.put_other:
    shl bx,1
    mov [gs:bx],cl 
    inc bx
    mov byte [gs:bx],0x07
    shr bx,1
    inc bx
    cmp bx,2000
    jl .set_cursor
.is_line_feed:
.is_carriage_return:
    xor dx,dx
    mov ax,bx
    mov si,80
    div si
    sub bx,dx
.is_carriage_return_end:
    add bx,80
    cmp bx,2000
.is_line_feed_end:
    jl .set_cursor

;滚屏第一步先把1到24行搬运到0到23行
.roll_srceen:
    cld 
    mov ecx,960
    mov esi,0xb80a0
    mov edi,0xb8000
    rep movsd
;滚屏第二步，最后一行用空格填充
    mov ebx,3840
    mov ecx,80
.cls:
    mov word [gs:ebx],0x0720
    add ebx,2
    loop .cls
    mov bx,1920

;设置光标的值，先设置低8位
.set_cursor:
    mov dx,0x03d4
    mov al,0x0e
    out dx,al 
    mov dx,0x03d5
    mov al,bh
    out dx,al 
;再设置高8位
    mov dx,0x03d4
    mov al,0x0f
    out dx,al
    mov dx,0x03d5
    mov al,bl
    out dx,al 
.put_char_done:
    popad
    ret