参考 操作系统真象还原 写的一个玩具os

nasm -o mbr.bin mbr.s

dd if=mbr.bin of=bin/hd60M.img bs=512 count=1 conv=notrunc

bin/bochs -f bochsrc.disk