#!/usr/bin/perl

#*****************************************************************************
#
#		CDEC assembler v1.00
#		Copyright(C) by Yoshihisa Tanaka
#
#*****************************************************************************

$CSymbol = '\b[_a-zA-Z]\w*\b';

if( 1 ){	# 0:ASIC 改版  1:完全版
	
	# CDEC 完全版 ISA
	@InsnTbl = (
		'0x00	rr	mov',
		'0xC1	ir	mvi',
		'0x80	ir	ld',
		'0x90	rr	ldx',
		'0xA0	ri	st',
		'0xB0	rr	stx',
		
		'0xD4	r	push',
		'0xD0	*r	pop',
		
		'0x20	*r	add',
		'0x24	*r	adc',
		'0x28	*r	sub',
		'0x2C	*r	sbb',
		'0x30	*r	and',
		'0x34	*r	or',
		'0x38	*r	cmp',
		'0x3C	*r	eor',
		'0x40	*r	inc',
		'0x44	*r	dec',
		'0x48	*r	shr',
		'0x4C	*r	shl',
		'0x50	*r	not',
		
		'0xC0	i	jmp',
		'0xE4	i	jc',
		'0xE8	i	jz',
		'0xEC	i	jns',
		'0xF0	i	js',
		'0xF4	i	jnz',
		'0xF8	i	jnc',
		
		'0x60	i	cal',
		'0x61	i	pcal',
		'0x0C	-	ret',
		'0x62	-	pret',
		
		'org	i	org',
		'db		*	db',
		'equ	i	equ',
		'end	-	end',
		
		'0xFF	*	;'
	);
}else{
	# ASIC 改版 ISA
	@InsnTbl = (
		'0x00	-	nop',
		'0x01	-	hlt',
		'0x04	*r	seg',
		
		'0x60	rr	mov',
		'0x80	ir	ld',
		'0xA0	ri	st',
		
		'0x20	*r	add',
		'0x24	*r	adc',
		'0x28	*r	sub',
		'0x2C	*r	sbb',
		'0x30	*r	and',
		'0x34	*r	or',
		'0x3C	*r	eor',
		'0x40	*r	inc',
		'0x44	*r	dec',
		'0x50	*r	not',
		
		'0xC0	i	jmp',
		'0xE4	i	jc',
		'0xE8	i	jz',
		'0xF0	i	js',
		
		'org	i	org',
		'db		*	db',
		'equ	i	equ',
		'end	-	end',
		
		'0xFF	*	;'
	);
}

&main();
exit( 0 );

### main procedure ###########################################################

sub main{
	
	local( $i );
	
	while( $ARGV[ 0 ] =~ /^-/ ){
		
		if( $ARGV[ 0 ] eq "-o" ){
			$DstFile = $ARGV[ 1 ];
			shift( @ARGV );
			
		}else{
			$bSimOut = 1 if( $ARGV[ 0 ] =~ /s/ );
			$bExec   = 1 if( $ARGV[ 0 ] =~ /[Eel]/ );
			$bMrgSrc = 1 if( $ARGV[ 0 ] =~ /e/ );
			$bMrgAsm = 1 if( $ARGV[ 0 ] =~ /E/ );
		}
		
		shift( @ARGV );
	}
	
	if( $#ARGV < 0 ){
		$0 =~ /[^\\\/]+$/;
		print( "usage : $& [-eEls] [-o <output file>] <source file>\n" );
		return;
	}
	
	# setup file name
	
	$SceFile = $ARGV[ 0 ];
	
	$SceFile  =~ /(.*)\./;
	$BaseName = ( $1 ne "" ) ? $1 : $SceFile;
	$DstFile  = $BaseName . (( $bSimOut ) ? ".obj" : ".mif" ) if( $DstFile eq "" );
	$LogFile  = "$BaseName.log";
	
	# setup instruction table
	
	&SetupInsnTbl();
	
	# 0 clear CodeBuf
	
	for( $i = 0; $i < 0x100; ++$i ){
		$CodeBuf[ $i ] = 0;
	}
	
	# assemble
	
	$i = &Parser();
	$i = &Parser() if( !$bError && $bRedoAsm );
	
	# undef clear CodeBuf
	
	for( ; $i < 0x100; ++$i ){
		$CodeBuf[ $i ] = ();
	}
	
	
	if( $bError ){
		unlink( $DstFile );
		return;
	}
	
	# execute
	
	&Simulator() if( $bExec );
}

