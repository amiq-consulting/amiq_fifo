//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_READ_AGENT
`define AMIQ_FIFO_READ_AGENT

/*
 * Agent class taking care of driving, monitoring and coverage collection
 */
class amiq_fifo_read_agent extends uvm_agent;
	`uvm_component_utils(amiq_fifo_read_agent)

	// configuration object for the entire agent
	protected amiq_fifo_read_config_obj config_obj;

	// driver object pulling on the agent interface wires
	amiq_fifo_read_driver driver;

	// sequencer object serving sequence items from the sequence towards the driver
	amiq_fifo_read_sequencer sequencer;

	// monitor object for observing interface traffic
	amiq_fifo_read_monitor monitor;

	// coverage collector related to agent
	amiq_fifo_read_coverage_collector coverage_collector;

	// constructor for the agent class
	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	/*
	 * Built in function for creating all required agent objects
	 * @see uvm_pkg::uvm_agent.build_phase
	 * @param phase -
	 */
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		monitor = amiq_fifo_read_monitor::type_id::create("monitor", this);

		if(!uvm_config_db#(amiq_fifo_read_config_obj)::get(this, "", "config_obj", config_obj))
			`uvm_fatal("NOCONFIG", {"Config object must be set for: ", get_full_name(), ".config_obj"})

		if(config_obj.has_coverage) begin
			coverage_collector = amiq_fifo_read_coverage_collector::type_id::create("coverage_collector", this);
		end

		// instantiate the driver and the sequencer only for an ACTIVE agent
		if(config_obj.is_active == UVM_ACTIVE) begin
			driver = amiq_fifo_read_driver::type_id::create("driver", this);
			sequencer = amiq_fifo_read_sequencer::type_id::create("sequencer", this);
		end
	endfunction

	/*
	 * Built in function for connecting the ports inside the agent's components
	 * @see uvm_pkg::uvm_agent.build_phase
	 * @param phase -
	 */
	virtual function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		if(config_obj.has_coverage) begin
			monitor.collected_item_port.connect(coverage_collector.monitor_port);
			monitor.collected_rd_en_item_port.connect(coverage_collector.monitor_rd_en_port);
		end

		if(config_obj.is_active == UVM_ACTIVE) begin
			driver.seq_item_port.connect(sequencer.seq_item_export);
		end
	endfunction
endclass

`endif
