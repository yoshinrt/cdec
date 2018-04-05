@echo off
path %path%;c:\cygwin\bin
goto make_%Ext%

:make_
del *.cmp
del *.cnf
del *.dat
del *.dls
del *.inc
del *.list
del *.log
del *.mif
del *.err
del *.sym
del cdec
del cdec.cfv
del cdec.cfv.orig
del cdec.fit
del cdec.hex
del cdec.hif
del CDEC.list
del cdec.mmf
del cdec.ndb
del cdec.pin
del cdec.pof
del cdec.rpt
del cdec.sof
del cdec.snf
del cdec.ttf
del CDEC.v
del CDEC_TEST.v
del save.hist
goto quit

:make_asm
perl cdecas.pl -o RAM.mif %1 %2
goto quit

perl cdecas.pl -o RAM.DAT -sl %1 %2
move /y %Nde%.log %Nde%_exec.log > nul
perl cdecas.pl -o RAM.mif -e %1 %2
goto quit

:make_v
perl d:\dds\storm\bin\vpp.pl CDEC_TEST.def.v
perl d:\dds\storm\bin\vpp.pl CDEC.def.v		> nul
goto quit

:quit
