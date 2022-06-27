//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_BASE_TEST
`define AMIQ_FIFO_BASE_TEST

/*
 * This is the base test where common logic for all tests should be placed
 * Creates the env, the virtual sequence and the env configuration object
 */
class amiq_fifo_base_test extends uvm_test;
	`uvm_component_utils(amiq_fifo_base_test)

	// environment object
	amiq_fifo_env env;

	// virtual sequence object
	amiq_fifo_virtual_sequence vseq;

	// configuration object used by the environment
	amiq_fifo_env_config_obj env_config_obj;

	// Indicates pass/fail of the test
	bit test_pass = 1;

	// printer for printing UVM related topology
	uvm_table_printer printer;

	/*
	 * Constructor for the base test class
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new(string name = "amiq_fifo_base_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	/*
	 * Builds/creates the objects used in the test
	 * @see uvm_pkg::uvm_component.build_phase
	 * @param phase -
	 */
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		env_config_obj = amiq_fifo_env_config_obj::type_id::create("config_obj", env);

		// set the config object
		uvm_config_db#(amiq_fifo_env_config_obj)::set(this, "env*", "env_config_obj", env_config_obj);

		env = amiq_fifo_env::type_id::create("env", this);

		// Create a specific depth printer for printing the created topology
		printer = new();
		printer.knobs.depth = 3;
	endfunction

	/*
	 * Perform actions at the end of elaboration phase
	 * @see uvm_pkg::uvm_component.end_of_elaboration_phase
	 * @param phase -
	 */
	virtual function void end_of_elaboration_phase(uvm_phase phase);
		// Print the test topology
		`uvm_info(get_type_name(), $sformatf("Printing the test topology :\n%s", this.sprint(printer)), UVM_LOW)
	endfunction : end_of_elaboration_phase

	/*
	 * Main task for managing the test scenario
	 * @see uvm_pkg::uvm_component.run_phase
	 * @param phase -
	 */
	virtual task run_phase(uvm_phase phase);
		super.run_phase(phase);
		// Set a drain-time
		phase.phase_done.set_drain_time(this, 10);
	endtask : run_phase

	/*
	 * Add here messages regarding status of the test
	 * @see uvm_pkg::uvm_component.report_phase
	 * @param phase -
	 */
	virtual function void report_phase(uvm_phase phase);
		if(test_pass) begin
			`uvm_info(get_type_name(), "** UVM TEST PASSED **", UVM_NONE)
		end
		else begin
			`uvm_error(get_type_name(), "** UVM TEST FAIL **")
		end
	endfunction : report_phase
endclass

`endif
