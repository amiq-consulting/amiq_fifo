//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_READ_COVERAGE_COLLECTOR
`define AMIQ_FIFO_READ_COVERAGE_COLLECTOR

// macro for declaring write functions
// + analysis port types for receiving items
`uvm_analysis_imp_decl(_collected_item)
`uvm_analysis_imp_decl(_collected_rd_en_item)

/*
 * Class for encapsulating agent coverage related information
 */
class amiq_fifo_read_coverage_collector extends uvm_component;
	`uvm_component_utils(amiq_fifo_read_coverage_collector)

	// virtual interface for accessing interface signals
	virtual amiq_fifo_read_if read_vif;

	// configuration object
	protected amiq_fifo_read_config_obj config_obj;

	// item used for sampling coverage
	protected amiq_fifo_read_item cover_item;

	// analysis port for receiving items from the monitor
	uvm_analysis_imp_collected_item#(amiq_fifo_read_item, amiq_fifo_read_coverage_collector) monitor_port;
	// analysis port for receiving rd_en item from the monitor
	uvm_analysis_imp_collected_rd_en_item#(amiq_fifo_read_item, amiq_fifo_read_coverage_collector) monitor_rd_en_port;

	// number of back-to-back reads
	// default value is 1 because the counter is incremented by 1, so when 2 b2b transfers are received, we want to sample 2
	int unsigned nof_b2b_reads = 1;

	// flag for marking the first rd_en
	bit had_first_rd_en;

	covergroup rd_data_cg with function sample(bit [(M-1):0] rd_data, int position);
		option.per_instance = 1;

		// Power-of-2 pattern for rd_data
		rd_data_cp : coverpoint position iff (rd_data[position]==1 && ((rd_data&(~((1<<(position+1))-1)))==0)) {
			bins b[] = {[0 : M - 1]};
		}
	endgroup

	covergroup rd_en_distance_cg with function sample (distance_intervals_t distance_in_clk_cycles);
		distance_between_2_consecutive_reads: coverpoint distance_in_clk_cycles {
			bins \0 = {_0};
			bins \1..10 = {_1_TO_10};
			bins \11..50 = {_11_TO_50};
			bins \51_$  = {_51_TO_MAX};
		}

		distance_between_2_consecutive_reads_transition: coverpoint distance_in_clk_cycles {
			bins trans[] = (_0, _1_TO_10, _11_TO_50, _51_TO_MAX  => _0, _1_TO_10, _11_TO_50, _51_TO_MAX);
		}
	endgroup

	covergroup rd_en_back2back_cg (int fifo_depth) with function sample (int back2back_reads);
		nof_back_to_back_reads_cp: coverpoint back2back_reads {
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

		rd_data_cg = new();
		rd_data_cg.set_inst_name({get_full_name(), ".rd_data_cg"});
		rd_en_distance_cg = new();
		rd_en_distance_cg.set_inst_name({get_full_name(), ".rd_en_distance_cg"});
		rd_en_back2back_cg = new((1 << P));
		rd_en_back2back_cg.set_inst_name({get_full_name(), ".rd_en_back2back_cg"});
	endfunction

	/*
	 * Build function for creating ports and getting values from factory
	 * @see uvm_pkg::uvm_component.build_phase()
	 * @param phase -
	 */
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		monitor_port = new("monitor_port",this);
		monitor_rd_en_port = new("monitor_rd_en_port",this);

		if(!uvm_config_db#(virtual amiq_fifo_read_if)::get(this, "", "fifo_read_vif", read_vif))
			`uvm_fatal("AGENT_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_read_vif", get_full_name()));

		if(!uvm_config_db#(amiq_fifo_read_config_obj)::get(this, "", "config_obj", config_obj))
			`uvm_fatal("AGENT_NO_CONFIG_OBJ_ERR", $sformatf("Config object must be set for: %s.config_obj", get_full_name()));
	endfunction

	/*
	 * Analysis port function for receiving items
	 * @param item - item received from the monitor
	 */
	function void write_collected_item(amiq_fifo_read_item item); //item based coverage
		for(int i = 0; i < M; i++) begin
			rd_data_cg.sample(item.rd_data, i);
		end
	endfunction

	/*
	 * Analysis port function for receiving rd_en items
	 * @param item - item received from the monitor
	 */
	function void write_collected_rd_en_item(amiq_fifo_read_item item); //item based coverage
		distance_intervals_t rd_en_delay;

		if (item.transfer_delay == 0)
			rd_en_delay = _0;
		else if (item.transfer_delay inside {[1:10]})
			rd_en_delay = _1_TO_10;
		else if (item.transfer_delay inside {[11:50]})
			rd_en_delay = _11_TO_50;
		else
			rd_en_delay = _51_TO_MAX;
		
		if (had_first_rd_en)
			rd_en_distance_cg.sample(rd_en_delay);

		if (item.transfer_delay == 0)
			nof_b2b_reads += 1;
		else begin
			// if there were at least two b2b transfers
			if (nof_b2b_reads != 1) begin
				rd_en_back2back_cg.sample(nof_b2b_reads);
				nof_b2b_reads = 1;
			end
		end

		// mark the first rd_en
		if (!had_first_rd_en)
			had_first_rd_en = 1;
	endfunction
endclass

`endif
