参考 操作系统真象还原 写的一个玩具os

bochs.out是运行过程中的日志文件

bochs.disk是配置文件

#nasm -o mbr.bin mbr.s

nasm -I boot/include/ -o mbr.bin boot/mbr.s

dd if=mbr.bin of=bin/hd60M.img bs=512 count=1 conv=notrunc

bin/bochs -f bochsrc.disk



nasm -I boot/include/ -o loader.bin boot/loader.s

dd if=loader.bin of=bin/hd60M.img bs=512 count=2 seek=2 conv=notrunc