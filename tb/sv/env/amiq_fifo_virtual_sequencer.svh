//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_VIRTUAL_SEQUENCER
`define AMIQ_FIFO_VIRTUAL_SEQUENCER

/*
 * Virtual sequencer class for managing the virtual sequences
 */
class amiq_fifo_virtual_sequencer extends uvm_sequencer;
	`uvm_component_utils(amiq_fifo_virtual_sequencer)

	// sequencer handle for input agent
	amiq_fifo_write_sequencer write_sequencer;

	// sequencer handle for output agent
	amiq_fifo_read_sequencer read_sequencer;

	// control virtual interface
	virtual amiq_fifo_control_if control_vif;

	/*
	 * Constructor for the virtual sequencer
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */

	function new(string name = "amiq_fifo_virtual_sequencer", uvm_component parent);
		super.new(name, parent);
	endfunction

	task drive_reset(int unsigned reset_delay, int unsigned reset_duration);
		// wait delay
		#(reset_delay);
		`uvm_info("DRIVE_RESET", $sformatf("Waited %0d delay", reset_delay), UVM_HIGH)

		// assert the reset
		control_vif.rst_n <= 0;
		`uvm_info("DRIVE_RESET", $sformatf("Activated hard reset"), UVM_HIGH)

		// wait reset_duration clock cycles until the reset deactivates
		repeat (reset_duration)
			@(posedge control_vif.clk);

		`uvm_info("DRIVE_RESET", $sformatf("Waited %0d clock cycles before deasserting the reset", reset_duration), UVM_HIGH)

		// deassert the reset
		control_vif.rst_n <= 1;

		`uvm_info("DRIVE_RESET", $sformatf("Deasserted reset"), UVM_HIGH)
	endtask

	task set_thresh(bit [(P-1):0] alm_full_thresh, bit [(P-1):0] alm_empty_thresh, int unsigned delay);
		// wait delay
		repeat (delay)
			@(posedge control_vif.clk);
		`uvm_info("SET_THRESH", $sformatf("Waited %0d delay", delay), UVM_HIGH)

		`uvm_info("SET_THRESH", $sformatf("alm_full_thresh = %0d", alm_full_thresh), UVM_HIGH)
		`uvm_info("SET_THRESH", $sformatf("alm_empty_thresh = %0d", alm_empty_thresh), UVM_HIGH)

		control_vif.alm_full_thresh <= alm_full_thresh;
		control_vif.alm_empty_thresh <= alm_empty_thresh;
	endtask
endclass

`endif
