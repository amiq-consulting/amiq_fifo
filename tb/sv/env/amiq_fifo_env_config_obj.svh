//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_ENV_CONFIG_OBJ
`define AMIQ_FIFO_ENV_CONFIG_OBJ

/*
 * Configuration object for the environment
 */
class amiq_fifo_env_config_obj extends uvm_object;
	`uvm_object_utils(amiq_fifo_env_config_obj)

	// enables/disables checkers
	bit has_checks = 1;

	// enables/disables coverage collection
	bit has_coverage = 1;

	// enables/disables end of test scoreboard checkers
	bit has_eot_scbd_check = 1;

	// indicates if agent is ACTIVE or PASSIVE
	uvm_active_passive_enum write_is_active = UVM_ACTIVE;

	// indicates if agent is ACTIVE or PASSIVE
	uvm_active_passive_enum read_is_active = UVM_ACTIVE;

	// configuration object for the agent
	amiq_fifo_write_config_obj config_obj_write;

	// configuration object for the agent
	amiq_fifo_read_config_obj config_obj_read;

	/*
	 * Constructor of the configuration object
	 * this class has no build_phase since it inherits uvm_object
	 * thus configuration objects for each agent should be instantiated in this constructor
	 * @see uvm_pkg::uvm_object.new
	 * @param name -
	 */
	function new(string name = "amiq_fifo_env_config_obj");
		super.new(name);

		config_obj_write = amiq_fifo_write_config_obj::type_id::create("config_obj_write");
		config_obj_read = amiq_fifo_read_config_obj::type_id::create("config_obj_read");
	endfunction

	// custom function for propagating configuration from the environment towards the agents
	function void configure_agents();
		config_obj_write.is_active = write_is_active;
		config_obj_write.has_checks = has_checks;
		config_obj_write.has_coverage = has_coverage;

		config_obj_read.is_active = read_is_active;
		config_obj_read.has_checks = has_checks;
		config_obj_read.has_coverage = has_coverage;
	endfunction
endclass

`endif
