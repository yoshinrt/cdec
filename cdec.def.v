/*****************************************************************************

		CDEC.def.v -- CDEC chip for altera
		Copylight(C) 2001 by Deyu Deyu HW & SW Designs

*****************************************************************************/

#define Register		always@( posedge Clk or posedge Reset )

enum {
	REG_PC,
	REG_A,
	REG_B,
	REG_C
};

enum tALUCmd {
	ALUCMD_ADD,
	ALUCMD_ADC,
	ALUCMD_SUB,
	ALUCMD_SBB,
	ALUCMD_AND,
	ALUCMD_OR,
	ALUCMD_MOV
	ALUCMD_XOR,
	ALUCMD_INC,
	ALUCMD_DEC,
	ALUCMD_SHR,
	ALUCMD_SHL,
	ALUCMD_NOT,
};

#define FLAGS			{ FlagS, FlagZ, FlagC }

/*** ALU ********************************************************************/

module ALU(
	// I/O port
	
	input	tALUCmd	iALUCmd,		// ALU operation command
	
	output	[7:0]	oDBus0,			// DBus0 ( ALU output )
	input	[7:0]	iDBus1,			// DBus1 ( ALU operand1 )
	input	[7:0]	iDBus2,			// DBus2 ( ALU operand2 )
	input			iCarry,			// CY in
	
	output	[2:0]	oFlags			// FLAGS out ( SZC )
);

// wire / reg

reg		[8:0]	Result;
wire	[8:0]	ResultAdder;
reg		[8:0]	ax, bx;
reg				cx;

