//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_IF
`define AMIQ_FIFO_WRITE_IF

/*
 * Interface for encapsulating the signals of a protocol
 * @param clk Clock signal
 * @param rst_n Reset signal - active low
 */
interface amiq_fifo_write_if#(parameter N = `N)(input logic clk, input logic rst_n);

	// Protocol signals
	
	/*
	 * write enable
	 * wr_en - the producer asserts this control signal to indicate valid data
	 */
	logic wr_en;
	
	/*
	 * data signal validated by the wr_en signal
	 * the data bus width is parameterizable within 1..N bits
	 */
	logic [(N-1):0] wr_data;

	// enabler of interface checkers
	logic has_checks;

endinterface

`endif
