section .data 
str_c_lib dd "c library says: hello world!",0xa
str_c_lib_len equ $-str_c_lib

str_syscall dd "syscall says: hello world!",0xa
str_syscall_len equ $-str_syscall

section .text
global _start 
_start:
    ;模拟c中系统调用库函数write
    push str_c_lib_len
    push str_c_lib
    push 1
    call simu_write
    add esp ,12

    ;跨过库函数直接进行系统调用
    mov eax,4
    mov ebx,1
    mov ecx,str_syscall
    mov edx,str_syscall_len
    int 0x80

    ;退出程序
    mov eax,1
    int 0x80


simu_write:
    push ebp
    mov ebp,esp
    mov eax,4
    mov ebx,[ebp+8]
    mov ecx,[ebx+12]
    mov edx,[ebx+16]
    int 0x80
    pop ebp
    ret