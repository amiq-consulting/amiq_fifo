//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_SEQ_LIB
`define AMIQ_FIFO_WRITE_SEQ_LIB

/*
 * Sequence class for generating items
 */
class amiq_fifo_write_sequence extends uvm_sequence#(amiq_fifo_write_item);
	`uvm_object_utils(amiq_fifo_write_sequence)

	/*
	 * Constructor function for the sequence
	 * @see uvm_pkg::uvm_object.new
	 * @param name -
	 */
	function new(string name = "amiq_fifo_write_sequence");
		super.new(name);
	endfunction

	/*
	 * The body of the sequence
	 * defines and creates a scenario
	 */
	task body();
		`uvm_do(req)
	endtask
endclass

`endif
