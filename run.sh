nasm -I boot/include/ -o mbr.bin boot/mbr.s&&

#mbr写入硬盘的第0个扇区
dd if=mbr.bin of=bin/hd60M.img bs=512 count=1 conv=notrunc&&

nasm -I boot/include/ -o loader.bin boot/loader.s&&

#loader写入硬盘的第2个扇区
dd if=loader.bin of=bin/hd60M.img bs=512 count=3 seek=2 conv=notrunc&&

#汇编print.s
nasm -I lib/kernel/include/ -f elf -o lib/kernel/print.o lib/kernel/print.s&&

#编译main.o    源程序编译汇编到目标代码，不进行链接
gcc -I lib/kernel/ -c -o kernel/main.o kernel/main.c -m32&&

#链接
ld -m elf_i386 -Ttext 0xc0001500 -e main -o kernel/kernel.bin kernel/main.o lib/kernel/print.o&&

#内核写入硬盘的第9个扇区
dd if=kernel/kernel.bin of=bin/hd60M.img bs=512 count=200 seek=9 conv=notrunc&&

bin/bochs -f bochsrc.disk