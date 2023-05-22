参考 操作系统真象还原 写的一个玩具os

bochs.out是运行过程中的日志文件

bochs.disk是配置文件

#nasm -o mbr.bin mbr.s
nasm -I mbr/include/ -o mbr.bin mbr/mbr.s

dd if=mbr.bin of=bin/hd60M.img bs=512 count=1 conv=notrunc

bin/bochs -f bochsrc.disk