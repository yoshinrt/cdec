# LED gradation

Loop:
	ld	iLEDCnt, A	; iLEDCnt = ( iLEDCnt + 1 ) % 8
	inc	A
	mvi	7, C
	and	C
	st	A, iLEDCnt
	
	mvi	LEDData, C	; A = &LEDData[ iLEDCnt ]
	add	C
	
	ldx	A, B		; B = LEDData[ iLEDCnt ]
	
	jmp	Loop;
	
LEDData:
	db	10000000b
	db	11101000b
	db	11100000b
	db	11111010b
	db	11010000b
	db	11111100b
	db	11110100b
	db	11111111b

iLEDCnt:db	0
