rom.gb: main.o
	rgblink -n rom.sym -o $@ $^
	rgbfix -t 'ARC4 TEST' -v $@

main.o: main.asm include/ascii.2bpp include/hardware.asm include/library.asm rc4.asm
	rgbasm -o $@ $<

include/ascii.2bpp: include/ascii.png
	rgbgfx -d 1 -o $@ $^

clean:
	rm -f main.o
	rm -f rom.{gb,sym}
	rm -f include/ascii.2bpp
