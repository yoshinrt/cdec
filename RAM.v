// megafunction wizard: %LPM_RAM_DQ%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: lpm_ram_dq 

// ============================================================
// File Name: RAM.v
// Megafunction Name(s):
// 			lpm_ram_dq
// ============================================================
// ************************************************************
// THIS IS A WIZARD GENERATED FILE. DO NOT EDIT THIS FILE!
// ************************************************************


//	Copyright (C) 1988-2000 Altera Corporation

//	Any megafunction design, and related net list (encrypted or decrypted),
//	support information, device programming or simulation file, and any other
//	associated documentation or information provided by Altera or a partner
//	under Altera's Megafunction Partnership Program may be used only to
//	program PLD devices (but not masked PLD devices) from Altera.  Any other
//	use of such megafunction design, net list, support information, device
//	programming or simulation file, or any other related documentation or
//	information is prohibited for any other purpose, including, but not
//	limited to modification, reverse engineering, de-compiling, or use with
//	any other silicon devices, unless such use is explicitly licensed under
//	a separate agreement with Altera or a megafunction partner.  Title to
//	the intellectual property, including patents, copyrights, trademarks,
//	trade secrets, or maskworks, embodied in any such megafunction design,
//	net list, support information, device programming or simulation file, or
//	any other related documentation or information provided by Altera or a
//	megafunction partner, remains with Altera, the megafunction partner, or
//	their respective licensors.  No other licenses, including any licenses
//	needed under any third party's intellectual property, are provided herein.

module RAM (
	address,
	we,
	data,
	q);

	input	[7:0]  address;
	input	  we;
	input	[7:0]  data;
	output	[7:0]  q;

	wire [7:0] sub_wire0;
	wire [7:0] q = sub_wire0[7:0];

	lpm_ram_dq	lpm_ram_dq_component (
				.address (address),
				.data (data),
				.we (we),
				.q (sub_wire0));
	defparam
		lpm_ram_dq_component.LPM_WIDTH = 8,
		lpm_ram_dq_component.LPM_WIDTHAD = 8,
		lpm_ram_dq_component.LPM_INDATA = "UNREGISTERED",
		lpm_ram_dq_component.LPM_ADDRESS_CONTROL = "UNREGISTERED",
		lpm_ram_dq_component.LPM_OUTDATA = "UNREGISTERED",
		lpm_ram_dq_component.LPM_FILE = "RAM.mif",
		lpm_ram_dq_component.LPM_HINT = "USE_EAB=ON";


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: WidthData NUMERIC "8"
// Retrieval info: PRIVATE: WidthAddr NUMERIC "8"
// Retrieval info: PRIVATE: RegData NUMERIC "0"
// Retrieval info: PRIVATE: RegAdd NUMERIC "0"
// Retrieval info: PRIVATE: OutputRegistered NUMERIC "0"
// Retrieval info: PRIVATE: BlankMemory NUMERIC "0"
// Retrieval info: PRIVATE: MIFfilename STRING "RAM.mif"
// Retrieval info: PRIVATE: UseLCs NUMERIC "0"
// Retrieval info: PRIVATE: DataBusSeparated NUMERIC "1"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "8"
// Retrieval info: CONSTANT: LPM_WIDTHAD NUMERIC "8"
// Retrieval info: CONSTANT: LPM_INDATA STRING "UNREGISTERED"
// Retrieval info: CONSTANT: LPM_ADDRESS_CONTROL STRING "UNREGISTERED"
// Retrieval info: CONSTANT: LPM_OUTDATA STRING "UNREGISTERED"
// Retrieval info: CONSTANT: LPM_FILE STRING "RAM.mif"
// Retrieval info: CONSTANT: LPM_HINT STRING "USE_EAB=ON"
// Retrieval info: USED_PORT: address 0 0 8 0 INPUT NODEFVAL address[7..0]
// Retrieval info: USED_PORT: we 0 0 0 0 INPUT VCC we
// Retrieval info: USED_PORT: q 0 0 8 0 OUTPUT NODEFVAL q[7..0]
// Retrieval info: USED_PORT: data 0 0 8 0 INPUT NODEFVAL data[7..0]
// Retrieval info: CONNECT: @address 0 0 8 0 address 0 0 8 0
// Retrieval info: CONNECT: @we 0 0 0 0 we 0 0 0 0
// Retrieval info: CONNECT: q 0 0 8 0 @q 0 0 8 0
// Retrieval info: CONNECT: @data 0 0 8 0 data 0 0 8 0
