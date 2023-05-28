参考 操作系统真象还原 写的一个玩具os

bochs.out是运行过程中的日志文件

bochs.disk是配置文件

#nasm -o mbr.bin mbr.s

把mbr和loader写入磁盘，启动相关代码在boot目录下

nasm -I boot/include/ -o mbr.bin boot/mbr.s

dd if=mbr.bin of=bin/hd60M.img bs=512 count=1 conv=notrunc

nasm -I boot/include/ -o loader.bin boot/loader.s

dd if=loader.bin of=bin/hd60M.img bs=512 count=3 seek=2 conv=notrunc

bin/bochs -f bochsrc.disk

kernel相关代码在文件夹kernel目录下

gcc -c -o kernel/main.o kernel/main.c -m32  #源程序编译汇编到目标代码，不进行链接

ld -m elf_i386 kernel/main.o -Ttext 0xc0001500 -e main -o kernel/kernel.bin   #链接