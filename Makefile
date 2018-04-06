%.v: %.def.v
	vpp/vpp.pl $<

%.obj: %.asm
	./cdecas.pl -s $<
	ln -sf $@ ram.dat

cdec_test.v: cdec.def.v

%.sim: cdec_test.v %.obj
	cver $< RAM.v

clean:
	rm -f cdec_test.v *.obj ram.dat *.log
