//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_READ_MONITOR
`define AMIQ_FIFO_READ_MONITOR

/*
 * Class for monitoring and collecting information on bus activity
 * Collected information is broadcasted to various subscribers
 */
class amiq_fifo_read_monitor extends uvm_monitor;
	`uvm_component_utils(amiq_fifo_read_monitor)

	// virtual interface for accessing signals
	virtual amiq_fifo_read_if read_vif;
	// virtual interface for accessing status signals
	virtual amiq_fifo_status_if status_vif;
	// virtual control interface
	virtual amiq_fifo_control_if control_vif;
	// configuration object
	protected amiq_fifo_read_config_obj config_obj;

	// analysis port for posting collected items
	uvm_analysis_port #(amiq_fifo_read_item) collected_item_port;
	// analysis port for posting collected rd_en items
	uvm_analysis_port #(amiq_fifo_read_item) collected_rd_en_item_port;

	/*
	 * Constructor function of the class where analysis ports are created
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new (string name, uvm_component parent);
		super.new(name, parent);

		collected_item_port = new("collected_item_port", this);
		collected_rd_en_item_port = new("collected_rd_en_item_port", this);
	endfunction

	/*
	 * Build function for getting values from factory
	 * @see uvm_pkg::uvm_component.build_phase
	 * @param phase -
	 */
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(virtual amiq_fifo_read_if)::get(this, "", "fifo_read_vif", read_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_read_vif", get_full_name()));

		if(!uvm_config_db#(virtual amiq_fifo_status_if)::get(this, "", "fifo_status_vif", status_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_status_vif", get_full_name()));

		if(!uvm_config_db#(virtual amiq_fifo_control_if)::get(this, "", "fifo_control_vif", control_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_control_vif", get_full_name()));

		if(!uvm_config_db#(amiq_fifo_read_config_obj)::get(this, "", "config_obj", config_obj))
			`uvm_fatal("AGENT_NO_CONFIG_OBJ_ERR", $sformatf("Config object must be set for: %s.config_obj", get_full_name()));
	endfunction

	/*
	 * Main task for managing monitoring and reset logic
	 * @see uvm_pkg::uvm_component.run_phase()
	 * @param phase -
	 */
	virtual task run_phase(uvm_phase phase);
		// monitoring thread
		process main_thread;
		// hard reset thread
		process rst_mon_thread;

		forever
		begin
			fork
				begin
					main_thread = process::self();
					monitor_items();
				end

				begin
					rst_mon_thread = process::self();
					@(negedge read_vif.rst_n);
//					reset_monitor();
				end
			join_any

			// kill all threads
			if(main_thread)
				main_thread.kill();
			if(rst_mon_thread)
				rst_mon_thread.kill();
		end
	endtask

	/*
	 * The main monitoring task
	 * it recognizes and collects item by item
	 * it then publishes them to the analysis port
	 */
	virtual task monitor_items();
		amiq_fifo_read_item item;
		// item useful for coverage
		amiq_fifo_read_item rd_en_item;
		// delay between rd_en
		int unsigned delay_between_rd_en;

		// wait for the reset to end
		@(posedge control_vif.rst_n);

		forever begin
			// Read transfer was enabled in the previous clock cycle and FIFO wasn't empty
			if (read_vif.rd_en && !status_vif.empty) begin
				item = amiq_fifo_read_item::type_id::create("item", this);
				// sample the data
				item.rd_data = read_vif.rd_data;

				// write the item using the analysis port
				collected_item_port.write(item);
				`uvm_info(get_type_name(), $sformatf("READ monitor :\n%s", item.sprint()), UVM_LOW)
			end
			if (read_vif.rd_en) begin
				rd_en_item = amiq_fifo_read_item::type_id::create("rd_en_item", this);
				rd_en_item.transfer_delay = delay_between_rd_en;
				collected_rd_en_item_port.write(rd_en_item);
				delay_between_rd_en = 0;
			end
			else
				delay_between_rd_en += 1;

			@(posedge read_vif.clk);
		end
	endtask
	
endclass

`endif
