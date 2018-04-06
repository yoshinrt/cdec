%.v: %.def.v
	vpp.pl $<

storm_test.v: storm.def.v storm.h

%.obj: %.asm
	./cdecas.pl -s $<
	ln -sf $@ ram.dat

cdec_test.v: cdec.def.v

%.sim: %.obj cdec_test.v
	cver $<

clean:
	rm -f storm_test.list storm_test.v verilog.log