### parser ###################################################################

sub Parser{
	
	$LineCnt = 0;
	$LocCnt	 = 0;
	
	local(
		$Label,
		$Optype,
		$Code,
		$CodeSize,
		$Line,
		$Line2,
		$Opr1,
		$Imm,
		$i,
		$Col
	);
	
	if( !open( fpIn, "< $SceFile" )){
		print( "Can't open file \"$SceFile\"\n" );
		$bError = 1;
		return;
	}
	open( fpOut, "> $DstFile" );
	if( !$bSimOut ){
		$0 =~ /[^\\\/]+$/;
		print( fpOut <<EOF );
-- $& - generated Memory Initialization File

WIDTH = 8;
DEPTH = 256;
ADDRESS_RADIX = HEX;
DATA_RADIX = HEX;
CONTENT BEGIN 0:

-- Code                 -- Addr   Line: Source code
EOF
		$ObjComment = "--"
		
	}else{
		print( fpOut "// Code                 // Addr   Line: Source code\n" );
		$ObjComment = "//"
	}
	
	while( $Line = <fpIn> ){
		
		$Line =~ s/[\x0D\x0A]//g;
		$SceBuf[ $LineCnt++ ] = $Line;
		
		$Imm	  = "";
		$CodeSize = 0;
		
		# 1行解析
		
		( $Label, $Optype, $Code, $Line2 ) = &LineParser( $Line );
		#print( "parser:$LineCnt>$Label, $Optype, $Code, $Line2\n" );
		
		### opr 解析処理 #####################################################
		
		if( $Optype eq '-' && $Line2 !~ /^\s*$/ ){
			# 不要なオペランドが指定された
			Error( "disused operand exists" );
			next;
		}
		
		if( $Optype ne '*' ){
			
			if( $Optype !~ /^\*/ ){
				if( $Line2 =~ /,/ ){
					$Opr1  = $`;
					$Line2 = $';
				}else{
					$Opr1  = $Line2;
					$Line2 = "";
				}
			}
			
			# opr1 解析
			
			if( $Optype =~ '^i' ){
				$Imm = &ImmExpression( $Opr1 )
			}elsif( $Optype =~ '^r' ){
				$Code = $Code & ~0x0C | ( &GetRegNumber( $Opr1 ) << 2 );
			}
			
			# opr2 解析
			
			if( $Optype =~ '^.i' ){
				$Imm = &ImmExpression( $Line2 )
				
			}elsif( $Optype =~ '^.r' ){
				$Code = $Code & ~0x03 | &GetRegNumber( $Line2 );
				
			}elsif( $Line2 !~ /^\s*/ ){
				# 不要なオペランドが指定された
				Error( "disused operand exists" );
				next;
			}
		}
		
		### equ 処理 #########################################################
		
		if( $Code eq 'equ' ){
			
			Error( "syntax error" ) if( $Label eq "" );
			&DefineLabel( $Label, $Imm );
			
			goto PutCode;
		}
		
		### Label 定義 #######################################################
		
		&DefineLabel( $Label, $LocCnt ) if( $Label ne "" );
		
		# opecode がなければ次
		
		goto PutCode if( $Optype eq "" );
		
		### org ##############################################################
		
		if( $Code eq "org" ){
			
			if(( $CodeSize = $Imm - $LocCnt ) < 0 ){
				Error( "org address exceeded \$" );
				$CodeSize = 0;
			}
		}
		
		### db ###############################################################
		
		elsif( $Code eq "db" ){
			while( $Line2 ne "" ){
				$Line2 =~ /([^,]+),?(.*)/;
				$Line2 = $2;
				$CodeBuf[ $LocCnt + $CodeSize ] = &ImmExpression( $1 );
				++$CodeSize;
			}
		}
		
		### put code #########################################################
		
	  PutCode:
		
		if( $Code =~ /^\d/ ){
			$CodeBuf[ $LocCnt + $CodeSize++ ] = $Code;
			$CodeBuf[ $LocCnt + $CodeSize++ ] = $Imm if( $Imm ne "" );
		}
		
		$Col = 0;
		
		# print obj code
		
		$Line = sprintf( "\t%6d: %s", $LineCnt, $Line );
		
		if( $CodeSize ){
			for( $i = 0; $i < $CodeSize; ++$i, ++$Col ){
				
				$CodeBuf[ $LocCnt + $i ] &= 0xFF;
				
				if( $Col >= 8 ){
					printf( fpOut "$ObjComment %02X%s\n", $LocCnt, $Line );
					
					$Line = "";
					$Col  = 0;
					$LocCnt += 8;
				}
				printf( fpOut "%02X ", $CodeBuf[ $LocCnt + $i ] );
			}
			printf( fpOut "%s$ObjComment %02X%s\n", ' ' x (( 8 - $Col ) * 3 ), $LocCnt, $Line );
			
		}elsif( $Label ne "" ){
			printf( fpOut " " x 24 . "$ObjComment %02X$Line\n", $LabelList{ $Label } );
		}else{
			print( fpOut " " x 24 . "$ObjComment   $Line\n" );
		}
		
		# $Loc --> ソースコード行 LUT 構築
		
		$Loc2Line[ $LocCnt ] = $LineCnt;
		
		$LocCnt += $Col;
		
		last if( $Code eq "end" );
		
		if( $LocCnt > 256 ){
			Error( "Code size exceeded 256bytes" );
			last;
		}
	}
	
	# 終了
	
	print( fpOut "; END;\n" ) if( !$bSimOut );
	
	close( fpOut );
	close( fpIn );
	
	++$PathCnt;
	
	return( $LocCnt );
}

### line parser ##############################################################

sub LineParser{
	
	local( $Line ) = @_;
	local(
		$Label,
		$Mnemonic,
		$Code,
		$Optype,
		$i
	);
	
	# delete comment
	$Line =~ s/;.*//g;
	
	### label 判別 ###########################################################
	
	if( $Line =~ /^\s*($CSymbol):(.*)/ ){
		# label
		$Label = $1;
		$Line  = $2;
		
	}else{
		# mnemonic か label か，まだ不明
		$Line =~ /^\s*($CSymbol)(.*)/;
		
		$Label	  = $1;
		$Line	  = $2;
		$Mnemonic = $1;
		$Mnemonic =~ tr/A-Z/a-z/;
		
		if( defined( $OpecodeIdx{ $Mnemonic } )){
			# mnemonic であること判明
			$Line  = $Mnemonic . $Line;
			$Label = "";
		}else{
			# label だた
			$Mnemonic = "";
		}
	}
	
	### mnemonic 判別 ########################################################
	
	if( $Line =~ /^\s*($CSymbol)(.*)/ ){
		$Mnemonic = $1;
		$Line	  = $2;
		
		if( !defined( $OpecodeIdx{ $Mnemonic } )){
			Error( "invalid opecode \"$Mnemonic\"" );
			return();
		}
		
		$i		= $OpecodeIdx{ $Mnemonic };
		$Optype	= $OptypeList[ $i ];
		$Code	= $CodeList	 [ $i ];
		
		return( $Label, $Optype, $Code, $Line );
	}
	
	Error( "syntax error ( missing opecode? )" ) if( $Line !~ /^\s*$/ );
	return( $Label );
}

### 定数式計算 ###############################################################

sub ImmExpression{
	local( $Line ) = @_;
	local(
		$ret
	);
	
	if( $Line =~ /\b[ABCF]\b/ ){
		Error( "invalid operand \"$Line\" ( imm requred )" );
		return();
	}
	
	# label --> imm
	$Line =~ s/$CSymbol/&Label2Imm( $& )/ge;
	
	# $ --> $LocCnt
	$Line =~ s/\$/$LocCnt/g;
	
	# 00h --> 0x00
	$Line =~ s/\b(\d\w*)h\b/0x$1/g;
	
	# 00b, 0b00 --> dec
	$Line =~ s/\b0b(\d+)\b/&Bin2Dec( $1 )/ge;
	$Line =~ s/\b(\d+)b\b/&Bin2Dec( $1 )/ge;
	
	# calculation
	eval( '$ret = ' . $Line );
	Error( "syntax error ( imm expression )" ) if( $@ );
	
	return( $ret & 0xFF );
}

sub Bin2Dec{
	local( $val ) = @_;
	unpack( "N", pack( "B32", substr( "0" x 32 . $val, -32 )));
}

### define label #############################################################

sub DefineLabel{
	local( $Label, $Imm ) = @_;
	
	# 二重定義?
	Error( "redefined label \"$Label\"" )
		if( !$PathCnt && defined( $LabelList{ $Label } ));
	
	# アドレス値が違う ( 再アセンブル必要 )
	$bRedoAsm = 1 if( $LabelList{ $Label } != $Imm );
	$LabelList{ $Label } = $Imm;
}

### label --> addr ###########################################################

sub Label2Imm{
	
	local( $Label ) = @_;
	
	# defined
	return( $LabelList{ $Label } ) if( defined( $LabelList{ $Label } ));
	
	# undefined
	Error( "undefined label \"$Label\"" ) if( $PathCnt );
	return( 0 );
}

### get reg number ###########################################################

sub GetRegNumber{
	
	local( $Line ) = @_;
	$Line =~ s/\s+//g;
	
#	return( 0 ) if( $Line eq 'F' );
	return( 1 ) if( $Line eq 'A' );
	return( 2 ) if( $Line eq 'B' );
	return( 3 ) if( $Line eq 'C' );
	
	Error( "invalid operand \"$Line\" ( reg requred )" );
	return( "" );
}

### setup insn tbl ###########################################################

sub SetupInsnTbl{
	
	local(
		$i,
		$Mnemonic,
		$Code,
		$Optype
	);
	
	@InsnTbl = sort( @InsnTbl );
	
	for( $i = 0; $i <= $#InsnTbl; ++$i ){
		$InsnTbl[ $i ] =~ /^(\S+)\s+(\S+)\s+(\S+)$/;
		
		$Code		= $1;
		$Optype		= $2;
		$Mnemonic	= $3;
		
		$Code = unpack( "C", pack( "H2", $1 )) if( $Code =~ /^0x(.*)/ );
		
		$OpecodeIdx{ $Mnemonic } = $i;
		$CodeList	 [ $i ] = $Code;
		$OptypeList	 [ $i ] = $Optype;
		$MnemonicList[ $i ] = $Mnemonic;
		
		#print( "tbl>\"$InsnTbl[ $i ]\" $i, $Code, $Optype, $Mnemonic\n" );
	}
}

### print Error ##############################################################

sub Error{
	print( "$SceFile($LineCnt): $_[ 0 ]\n" );
	$bError = 1;
}

### simulator ################################################################

sub Simulator{
	
	local( $PC ) = 0;
	local( @Regs ) = ( 0, 0, 0, 0 );
	local( @RegName ) = ( 'F', 'A', 'B', 'C' );
	local( $fSign, $fZero, $fCarry ) = ( 0, 0, 0 );
	local(
		$Code,
		$Imm,
		$Inst,
		$i
	);
	
	open( fpLog, "> $LogFile" );
	
	while( 1 ){
		
		### print trace log ##################################################
		
		$Code = $CodeBuf[ $PC ];
		$Imm  = $CodeBuf[ ( $PC + 1 ) & 0xFF ];
		
		# print regs
		printf( fpLog "A:%02x B:%02x C:%02x PC:%02x ",
			$Regs[ 1 ], $Regs[ 2 ], $Regs[ 3 ], $PC );
		
		# print flags & opecode
		print( fpLog
			( $fSign  ? '-' : '+' ) .
			( $fZero  ? 'Z' : '.' ) .
			( $fCarry ? 'C' : '.' ));
		
		# 命令を判別
		for( $i = 0; $CodeList[ $i + 1 ] != 0xFF; ++$i ){
			last if( $CodeList[ $i + 1 ] > $Code );
		}
		
		$Inst = $MnemonicList[ $i ];
		
		# print instruction
		
		if( $bMrgSrc && defined( $Loc2Line[ $PC ] )){
			printf( fpLog "%6d:\t$SceBuf[ $Loc2Line[ $PC ] - 1 ]", $Loc2Line[ $PC ] );
			
		}elsif( $bMrgSrc || $MrgAsm ){
			print( fpLog "   ( no src )" ) if( $bMrgSrc );
			print( fpLog "\t$Inst\t" );		# opc
			
			if( $OptypeList[ $i ] =~ /^r/ ){		# opr1
				print( fpLog $RegName[ ( $Code >> 2 ) & 3 ] );
				
			}elsif( $OptypeList[ $i ] =~ /^i/ ){
				printf( fpLog "%02x", $Imm );
			}
			
			print( fpLog "," ) if( $OptypeList[ $i ] =~ /^[^*]./ );
			
			if( $OptypeList[ $i ] =~ /^.r/ ){		# opr2
				print( fpLog $RegName[ $Code & 3 ] );
				
			}elsif( $OptypeList[ $i ] =~ /^.i/ ){
				printf( fpLog "%02x", $Imm );
			}
		}
		print( fpLog "\n" );
		
		++$PC if( $OptypeList[ $i ] =~ /i/ );
		++$PC;
		
		### 命令ごとの実行 ###################################################
		
		# data xfer insn
		
		if( $Inst eq 'mov' ){
			$Regs[ $Code & 3 ] = $Regs[ ( $Code >> 2 ) & 3 ];
			
		}elsif( $Inst eq 'mvi' ){
			$Regs[ $Code & 3 ] = $Imm;
			
		}elsif( $Inst eq 'ld' ){
			$Regs[ $Code & 3 ] = $CodeBuf[ $Imm ];
			
		}elsif( $Inst eq 'ldx' ){
			$Regs[ $Code & 3 ] = $CodeBuf[ $Regs[ ( $Code >> 2 ) & 3 ] ];
			
		}elsif( $Inst eq 'st' ){
			$CodeBuf[ $Imm ] = $Regs[ ( $Code >> 2 ) & 3 ];
			
		}elsif( $Inst eq 'stx' ){
			$CodeBuf[ $Regs[ $Code & 3 ] ] = $Regs[ ( $Code >> 2 ) & 3 ];
			
		}elsif( $Inst eq 'push' ){
			&PushInsn( $Regs[ ( $Code >> 2 ) & 3 ] );
			
		}elsif( $Inst eq 'pop' ){
			$Regs[ $Code & 3 ] = &PopInsn();
			
		# jmp insn
		
		}elsif( $Inst eq 'jmp' ){ &JmpInsn( *PC, $Imm, 1 );
		}elsif( $Inst eq 'js'  ){ &JmpInsn( *PC, $Imm, $fSign );
		}elsif( $Inst eq 'jz'  ){ &JmpInsn( *PC, $Imm, $fZero );
		}elsif( $Inst eq 'jc'  ){ &JmpInsn( *PC, $Imm, $fCarry );
		}elsif( $Inst eq 'jns' ){ &JmpInsn( *PC, $Imm, !$fSign );
		}elsif( $Inst eq 'jnz' ){ &JmpInsn( *PC, $Imm, !$fZero );
		}elsif( $Inst eq 'jnc' ){ &JmpInsn( *PC, $Imm, !$fCarry );
		
		}elsif( $Inst eq 'cal' ){
			$Regs[ 3 ] = $PC;
			&JmpInsn( *PC, $Imm, 1 )
			
		}elsif( $Inst eq 'ret' ){
			&JmpInsn( *PC, $Regs[ 3 ], 1 );
		
		}elsif( $Inst eq 'pcal' ){
			&PushInsn( $PC );
			&JmpInsn( *PC, $Imm, 1 )
			
		}elsif( $Inst eq 'pret' ){
			&JmpInsn( *PC, &PopInsn(), 1 );
		
		# arithmetic insn
		
		}elsif( $Inst eq 'add' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] + $Regs[ $Code & 3 ] );
			
		}elsif( $Inst eq 'sub' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] - $Regs[ $Code & 3 ] );
			
		}elsif( $Inst eq 'adc' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] + $Regs[ $Code & 3 ] + $fCarry );
			
		}elsif( $Inst eq 'sbb' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] - $Regs[ $Code & 3 ] - $fCarry );
			
		}elsif( $Inst eq 'and' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] & $Regs[ $Code & 3 ] );
			
		}elsif( $Inst eq 'or' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] | $Regs[ $Code & 3 ] );
			
		}elsif( $Inst eq 'cmp' ){
			&SetFlag( $Regs[ 1 ] - $Regs[ $Code & 3 ] );
			
		}elsif( $Inst eq 'eor' ){
			$Regs[ 1 ] = &SetFlag( $Regs[ 1 ] ^ $Regs[ $Code & 3 ] );
			
		}elsif( $Inst eq 'inc' ){
			$Regs[ $Code & 3 ] = &SetFlag( $Regs[ $Code & 3 ] + 1 );
			
		}elsif( $Inst eq 'dec' ){
			$Regs[ $Code & 3 ] = &SetFlag( $Regs[ $Code & 3 ] - 1 );
			
		}elsif( $Inst eq 'shl' ){
			$Regs[ $Code & 3 ] = &SetFlag( $Regs[ $Code & 3 ] << 1 );
			
		}elsif( $Inst eq 'shr' ){
			$Regs[ $Code & 3 ] = &SetFlag(
				( $Regs[ $Code & 3 ] >> 1 ) +
				(( $Regs[ $Code & 3 ] & 1 ) << 8 )
			);
			
		}elsif( $Inst eq 'not' ){
			$Regs[ $Code & 3 ] = &SetFlag( $Regs[ $Code & 3 ] ^ 0xFF );
		}
		
		last if( $bBreak );
		
		if( $PC > 0xFF ){
			print( "$SceFile: Runtime error: PC exceeded 0xFF\n" );
			$bError = 1;
			last;
		}
	}
	
	# core dump
	
	print( fpLog "\n*** core dump *************************************\n" );
	print( fpLog "ADR +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F\n" );
	
	for( $i = 0; $i < 0x100; ++$i ){
		printf( fpLog "%02x:", $i ) if(( $i % 16 ) == 0 );
		
		if( defined( $CodeBuf[ $i ] )){
			printf( fpLog " %02x", $CodeBuf[ $i ] );
		}else{
			print( fpLog  " xx" );
		}
		
		print( fpLog "\n" ) if(( $i % 16 ) == 15 );
	}
	
	close( fpLog );
}

### set flag #################################################################

sub SetFlag{
	local( $Val ) = @_;
	
	$fSign  = (( $Val &  0x80 ) != 0 );
	$fZero  = (( $Val &  0xFF ) == 0 );
	$fCarry = (( $Val & ~0xFF ) != 0 );
	
	return( $Val & 0xFF );
}

### jmp insn #################################################################

sub JmpInsn{
	local( *PC, $Dst, $cc ) = @_;
	
	local( $PrePC ) = $PC - 2;
	
	$PC = $Dst if( $cc );
	$bBreak = ( $PC == $PrePC );
}

### push / pop ###############################################################

sub PushInsn{
	$Regs[ 3 ] = ( $Regs[ 3 ] - 1 ) & 0xFF;
	$CodeBuf[ $Regs[ 3 ] ] = $_[ 0 ];
}

sub PopInsn{
	local( $Ret ) = $CodeBuf[ $Regs[ 3 ] ];
	
	$Regs[ 3 ] = ( $Regs[ 3 ] + 1 ) & 0xFF;
	return( $Ret );
}
