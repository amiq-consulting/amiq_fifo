//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_CONTROL_IF
`define AMIQ_FIFO_CONTROL_IF

//`include "amiq_fifo_in_defines.svh"

/*
 * Interface for encapsulating the signals of a protocol
 * @param clk Clock signal
 */
interface amiq_fifo_control_if#(parameter P = `P)(input logic clk);

	/*
	 * For hard reset of the FIFO is used the rst_n signal
	 * When rst_n signal is asserted the entire content of the FIFO is removed
	 * and both read and write pointers are reset to point to the first address
	 */
	logic rst_n;
	/*
	 * It is used to configure how many spaces are necessary to be empty in order to have the alm_full signal asserted
	 */
	logic [(P-1):0] alm_full_thresh;
	/*
	 * It is used to configure how many spaces are necessary to be filled in order to have the alm_empty signal asserted
	 */
	logic [(P-1):0] alm_empty_thresh;

endinterface

`endif
