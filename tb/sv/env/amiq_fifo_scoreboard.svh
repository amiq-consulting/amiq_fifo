//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_SCOREBOARD
`define AMIQ_FIFO_SCOREBOARD

// macro for declaring write functions
// + analysis port types for receiving items
`uvm_analysis_imp_decl(_agent_write_port)
`uvm_analysis_imp_decl(_agent_read_port)

/*
 * Class for holding scoreboarding logic when main checking occurs
 */
class amiq_fifo_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(amiq_fifo_scoreboard)

	// analysis port for receiving data from the in agent monitor
	uvm_analysis_imp_agent_write_port #(amiq_fifo_write_item, amiq_fifo_scoreboard) agent_write_port;

	// analysis port for receiving data from the out agent monitor
	uvm_analysis_imp_agent_read_port #(amiq_fifo_read_item, amiq_fifo_scoreboard) agent_read_port;

	// pointer towards the configuration object of the environment
	protected amiq_fifo_env_config_obj env_config_obj;

	// status virtual interface
	virtual amiq_fifo_status_if status_vif;
	// control virtual interface
	virtual amiq_fifo_control_if control_vif;

	/* FIFO depth (max size for FIFO)
	 * makes sense to be consider P (2^P), as the thresholds are on P bits
	 */
	localparam FIFO_DEPTH = 1 << P;
	// FIFO memory (considered M to be important, as it is the output bits)
	bit [0 : (FIFO_DEPTH * M - 1)]  expected_mem;
	// read address
	bit [(FIFO_DEPTH - 1) : 0] rdaddr;
	// write address
	bit [((FIFO_DEPTH * M / N) - 1) : 0] wraddr;

	/*
	 * Constructor of the scoreboard
	 * instantiates analysis ports
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new(string name = "amiq_fifo_scoreboard", uvm_component parent);
		super.new(name, parent);

		agent_write_port  = new("agent_write_port", this);
		agent_read_port = new("agent_read_port", this);
	endfunction

	/*
	 * Scoreboard receives collected items from the monitor
	 * the analysis port is the communication channel between the scoreboard and the monitor
	 * every time an item is received this function is being called
	 * @param item - item received from the in monitor
	 */
	function void write_agent_write_port(amiq_fifo_write_item received_item);
		`uvm_info(get_name(),$sformatf("received WRITE"), UVM_LOW)

		// write the new data in memory
		write_memory(received_item);
	endfunction

	/*
	 * Scoreboard receives collected items from the monitor
	 * the analysis port is the communication channel between the scoreboard and the monitor
	 * every time an item is received this function is being called
	 * @param item - item received from the out monitor
	 */
	function void write_agent_read_port(amiq_fifo_read_item received_item);
		`uvm_info(get_name(),$sformatf("received READ"), UVM_LOW)

		// read the data from memory and compare with received data (RTL output)
		read_memory(received_item);
	endfunction

	/*
	 *  Build phase from the UVM methodology
	 * @see uvm_pkg::uvm_component.build_phase
	 * @param phase -
	 */
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(virtual amiq_fifo_status_if)::get(this, "", "fifo_status_vif", status_vif))
			`uvm_fatal("SCBD_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_status_vif", get_full_name()));

		if(!uvm_config_db#(virtual amiq_fifo_control_if)::get(this, "", "fifo_control_vif", control_vif))
			`uvm_fatal("SCBD_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_control_vif", get_full_name()));

		if(!uvm_config_db#(amiq_fifo_env_config_obj)::get(this, "", "env_config_obj", env_config_obj))
			`uvm_fatal("SCBD_NO_CONFIG_OBJ_ERR", $sformatf("Config object must be set for: %s.env_config_obj", get_full_name()) );
	endfunction

	/*
	 * Task for taking various actions during simulation
	 * @see uvm_pkg::uvm_component.run_phase
	 * @param phase -
	 */
	virtual task run_phase(uvm_phase phase);
		fork
			begin
				reset_scoreboard();
			end
		join_none
	endtask

	function void write_memory(amiq_fifo_write_item received_item);
		// write the data in memory
		for (int i = 0; i < N; i++) begin
			expected_mem[(wraddr * N + i) % (FIFO_DEPTH * M)] = received_item.wr_data[N - 1 - i];
		end

		// increment write address
		wraddr += 1;
	endfunction

	function void read_memory(amiq_fifo_read_item received_item);
		bit [M - 1 : 0] expected_data;

		// store the data from the memory in expected_data
		for (int i = 0; i <= M - 1; i++) begin
			expected_data[M - 1 - i] = expected_mem[(i + rdaddr * M) % (FIFO_DEPTH * M)];
		end

		// increment read address
		rdaddr += 1;

		// check that the expected data value matches the received item value
		AMIQ_FIFO_DATA_INTEGRITY_CHK: assert (expected_data == received_item.rd_data)
		else `uvm_error("AMIQ_FIFO_DATA_INTEGRITY_CHK", $sformatf("Read data %x did not match expected data %x.", received_item.rd_data, expected_data));

		`uvm_info(get_name(),$sformatf("rd_datadata %x; expected_data %x.", received_item.rd_data, expected_data), UVM_LOW)
	endfunction

	virtual task reset_scoreboard();
		forever begin
			// reset inactive
			while (!(!control_vif.rst_n))
				@(posedge control_vif.clk);

			`uvm_info(get_name(),$sformatf("had reset"), UVM_LOW)

			// any type of reset
			wraddr <= 0;
			rdaddr <= 0;

			// hard reset
			if (!control_vif.rst_n) begin
				// reset the entire memory
				for (int i = 0; i < FIFO_DEPTH * M; i++)
					expected_mem[i] <= 0;
			end

			@(posedge control_vif.clk);
		end
	endtask

endclass

`endif
