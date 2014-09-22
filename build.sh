# args:
#	b = build and copy bootloader
#	r = run virtual machine	

clear
echo "!?! Note, floppy image must be mounted first"
cd asm
echo "### Assembling kernel"
nasm -f bin kernel.s -o ../bin/kernel.bin

if [ "$1" = "b" -o "$2" = "b" -o  "$3" = "b" -o "$4" = "b" ]
then
	echo "### Assembling bootloader"
	nasm -f bin boot1.s -o ../bin/boot1.bin
	nasm -f bin boot2.s -o ../bin/boot2.bin
	cd ..
	echo "### Copying bootloader"
	./sfk partcopy bin/boot1.bin 0 512 ~/Desktop/floppy.img 0 -yes
	sudo cp -v "bin/boot2.bin" "/Volumes/FLOPPY/boot2.bin"
else
	cd ..
fi

echo "### Copying kernel"
sudo cp -v "bin/kernel.bin" "/Volumes/FLOPPY/KERNEL.BIN"

if [ "$1" = "s" -o "$2" = "s" -o  "$3" = "s" -o "$4" = "s" ]
then
	echo "### Shutting down vm"
	VBoxManage controlvm "MyOS" poweroff
fi

if [ "$1" = "r" -o "$2" = "r" -o  "$3" = "r" -o "$4" = "r" ]
then
	echo "### Running vm"
	VBoxManage startvm "MyOS"
fi
