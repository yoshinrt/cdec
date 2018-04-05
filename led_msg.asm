# LED gradation
loop:
	# M ? (^^;
	mvi	11111111b, B
	mvi	00001100b, B
	mvi	00110000b, B
	mvi	00110000b, B
	mvi	00001100b, B
	mvi	11111111b, B
	mvi	00000000b, B
	
	# S
	
	mvi	01000110b, B
	mvi	10001001b, B
	mvi	10001001b, B
	mvi	10010001b, B
	mvi	10010001b, B
	mvi	01100010b, B
	mvi	00000000b, B
	
	# T
	
	mvi	00000001b, B
	mvi	00000001b, B
	mvi	00000001b, B
	mvi	11111111b, B
	mvi	00000001b, B
	mvi	00000001b, B
	mvi	00000001b, B
	
	# blank
	
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	
	# T
	
	mvi	00000001b, B
	mvi	00000001b, B
	mvi	00000001b, B
	mvi	11111111b, B
	mvi	00000001b, B
	mvi	00000001b, B
	mvi	00000001b, B
	
	# S ( reversed )
	
	mvi	01100010b, B
	mvi	10010001b, B
	mvi	10010001b, B
	mvi	10001001b, B
	mvi	10001001b, B
	mvi	01000110b, B
	mvi	00000000b, B
	
	# M ? (^^;
	mvi	11111111b, B
	mvi	00001100b, B
	mvi	00110000b, B
	mvi	00110000b, B
	mvi	00001100b, B
	mvi	11111111b, B
	mvi	00000000b, B
	
	# blank
	
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	mvi	00000000b, B
	
	jmp	loop
