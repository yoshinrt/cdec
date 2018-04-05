hex	equ	0ABh
bin	equ	10101100b
oct	equ	0666

	ld	Imm10, A
Loop:	dec	A
	jz	ExitLoop
	jmp	Loop
	
	db	hex, bin, oct
	
	org	10h
	
ExitLoop:
l1:	mov	A, B
	mvi	0xFF, B
	stx	C, A
	ld	var1, B
	ldx	A, B
	st	C, var2
	
l2:	add	A
	adc	B
	sub	C
	cmp	C
	sbb	A
	and	A
	or	B
	eor	A
	dec	A
	shr	A
	shl	A
	shl	A
	inc	A
	not	C
	
	pcal	Sub1
	cal	Sub
	
	jz	l2
	jc	l3
	js	$ + 2
	jmp	$
	
Sub:	ret
Sub1:	pret
	
var1:	db	0, 1 + 2 * 3
var2:	db	$, hex + var1
Imm10:	db	10
	
l3:	end
