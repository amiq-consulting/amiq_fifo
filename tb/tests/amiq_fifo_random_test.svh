//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_RANDOM_TEST
`define AMIQ_FIFO_RANDOM_TEST

/*
 * Random test
 */
class amiq_fifo_random_test extends amiq_fifo_base_test;
	`uvm_component_utils(amiq_fifo_random_test)

	/*
	 * Constructor for the random test class
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new(string name = "amiq_fifo_random_test", uvm_component parent=null);
		super.new(name, parent);

		uvm_config_wrapper::set(uvm_root::get(), "*env.vseqr.run_phase", "default_sequence", amiq_fifo_virtual_sequence::type_id::get());
	endfunction

	/*
	 * Builds/creates/changes the objects used in the test
	 * @see uvm_pkg::uvm_component.build_phase
	 * @param phase -
	 */
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	endfunction
endclass

`endif
