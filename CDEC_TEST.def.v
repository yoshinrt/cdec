$header

/*****************************************************************************

		CDEC_TEST.def.v -- CDEC test bench & data logger
		Copylight(C) 2001 by Deyu Deyu Software

*****************************************************************************/

`timescale 1ns/1ns

#include "CDEC.def.v"
#include "RAM.v"

testmodule CDEC_TEST;

integer			fd;
reg		[7:0]	prePC;

parameter		STEP = 24;

	instance CDEC * * (
		oClkDiv		Clk
	);
	
	/*** signal gen. ********************************************************/
	
	initial begin
		ClkMst	= 1;
		Reset	= 1;
	
	#( STEP / 2 )
		Reset	= 0;
	end
	
	// clock
	
	always #( STEP / 2 )	ClkMst = ~ClkMst;
	
	/*** monitoring *********************************************************/
	
	initial begin
		fd		= $fopen( "CDEC_exec.log" );
		prePC	= 8'hFF;
	end
	
	always@( posedge Clk ) begin
		if( CDECInst.SequencerInst.StateReg == 1 ) begin
			
			if( prePC == CDECInst.RegPC ) begin
				CoreDump;
				$fclose( fd );
				$finish;
			end
			
			prePC = CDECInst.RegPC;
			
			$fdisplay( fd, "A:%h B:%h C:%h PC:%h %s%s%s",
				CDECInst.RegA,
				CDECInst.RegB,
				CDECInst.RegC,
				CDECInst.RegPC,
				( CDECInst.FlagsReg[ 2 ] ? "-" : "+" ),
				( CDECInst.FlagsReg[ 1 ] ? "Z" : "." ),
				( CDECInst.FlagsReg[ 0 ] ? "C" : "." )
			);
		end
	end
	
task CoreDump;
integer	i;
	begin
		
		$fdisplay( fd, "" );
		$fdisplay( fd, "*** core dump *************************************" );
		$fdisplay( fd, "ADR +0 +1 +2 +3 +4 +5 +6 +7 +8 +9 +A +B +C +D +E +F" );
		
		for( i = 0; i < 256; i = i + 1 ) begin
			if( i % 16 == 0 ) $fwrite( fd, "%h:", i[7:0] );
			
			if( i % 16 == 15 )
				$fdisplay( fd, " %h", CDECInst.RAMInst.lpm_ram_dq_component.RAM[ i ] );
			else
				$fwrite  ( fd, " %h", CDECInst.RAMInst.lpm_ram_dq_component.RAM[ i ] );
		end
	end
endtask

endmodule

/*** altera RAM module for simulation ***************************************/

module lpm_ram_dq;

// I/O port

input	[7:0]	address;
input			we;
input	[7:0]	data;
output	[7:0]	q;

// reg / wire

reg		[7:0]	RAM[0:255];

// parameter (dummy)

parameter LPM_WIDTH				= 8;
parameter LPM_WIDTHAD			= 8;
parameter LPM_INDATA			= "REGISTERED";
parameter LPM_ADDRESS_CONTROL	= "REGISTERED";
parameter LPM_OUTDATA			= "UNREGISTERED";
parameter LPM_FILE				= "RAM.hex";
parameter LPM_HINT				= "USE_EAB=ON";

	initial begin
		$readmemh( "RAM.dat", RAM );
	end
	
	always@( we or address or data ) begin
		if( we ) RAM[ address ] = data;
	end
	
	assign q = RAM[ address ];
endmodule
