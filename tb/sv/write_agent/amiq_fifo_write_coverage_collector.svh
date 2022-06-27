//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_COVERAGE_COLLECTOR
`define AMIQ_FIFO_WRITE_COVERAGE_COLLECTOR

// macro for declaring write functions
// + analysis port types for receiving items
`uvm_analysis_imp_decl(_collected_item)
`uvm_analysis_imp_decl(_collected_wr_en_item)

/*
 * Class for encapsulating agent coverage related information
 */
class amiq_fifo_write_coverage_collector extends uvm_component;
	`uvm_component_utils(amiq_fifo_write_coverage_collector)

	// virtual interface for accessing interface signals
	virtual amiq_fifo_write_if write_vif;

	// configuration object
	protected amiq_fifo_write_config_obj config_obj;

	// item used for sampling coverage
	protected amiq_fifo_write_item cover_item;

	// analysis port for receiving items from the monitor
	uvm_analysis_imp_collected_item#(amiq_fifo_write_item, amiq_fifo_write_coverage_collector) monitor_port;
	// analysis port for receiving wr_en items from the monitor
	uvm_analysis_imp_collected_wr_en_item#(amiq_fifo_write_item, amiq_fifo_write_coverage_collector) monitor_wr_en_port;

	// number of back-to-back writes
	// default value is 1 because the counter is incremented by 1, so when 2 b2b transfers are received, we want to sample 2
	int unsigned nof_b2b_writes = 1;

	// flag for marking the first wr_en
	bit had_first_wr_en;

	covergroup wr_data_cg with function sample(bit [(N-1):0] wr_data, int position);
		option.per_instance = 1;

		// Power-of-2 pattern for wr_data
		wr_data_cp : coverpoint position iff (wr_data[position]==1 && ((wr_data&(~((1<<(position+1))-1)))==0)) {
			bins b[] = {[0 : N - 1]};
		}
	endgroup

	covergroup wr_en_distance_cg with function sample (distance_intervals_t distance_in_clk_cycles);
		distance_between_2_consecutive_writes: coverpoint distance_in_clk_cycles {
			bins \0 = {_0};
			bins \1..10 = {_1_TO_10};
			bins \11..50 = {_11_TO_50};
			bins \51_$  = {_51_TO_MAX};
		}

		distance_between_2_consecutive_writes_transition: coverpoint distance_in_clk_cycles {
			bins trans[] = (_0, _1_TO_10, _11_TO_50, _51_TO_MAX  => _0, _1_TO_10, _11_TO_50, _51_TO_MAX);
		}
	endgroup

	covergroup wr_en_back2back_cg (int fifo_depth) with function sample (int back2back_writes);
		nof_back_to_back_writes_cp: coverpoint back2back_writes {
			bins values[] = {[2 : fifo_depth]};
		}
	endgroup

	/*
	 * Constructor function to instantiate the covergroups
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new(string name, uvm_component parent);
		super.new(name, parent);

		wr_data_cg = new();
		wr_data_cg.set_inst_name({get_full_name(), ".wr_data_cg"});
		wr_en_distance_cg = new();
		wr_en_distance_cg.set_inst_name({get_full_name(), ".wr_en_distance_cg"});
		wr_en_back2back_cg = new((1 << P) * M / N);
		wr_en_back2back_cg.set_inst_name({get_full_name(), ".wr_en_back2back_cg"});
	endfunction

	/*
	 * Build function for creating ports and getting values from factory
	 * @see uvm_pkg::uvm_component.build_phase()
	 * @param phase -
	 */
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		monitor_port = new("monitor_port",this);
		monitor_wr_en_port = new("monitor_wr_en_port",this);

		if(!uvm_config_db#(virtual amiq_fifo_write_if)::get(this, "", "fifo_write_vif", write_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_write_vif", get_full_name()));

		if(!uvm_config_db#(amiq_fifo_write_config_obj)::get(this, "", "config_obj", config_obj))
			`uvm_fatal("AGENT_NO_CONFIG_OBJ_ERR", $sformatf("Config object must be set for: %s.config_obj", get_full_name()));
	endfunction

	/*
	 * Analysis port function for receiving items
	 * @param item - item received from the monitor
	 */
	function void write_collected_item(amiq_fifo_write_item item); //item based coverage
		for(int i = 0; i < N; i++) begin
			wr_data_cg.sample(item.wr_data, i);
		end
	endfunction

	/*
	 * Analysis port function for receiving wr_en items
	 * @param item - item received from the monitor
	 */
	function void write_collected_wr_en_item(amiq_fifo_write_item item); //item based coverage
		distance_intervals_t transfer_delay;

		if (item.transfer_delay == 0)
			transfer_delay = _0;
		else if (item.transfer_delay inside {[1:10]})
			transfer_delay = _1_TO_10;
		else if (item.transfer_delay inside {[11:50]})
			transfer_delay = _11_TO_50;
		else
			transfer_delay = _51_TO_MAX;

		if (had_first_wr_en)
			wr_en_distance_cg.sample(transfer_delay);

		if (item.transfer_delay == 0)
			nof_b2b_writes += 1;
		else begin
			// if there were at least two b2b transfers
			if (nof_b2b_writes != 1) begin
				wr_en_back2back_cg.sample(nof_b2b_writes);
				nof_b2b_writes = 1;
			end
		end

		// mark the first wr_en
		if (!had_first_wr_en)
			had_first_wr_en = 1;
	endfunction
endclass

`endif
