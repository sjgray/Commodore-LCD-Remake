all: clean makeroms

clean:
	rm -f 27c*.bin kernal.bin kernal.hex kernal.lst kernal.o

makeroms: kernal.hex
	python3 makeroms.py

kernal.hex: kernal.bin
	srec_cat kernal.bin -binary -o kernal.hex -intel -address-length=2 -line-length=76 -crlf

kernal.bin: kernal.o
	ld65 -C kernal.ld -o kernal.bin kernal.o

kernal.o: kernal.asm
	ca65 -l kernal.lst kernal.asm
