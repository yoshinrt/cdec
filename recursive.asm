; sum of 1 to 10 using recursive call
	
	mvi	10, B
	mvi	0, A
	mvi	0, C
	
	pcal	Sum
	jmp	$
	
Sum:	push	B
	dec	B	; if( B != 1 ){
	jz	Sum1
	
	pcal	Sum	;   return( Sum( B - 1 )
	pop	B
	add	B	;     + B );
	pret
			; }else{
Sum1:	pop	A	;   A = 1;
	pret		;   return( 1 )
			; };
