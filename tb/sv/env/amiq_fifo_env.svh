//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_ENV
`define AMIQ_FIFO_ENV

/*
 * Environment class which encapsulates all verification components
 * agents, configuration objects, scoreboard(s), coverage collector, etc
 */
class amiq_fifo_env extends uvm_env;
	`uvm_component_utils(amiq_fifo_env)

	// configuration object for the entire environment
	amiq_fifo_env_config_obj env_config_obj;

	// instance of an agent
	amiq_fifo_write_agent write_agent;

	// instance of an agent
	amiq_fifo_read_agent read_agent;

	// scoreboard object used for checking
	amiq_fifo_scoreboard scbd;

	// virtual sequencer object for coordinating traffic
	amiq_fifo_virtual_sequencer vseqr;

	// coverage collector object
	amiq_fifo_env_coverage_collector cov_collector;

	// custom repoter for changing the way the UVM message printing looks like
	amiq_fifo_custom_reporter custom_reporter;

	// control virtual interface
	virtual amiq_fifo_control_if control_vif;

	// block virtual interface
	virtual amiq_fifo_block_if block_vif;

	/*
	 * Constructor for the environment
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new(string name = "amiq_fifo_env", uvm_component parent);
		super.new(name, parent);

		// instantiate the custom reporter
		custom_reporter = new;

		// Override default UVM reporter
		if ($test$plusargs("USE_CUSTOM_UVM_REPORTER")) begin
			`uvm_info("USE_CUSTOM_UVM_REPORTER",$sformatf("Replacing the default UVM reporter with a custom reporter"), UVM_LOW)
			uvm_report_server::set_server( custom_reporter );
		end
	endfunction

	/*
	 *  Function for building the components of the environment
	 * or for getting and passing further the configuration objects
	 * @see uvm_pkg::uvm_component.build_phase
	 * @param phase -
	 */
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(amiq_fifo_env_config_obj)::get(this, "", "env_config_obj", env_config_obj))
			`uvm_fatal("ENV_NO_CONFIG_OBJ_ERR", $sformatf("Config object must be set for: %s.env_config_obj", get_full_name()) );

		// call the function for propagating required information towards the agent config objects
		env_config_obj.configure_agents();

		// further passing down the configuration objects for the agents
		uvm_config_db#(amiq_fifo_write_config_obj)::set(this, "write_agent*", "config_obj", env_config_obj.config_obj_write);
		uvm_config_db#(amiq_fifo_read_config_obj)::set(this, "read_agent*", "config_obj", env_config_obj.config_obj_read);

		// get the control interface
		if(!uvm_config_db#(virtual amiq_fifo_control_if)::get(this, "", "fifo_control_vif", control_vif))
			`uvm_fatal("ENV_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_control_vif", get_full_name()));

		// get the block interafce
		if(!uvm_config_db#(virtual amiq_fifo_block_if)::get(this, "", "fifo_block_vif", block_vif))
			`uvm_fatal("ENV_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_block_vif", get_full_name()));

		// instantiate agents and the other env components
		write_agent = amiq_fifo_write_agent::type_id::create("write_agent", this);
		read_agent = amiq_fifo_read_agent::type_id::create("read_agent", this);
		vseqr = amiq_fifo_virtual_sequencer::type_id::create("vseqr", this);
		scbd = amiq_fifo_scoreboard::type_id::create("scbd", this);

		if (env_config_obj.has_coverage)
			cov_collector = amiq_fifo_env_coverage_collector::type_id::create("cov_collector", this);

		block_vif.has_checks = env_config_obj.has_checks;

	endfunction

	/*
	 * Function for connecting ports or instances inside the environment
	 * it is done at this level because we have visibility to all the components
	 * @see uvm_pkg::uvm_component.connect_phase
	 * @param phase -
	 */
	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		if (env_config_obj.has_coverage) begin
			write_agent.monitor.collected_item_port.connect(cov_collector.write_port);
			read_agent.monitor.collected_item_port.connect(cov_collector.read_port);
		end

		// bind the physical sequencers pointers from the virtual sequencer
		vseqr.write_sequencer = write_agent.sequencer;
		vseqr.read_sequencer = read_agent.sequencer;
		// pass the interface to the virtual sequencer
		vseqr.control_vif = control_vif;

		// connect the scoreboard ports to the monitor ports
		write_agent.monitor.collected_item_port.connect(scbd.agent_write_port);
		read_agent.monitor.collected_item_port.connect(scbd.agent_read_port);

	endfunction
endclass

`endif
