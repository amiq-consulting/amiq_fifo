//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_CONFIG_OBJ
`define AMIQ_FIFO_WRITE_CONFIG_OBJ

/*
 * Configuration class for holding agent configuration fields
 * They will be used all over the agent's components
 */
class amiq_fifo_write_config_obj extends uvm_object;

	// field for determining if the agent is ACTIVE or PASSIVE
	uvm_active_passive_enum is_active = UVM_ACTIVE;

	// enabler for agent checkers
	bit has_checks = 1;

	// enabler for agent coverage
	bit has_coverage = 1;

	`uvm_object_utils_begin(amiq_fifo_write_config_obj)
		`uvm_field_enum(uvm_active_passive_enum, is_active, UVM_DEFAULT)
		`uvm_field_int(has_checks, UVM_DEFAULT)
		`uvm_field_int(has_coverage, UVM_DEFAULT)
	`uvm_object_utils_end

	/*
	 * Constructor function for the configuration object
	 * @see uvm_pkg::uvm_object.new
	 * @param name -
	 */
	function new(string name = "amiq_fifo_write_config_obj");
		super.new(name);
	endfunction
endclass

`endif
