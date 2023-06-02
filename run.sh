nasm -I boot/include/ -o mbr.bin boot/mbr.s&&
dd if=mbr.bin of=bin/hd60M.img bs=512 count=1 conv=notrunc&&
nasm -I boot/include/ -o loader.bin boot/loader.s&&
dd if=loader.bin of=bin/hd60M.img bs=512 count=3 seek=2 conv=notrunc&&
nasm -I lib/kernel/include/ -f elf -o lib/kernel/print.o lib/kernel/print.s&&
gcc -I lib/kernel/ -c -o kernel/main.o kernel/main.c -m32&&
ld -m elf_i386 -Ttext 0xc0001500 -e main -o kernel/kernel.bin kernel/main.o lib/kernel/print.o&&
dd if=kernel/kernel.bin of=bin/hd60M.img bs=512 count=200 seek=9 conv=notrunc&&
bin/bochs -f bochsrc.disk