wire			FlagS,
				FlagZ,
				FlagC;

	assign ResultAdder = ax + bx + cx;
	
	always@( iDBus1 or iDBus2 or iALUCmd or iCarry or ResultAdder ) begin
		
		ax = { 1'b0, iDBus1 };
		bx = 9'bx;
		cx = 1'bx;
		
		Case( iALUCmd )
			ALUCMD_ADD,
			ALUCMD_ADC,
			ALUCMD_SUB,
			ALUCMD_SBB,
			ALUCMD_INC,
			ALUCMD_DEC: begin
				
				Case( iALUCmd )
					ALUCMD_SUB, ALUCMD_SBB: bx = { 1'b1, iDBus2 };
					ALUCMD_INC:				bx = 9'd1;
					ALUCMD_DEC:				bx = 9'h1FF;
					default:				bx = iDBus2;
				endcase
				
				Case( iALUCmd )
					ALUCMD_ADC: cx = iCarry;
					ALUCMD_SUB: cx = 1;
					ALUCMD_SBB: cx = ~iCarry;
					default:	cx = 0;
				endcase
				
				Result = ResultAdder;
			end
			
			ALUCMD_AND:	Result = iDBus1 & iDBus2;
			ALUCMD_OR:	Result = iDBus1 | iDBus2;
			ALUCMD_XOR:	Result = iDBus1 ^ iDBus2;
			ALUCMD_SHL:	Result = iDBus1 << 1;
			ALUCMD_SHR:	Result = { iDBus1[ 0 ], 1'b0, iDBus1[7:1] };
			ALUCMD_NOT:	Result = { 1'b0, ~iDBus1 };
			ALUCMD_MOV:	Result = iDBus1;
			default:	Result = 9'bx;
		endcase
	end
	
	assign oDBus0 = Result[7:0];
	
	assign FlagS = Result[7];
	assign FlagZ = ( Result[7:0] == 0 );
	assign FlagC = Result[8];
	assign oFlags = FLAGS;
endmodule

module FlagsRegister(
	input			Clk,			// clock
	input			Reset,			// reset
	
	input			iWriteEnb,		// Flags reg WE
	input	[2:0]	iFlags,			// FLAGS in ( SZC )
	
	outreg	[2:0]	oFlagsReg		// FLAGS reg out
);

	Register begin
		if( Reset )				oFlagsReg <= 3'd0;
		else if( iWriteEnb )	oFlagsReg <= iFlags;
	end
endmodule

/*** generic register file ( PC, A, B, C ) **********************************/

module RegFile(
	// I/O port
	
	input			Clk,			// clock
	input			Reset,			// reset
	
	input			iWriteEnb,		// register Write Enable
	input	[1:0]	iDBusSel0,		// write register
	input	[1:0]	iDBusSel1,		// read register DBus1
	input	[1:0]	iDBusSel2,		// read register DBus2
	
	input	[7:0]	iDBus0,			// DBus0 ( ALU output )
	outreg	[7:0]	oDBus1,			// DBus1 ( ALU operand1 )
	outreg	[7:0]	oDBus2,			// DBus2 ( ALU operand2 )
	
	outreg	[7:0]	oRegPC,			// generic registers
	outreg	[7:0]	oRegA,
	outreg	[7:0]	oRegB,
	outreg	[7:0]	oRegC
);
	
	Register begin
		if( Reset ) begin
			oRegPC <= 8'd0;
			oRegA  <= 8'd0;
			oRegB  <= 8'd0;
			oRegC  <= 8'd0;
		end else if( iWriteEnb ) begin
			Case( iDBusSel0 )
				REG_PC: oRegPC <= iDBus0;
				REG_A : oRegA  <= iDBus0;
				REG_B : oRegB  <= iDBus0;
				REG_C : oRegC  <= iDBus0;
				default: ;
			endcase
		end
	end
	
	// oDBus1 selector
	
	always@( oRegPC or oRegA or oRegB or oRegC or iDBusSel1 ) begin
		Case( iDBusSel1 )
			REG_PC: oDBus1 <= oRegPC;
			REG_A : oDBus1 <= oRegA;
			REG_B : oDBus1 <= oRegB;
			REG_C : oDBus1 <= oRegC;
			default:oDBus1 <= 8'bx;
		endcase
	end
	
	// oDBus2 selector
	
	always@( oRegPC or oRegA or oRegB or oRegC or iDBusSel2 ) begin
		Case( iDBusSel2 )
			REG_PC: oDBus2 <= oRegPC;
			REG_A : oDBus2 <= oRegA;
			REG_B : oDBus2 <= oRegB;
			REG_C : oDBus2 <= oRegC;
			default:oDBus2 <= 8'bx;
		endcase
	end
endmodule

/*** sequencer **************************************************************/

enum	tState {
	S_INIT,		S_MOV_MAR_PC,	S_MOV_IR_MEM,	S_BRANCH,
	
	S_MOV,
	
	S_LD,		S_LD1,		S_LDX,		S_LD_MEM,
	S_ST,		S_ST1,		S_STX,		S_ST_MEM,
	
	S_ADD,		S_INC,		S_CMP,
	
	S_PUSH,		S_PUSH1,
	S_POP,		S_POP1,		S_POP2,
	
	S_CAL,
	S_PCAL,		S_PCAL1,	S_PCAL2,	S_PCAL3,
	S_PRET,		S_PRET1,	S_PRET2,
	
	S_INC_PC2
};

module Sequencer(
	input			Clk,			// clock
	input			Reset,			// reset
	
	input	[7:0]	iIR,			// IR in
	input	[2:0]	iFlagsReg,		// FLAGS reg out
	
	outreg	tALUCmd	oALUCmd,		// ALU operation command
	outreg	[1:0]	oDBusSel0,		// write register
	outreg	[1:0]	oDBusSel1,		// read register DBus1
	outreg	[1:0]	oDBusSel2,		// read register DBus2
	
	outreg			oWE_Regs,		// register file WE
	outreg			oWE_RegIR,		// IR WE
	outreg			oWE_RegMAR,		// MAR WE
	outreg			oRE_MAU,		// MAU RE
	outreg			oWE_MAU,		// MAU WE
	outreg			oWE_Flags		// Flags reg WE
);

// wire / reg

reg		tState	StateReg;		// Current state
reg		tState	NextState;		// Next state ( wire )
reg				bJccTrue;

	/*** state register *****************************************************/
	
	Register begin
		if( Reset )	StateReg <= S_INIT;
		else		StateReg <= NextState;
	end
	
	/*** control signal generator *******************************************/
	
	always@( StateReg or iIR or bJccTrue ) begin
		
		oALUCmd		= ALUCMD_MOV;
		oDBusSel0	= 2'bx;
		oDBusSel1	= 2'bx;
		oDBusSel2	= 2'bx;
		
		oWE_Regs	= 0;
		oWE_RegIR	= 0;
		oWE_RegMAR	= 0;
		oRE_MAU		= 0;
		oWE_MAU		= 0;
		oWE_Flags	= 0;
		
		Case( StateReg )
			
			/*** load instruction code **************************************/
			
			S_MOV_MAR_PC: begin			// MAU = PC
				oDBusSel1	= REG_PC;
				oWE_RegMAR	= 1;
				NextState	= S_MOV_IR_MEM;
			end
			
			S_MOV_IR_MEM: begin			// IR = *MAU
				oWE_RegIR	= 1;
				oRE_MAU		= 1;
				NextState	= S_BRANCH;
			end
			
			S_BRANCH: begin				// MAU = ++PC
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_PC;
				oDBusSel1	= REG_PC;
				oWE_RegMAR	= 1;
				oWE_Regs	= 1;
				
				Case( iIR[7:5] )
					3'b000:	NextState = S_MOV; // & S_RET
					3'b001: NextState = ( iIR[4:2] == 3'b110 ) ? S_CMP : S_ADD;
					3'b010:	NextState = S_INC;
					
					3'b011: NextState =
								( iIR[1:0] == 2'b00 ) ? S_CAL	:
								( iIR[1:0] == 2'b01 ) ? S_PCAL	:
														S_PRET	;
					
					3'b100: NextState = ( iIR[4] == 1'b0 ) ? S_LD : S_LDX;
					3'b101: NextState = ( iIR[4] == 1'b0 ) ? S_ST : S_STX;
					
					3'b110: NextState =
								( iIR[4:2] == 3'b100 ) ? S_POP		:
								( iIR[4]   == 1'b1   ) ? S_PUSH		:
								( iIR[1:0] == 2'b00  ) ? S_LD_MEM	: // S_JMP
														 S_LD1		; // S_MVI
					
					3'b111: NextState = bJccTrue ? S_LD_MEM : S_INC_PC2; // jcc
					
					default:NextState = tState_w'bx;
				endcase
			end
			
			/*** data transfer **********************************************/
			
			S_MOV: begin
				oALUCmd		= ALUCMD_MOV;
				oDBusSel0	= iIR[1:0];
				oDBusSel1	= iIR[3:2];
				oWE_Regs	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** LD: dreg = **PC ***/
			
			S_LD: begin		// MAR = *MAR
				oALUCmd		= ALUCMD_MOV;
				oRE_MAU		= 1;
				oWE_RegMAR	= 1;
				NextState	= S_LD1;
			end
			
			S_LD1: begin	// ++PC
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_PC;
				oDBusSel1	= REG_PC;
				oWE_Regs	= 1;
				NextState	= S_LD_MEM;
			end
			
			S_LD_MEM: begin	// dst = *MAR
				oALUCmd		= ALUCMD_MOV;
				oDBusSel0	= iIR[1:0];
				oRE_MAU		= 1;
				oWE_Regs	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** LDX: dreg = *sreg ***/
			
			S_LDX: begin	// MAR = sreg	next: S_LD_MEM
				oALUCmd		= ALUCMD_MOV;
				oDBusSel1	= iIR[3:2];
				oWE_RegMAR	= 1;
				NextState	= S_LD_MEM;
			end
			
			/*** ST: **PC = sreg ***/
			
			S_ST: begin		// MAR = *MAR
				oALUCmd		= ALUCMD_MOV;
				oRE_MAU		= 1;
				oWE_RegMAR	= 1;
				NextState	= S_ST1;
			end
			
			S_ST1: begin	// ++PC
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_PC;
				oDBusSel1	= REG_PC;
				oWE_Regs	= 1;
				NextState	= S_ST_MEM;
			end
			
			S_ST_MEM: begin	// *MAR = sreg
				oALUCmd		= ALUCMD_MOV;
				oWE_MAU		= 1;
				oDBusSel1	= iIR[3:2];
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** STX: *dreg = sreg ***/
			
			S_STX: begin	// MAR = sdreg	next: S_ST_MEM
				oALUCmd		= ALUCMD_MOV;
				oDBusSel1	= iIR[1:0];
				oWE_RegMAR	= 1;
				NextState	= S_ST_MEM;
			end
			
			/*** arithmetic operation ***************************************/
			
			S_ADD: begin	// A = A op OPR ( ADD etc ... )
				oALUCmd		= iIR[5:2] ^ 4'b1000;
				oDBusSel0	= REG_A;
				oDBusSel1	= REG_A;
				oDBusSel2	= iIR[1:0];
				oWE_Regs	= 1;
				oWE_Flags	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			S_INC: begin	// OPR = op OPR ( INC etc ... )
				oALUCmd		= iIR[5:2] ^ 4'b1000;
				oDBusSel0	= iIR[1:0];
				oDBusSel1	= iIR[1:0];
				oWE_Regs	= 1;
				oWE_Flags	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			S_CMP: begin	// CMP
				oALUCmd		= ALUCMD_SUB;
				oDBusSel1	= REG_A;
				oDBusSel2	= iIR[1:0];
				oWE_Flags	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** push / pop *************************************************/
			
			S_PUSH: begin	// MAR = --C
				oALUCmd		= ALUCMD_DEC;
				oDBusSel0	= REG_C;
				oDBusSel1	= REG_C;
				oWE_Regs	= 1;
				oWE_RegMAR	= 1;
				NextState	= S_PUSH1;
			end
			
			S_PUSH1: begin	// *MAR = sce
				oALUCmd		= ALUCMD_MOV;
				oWE_MAU		= 1;
				oDBusSel1	= iIR[3:2];
				NextState	= S_MOV_MAR_PC;
			end
			
			S_POP: begin	// MAR = C
				oALUCmd		= ALUCMD_MOV;
				oWE_RegMAR	= 1;
				oDBusSel1	= REG_C;
				NextState	= S_POP1;
			end
			
			S_POP1: begin	// dst = *MAR
				oALUCmd		= ALUCMD_MOV;
				oDBusSel0	= iIR[1:0];
				oRE_MAU		= 1;
				oWE_Regs	= 1;
				NextState	= S_POP2;
			end
			
			S_POP2: begin	// ++C
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_C;
				oDBusSel1	= REG_C;
				oWE_Regs	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** call *******************************************************/
			
			S_CAL: begin	// C = PC + 1  next: LD1
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_C;
				oDBusSel1	= REG_PC;
				oWE_Regs	= 1;
				NextState	= S_LD_MEM;
			end
			
			/*** pcal ***/
			
			S_PCAL: begin	// MAR = --C
				oALUCmd		= ALUCMD_DEC;
				oDBusSel0	= REG_C;
				oDBusSel1	= REG_C;
				oWE_Regs	= 1;
				oWE_RegMAR	= 1;
				NextState	= S_PCAL1;
			end
			
			S_PCAL1: begin	// *MAR = PC + 1
				oALUCmd		= ALUCMD_INC;
				oWE_MAU		= 1;
				oDBusSel1	= REG_PC;
				NextState	= S_PCAL2;
			end
			
			S_PCAL2: begin	// MAR = PC
				oALUCmd		= ALUCMD_MOV;
				oWE_RegMAR	= 1;
				oDBusSel1	= REG_PC;
				NextState	= S_PCAL3;
			end
			
			S_PCAL3: begin	// PC = *MAR
				oALUCmd		= ALUCMD_MOV;
				oDBusSel0	= REG_PC;
				oRE_MAU		= 1;
				oWE_Regs	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** pret ***/
			
			S_PRET: begin	// MAR = C
				oALUCmd		= ALUCMD_MOV;
				oWE_RegMAR	= 1;
				oDBusSel1	= REG_C;
				NextState	= S_PRET1;
			end
			
			S_PRET1: begin	// PC = *MAR
				oALUCmd		= ALUCMD_MOV;
				oDBusSel0	= REG_PC;
				oRE_MAU		= 1;
				oWE_Regs	= 1;
				NextState	= S_PRET2;
			end
			
			S_PRET2: begin	// ++C
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_C;
				oDBusSel1	= REG_C;
				oWE_Regs	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** ++PC *******************************************************/
			
			S_INC_PC2: begin	// ++PC
				oALUCmd		= ALUCMD_INC;
				oDBusSel0	= REG_PC;
				oDBusSel1	= REG_PC;
				oWE_Regs	= 1;
				NextState	= S_MOV_MAR_PC;
			end
			
			/*** others *****************************************************/
			
			S_INIT:
				NextState	= S_MOV_MAR_PC;
			
			default: begin
				oALUCmd		= tALUCmd_w'bx;
				oDBusSel0	= 2'bx;
				oDBusSel1	= 2'bx;
				oDBusSel2	= 2'bx;
				
				oWE_Regs	= 1'bx;
				oWE_RegIR	= 1'bx;
				oWE_RegMAR	= 1'bx;
				oRE_MAU		= 1'bx;
				oWE_MAU		= 1'bx;
				oWE_Flags	= 1'bx;
				NextState	= S_MOV_MAR_PC;
			end
		endcase
	end
	
	/*** jcc condition checker **********************************************/
	
	always@( iIR[4:2] or iFlagsReg ) begin
		Case( iIR[4:2] )
			3'b100: bJccTrue =  iFlagsReg[2];	// s
			3'b011: bJccTrue = ~iFlagsReg[2];	// ns
			3'b010: bJccTrue =  iFlagsReg[1];	// z
			3'b101: bJccTrue = ~iFlagsReg[1];	// nz
			3'b001: bJccTrue =  iFlagsReg[0];	// c
			3'b110: bJccTrue = ~iFlagsReg[0];	// nc
			default:bJccTrue = 1'bx;
		endcase
	end
endmodule

/*** generic 8bit register **************************************************/

module Register8(
	input			Clk,			// clock
	input			Reset,			// reset
	
	input			iWriteEnb,		// write enable
	input	[7:0]	iData,			// DBus0 ( ALU output )
	outreg	[7:0]	oData			// IR out
);

	Register begin
		if( Reset )				oData <= 8'd0;
		else if( iWriteEnb )	oData <= iData;
	end
endmodule

/*** CDEC *******************************************************************/

module CDEC(
	
	input			Clk,			// clock
	input			Reset,			// reset
	input			iClkMst,		// master input clk ( 24MHz )
	
	output			oClkDiv,		// output divided clk
	
	output	[6:0]	oData7Seg0,		// 7seg display data
					oData7Seg1,
	output			oData7SegP,		// 7seg 0's dp
	output	[7:0]	oDataLED		// 8bit LED data
);

// wire / reg

wire	[7:0]	DBus1,
				DBus1Reg,
				DBus1MAU;

wire			RAM_WE;
	
	/*** CDEC CORE modules **************************************************/
	
	assign DBus1 = RE_MAU ? DBus1MAU : DBus1Reg;
	
	instance ALU * * (
		iCarry		FlagsReg[0]
	);
	
	instance FlagsRegister * *(
		iWriteEnb	WE_Flags
	);
	
	instance RegFile * * (
		oDBus1		DBus1Reg
		iWriteEnb	WE_Regs
		.*							W
	);
	
	instance Register8  RegMAR * (
		iData		DBus0
		oData		AddrBus
		iWriteEnb	WE_RegMAR
	);
	
	instance Sequencer * *(
		iIR			InstCode
		o[RW]E_MAU					W
	);
	
	instance Register8 RegIR * (
		iData		DBus0
		oData		InstCode
		iWriteEnb	WE_RegIR
	);
	
	assign RAM_WE = ~Clk & WE_MAU;
	
	/*** RAM ****************************************************************/
	
	instance RAM * RAM.v (
		data		DBus0
		q			DBus1MAU
		address		AddrBus
		we			RAM_WE
	);
	
	/*** 7seg decoder & LED *************************************************/
	
	instance Seg7Decode Seg7_0 * (
		iData		RegA[7:4]
		oSegData	oData7Seg0
	);
	
	instance Seg7Decode Seg7_1 * (
		iData		RegA[3:0]
		oSegData	oData7Seg1
	);
	
	assign oData7SegP	= 1; // ~Data7Seg[8];
	assign oDataLED		= ~RegB;
	
	/*** other modules ******************************************************/
	
	instance ClkDiv * * (
		(.*)		$1
	);
	
endmodule

/*** 7seg decoder ***********************************************************/

module Seg7Decode(
	input	[3:0]	iData,
	outreg	[6:0]	oSegData
);

	always@( iData ) begin
		Case( iData )		 // GFEDCBA
			4'h0: oSegData = 7'b1000000;
			4'h1: oSegData = 7'b1111001;
			4'h2: oSegData = 7'b0100100;
			4'h3: oSegData = 7'b0110000;
			4'h4: oSegData = 7'b0011001;
			4'h5: oSegData = 7'b0010010;
			4'h6: oSegData = 7'b0000010;
			4'h7: oSegData = 7'b1011000;
			4'h8: oSegData = 7'b0000000;
			4'h9: oSegData = 7'b0010000;
			4'hA: oSegData = 7'b0001000;
			4'hB: oSegData = 7'b0000011;
			4'hC: oSegData = 7'b1000110;
			4'hD: oSegData = 7'b0100001;
			4'hE: oSegData = 7'b0000110;
			4'hF: oSegData = 7'b0001110;
			default:oSegData = 7'bx;
		endcase
	end
endmodule

/*** clock division circuit *************************************************/

module ClkDiv(
	input			iClkMst,	// master input clk ( 24MHz )
	input			Reset,		// reset
	outreg			oClkDiv	// divided clk out ( 1/6 = 4MHz )
);

// wire / reg

reg		[2:0]	Cnt;

	
	always@( posedge iClkMst or posedge Reset )
		if( Reset )	oClkDiv <= 0;
		else		oClkDiv <= ( Cnt < 3 );
	
	always@( posedge iClkMst or posedge Reset ) begin
		if	   ( Reset )	Cnt <= 0;
		else if( Cnt == 5 )	Cnt <= 0;
		else				Cnt <= Cnt + 1;
	end
endmodule
