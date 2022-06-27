//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_READ_SEQUENCER
`define AMIQ_FIFO_READ_SEQUENCER

/*
 * Sequencer class role is to be a proxy between sequences and driver
 * It also handles arbitration priorities when items are received from multiple sequences at the same time
 */
class amiq_fifo_read_sequencer extends uvm_sequencer #(amiq_fifo_read_item);
	`uvm_component_utils(amiq_fifo_read_sequencer)

	/*
	 * Constructor of the sequencer
	 * @see uvm_pkg::uvm_driver.new
	 * @param name -
	 * @param parent -
	 */
	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction
endclass

`endif
