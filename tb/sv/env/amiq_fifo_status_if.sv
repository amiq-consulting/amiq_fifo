//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_STATUS_IF
`define AMIQ_FIFO_STATUS_IF

//`include "amiq_fifo_in_defines.svh"

/*
 * Interface for encapsulating the signals of a protocol
 * @param clk Clock signal
 * @param rst_n Reset signal - active low
 */
interface amiq_fifo_status_if(input logic clk, input logic rst_n);

	/*
	 * It is used as a safety mechanism to avoid the writing of the entire FIFO memory
	 * It is asserted when the fill level of the FIFO is between FIFO_depth and FIFO_depth - alm_full_thresh
	 */
	logic alm_full;
	/*
	 * Status signal used to mark that all the FIFO positions are used and there is no free space for more data
	 */
	logic full;
	/*
	 * It is used as a safety mechanism to avoid the situation when the FIFO memory is almost empty
	 * It is asserted when the fill level of the FIFO is between empty and alm_empty_thresh
	 */
	logic alm_empty;
	/*
	 * Status signal used to mark the FIFO does not contain any valid data
	 */
	logic empty;

endinterface

`endif
