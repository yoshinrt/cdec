; multiply 16bit <-- 8bit x 8bit

	ld	TestBit, B
	
Loop:	ld	Data0, A	; test Data0, TestBit
	and	B
	
	jz	skip1		; ifnz {
	
	ld	Data1, A	;   Ans += Data1 (L)
	ld	Ans,   C
	add	C
	st	A, Ans
	
	ld	Data1 + 1, A	;   (H)
	ld	Ans + 1,   C
	adc	C
	st	A, Ans + 1
	
skip1:				; }
	
	ld	Data1, A	; Data1 <<= 1 (L)
	add	A
	st	A, Data1
	
	ld	Data1 + 1, A	; (H)
	adc	A
	st	A, Data1 + 1
	
	
	mov	B, A		; TestBit <<= 1
	add	A
	mov	A, B
	jz	$		; if( TestBit == 0 ) quit;
	
	jmp	Loop
	
;*** data area ***
	org	40h
Data0:	db	0xAA
Data1:	db	0xAA, 0
TestBit:db	1
	
	org	80h
Ans:	db	0, 0
