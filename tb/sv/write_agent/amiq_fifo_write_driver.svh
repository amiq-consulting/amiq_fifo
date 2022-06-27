//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_DRIVER
`define AMIQ_FIFO_WRITE_DRIVER

/*
 * Driver class for toggling interface signals according to the protocol
 */
class amiq_fifo_write_driver extends uvm_driver#(amiq_fifo_write_item);
	`uvm_component_utils(amiq_fifo_write_driver)

	// virtual interface for accessing signals
	virtual amiq_fifo_write_if write_vif;

	// control virtual interface
	virtual amiq_fifo_control_if control_vif;

	// configuration object
	protected amiq_fifo_write_config_obj config_obj;

	/*
	 * flag for marking the start of a transaction
	 * used in case of any type of reset to call item_done()
	 */
	bit started_driving_transaction;

	/*
	 * Constructor of the class
	 * @see uvm_pkg::uvm_driver.new
	 * @param name -
	 * @param parent -
	 */
	function new (string name, uvm_component parent);
		super.new(name, parent);
	endfunction

	/*
	 * Build function for getting values from factory
	 * @see uvm_pkg::uvm_component.build_phase()
	 * @param phase -
	 */
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(virtual amiq_fifo_write_if)::get(this, "", "fifo_write_vif", write_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_write_vif", get_full_name()));

		if(!uvm_config_db#(virtual amiq_fifo_control_if)::get(this, "", "fifo_control_vif", control_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_control_vif", get_full_name()));

		if(!uvm_config_db#(amiq_fifo_write_config_obj)::get(this, "", "config_obj", config_obj))
			`uvm_fatal("AGENT_NO_CONFIG_OBJ_ERR", $sformatf("Config object must be set for: %s.config_obj", get_full_name()));
	endfunction

	/*
	 * Main task managing driving and reset logic
	 * @see uvm_pkg::uvm_component.run_phase()
	 * @param phase -
	 */
	virtual task run_phase(uvm_phase phase);
		// driving thread
		process main_thread;
		// hard reset thread
		process rst_mon_thread;

		forever
		begin
			fork
				begin
					main_thread = process::self();
					get_and_drive();
				end

				begin
					rst_mon_thread = process::self();
					@(negedge write_vif.rst_n);
					reset_driver();
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
	 * Function for retrieving and drive the next item
	 * item is received from a sequence via the sequencer
	 */
	virtual task get_and_drive();
		// wait for the reset to end
		@(posedge control_vif.rst_n);

		forever
		begin
			seq_item_port.get_next_item(req);
			started_driving_transaction = 1;

			`uvm_info(get_type_name(), $sformatf("fifo in start driving item :\n%s", req.sprint()), UVM_HIGH)
			drive_item(req);
			`uvm_info(get_type_name(), $sformatf("fifo in done driving item :\n%s", req.sprint()), UVM_HIGH)

			started_driving_transaction = 0;
			seq_item_port.item_done();

			// Drive idle values for the signals
			reset_signals();
		end
	endtask

	/*
	 * Task for driving a single item to the interface wires
	 * it toggles the interface wires according to the protocol
	 * @param item The item to be driven on the bus
	 */
	task drive_item(amiq_fifo_write_item item);
		// Wait transfer_delay clock cycles before driving the item
		repeat (item.transfer_delay) begin
			@(posedge write_vif.clk);
		end

		// enable the write transaction
		write_vif.wr_en <= 1;
		// assign the write value from the item
		write_vif.wr_data <= item.wr_data;

		@(posedge write_vif.clk);

	endtask

	// task for bringing all interface signals to their default reset value
	virtual task reset_signals();
		write_vif.wr_en <= 0;
	// TODO add idle values for the signals (ZEROS, ONES, RANDOM, ALL_X, ALL_Z)
	endtask

	// task to reset the driver related fields
	virtual task reset_driver();
		reset_signals();
		// if the flag is 1, a transaction was started but the reset interrupted it
		// so item_done() must be called here
		if (started_driving_transaction) begin
			seq_item_port.item_done();
			// reset the flag after item_done()
			started_driving_transaction = 0;
		end

		write_vif.has_checks = config_obj.has_checks;
	endtask
endclass

`endif
