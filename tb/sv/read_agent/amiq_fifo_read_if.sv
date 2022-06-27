//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_READ_IF
`define AMIQ_FIFO_READ_IF

//`include "amiq_fifo_in_defines.svh"

/*
 * Interface for encapsulating the signals of a protocol
 * @param clk Clock signal
 * @param rst_n Reset signal - active low
 */
interface amiq_fifo_read_if#(parameter M = `M)(input logic clk, input logic rst_n);

	// Protocol signals
	/*
	 * read enable
	 * the consumer asserts this control signal to indicate valid read data
	 */
	logic rd_en;
	/*
	 * data signal validated by the rd_en signal
	 * the data bus width is parameterizable within 1..M bits
	 */
	logic [(M-1):0] rd_data;

	// enabler of interface checkers
	logic has_checks;

endinterface

`endif
