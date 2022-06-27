//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_ENV_COVERAGE_COLLECTOR
`define AMIQ_FIFO_ENV_COVERAGE_COLLECTOR

// macro for declaring write functions
// + analysis port types for receiving items
`uvm_analysis_imp_decl(_in_port)
`uvm_analysis_imp_decl(_out_port)

/*
 * Coverage collector class for the verification environment
 */
 
class amiq_fifo_env_coverage_collector extends uvm_component;
	`uvm_component_utils(amiq_fifo_env_coverage_collector)

	// analysis port for receiving data from the monitor
	uvm_analysis_imp_in_port#(amiq_fifo_write_item, amiq_fifo_env_coverage_collector) write_port;

	// analysis port for receiving data from the monitor
	uvm_analysis_imp_out_port#(amiq_fifo_read_item, amiq_fifo_env_coverage_collector) read_port;

	// virtual status interface
	virtual amiq_fifo_status_if status_vif;

	// virtual control interface
	virtual amiq_fifo_control_if control_vif;

	// virtual block interface
	virtual amiq_fifo_block_if block_vif;

	// previous value of status alm_empty_thresh
	bit [(P-1):0] prev_status_alm_empty_thresh;
	// previous value of status alm_full_thresh
	bit [(P-1):0] prev_status_alm_full_thresh;
	// Back-to-back writes counter
	int nof_back2back_wr;
	// Reads counter
	int nof_reads;
	// flag that marks alm_full assertion
	bit had_alm_full;
	// flag that marks alm_empty assertion
	bit had_alm_empty;
	// previous value of block alm_empty_thresh
	bit [(P-1):0] prev_block_alm_empty_thresh;
	// previous value of block alm_full_thresh
	bit [(P-1):0] prev_block_alm_full_thresh;
	// flag for marking the sample of first thresh values
	bit sampled_first_thresh_values;

	covergroup alm_empty_threshold_cg with function sample (bit[P-1 : 0] threshold);
		threshold_val_cp: coverpoint threshold {
			bins min = {0};
			bins middle[P] = {[ 1 : 2**(P) - 2]};
			bins max = {2**(P) - 1};
		}
	endgroup

	covergroup alm_full_threshold_cg with function sample (bit[P-1 : 0] threshold);
		threshold_val_cp: coverpoint threshold {
			bins min = {0};
			bins middle[P] = {[ 1 : 2**(P) - 2]};
			bins max = {2**(P) - 1};
		}
	endgroup

	covergroup empty_cg with function sample (bit empty, bit alm_empty);
		empty_val: coverpoint empty {
			bins \0 = {0};
			bins \1 = {1};
		}
		alm_empty_val: coverpoint alm_empty {
			bins \0 = {0};
			bins \1 = {1};
		}
	endgroup

	covergroup full_cg with function sample (bit full, bit alm_full);
		full_val: coverpoint full {
			bins \0 = {0};
			bins \1 = {1};
		}
		alm_full_val: coverpoint alm_full {
			bins \0 = {0};
			bins \1 = {1};
		}
	endgroup

	covergroup wr_with_rd_cg with function sample (bit wr_en, bit rd_en);
		wr_en_val: coverpoint wr_en {
			bins \0 = {0};
			bins \1 = {1};
		}
		rd_en_val: coverpoint rd_en {
			bins \0 = {0};
			bins \1 = {1};
		}
		wr_en_x_rd_en: cross wr_en_val, rd_en_val;
	endgroup

	covergroup wr_en_back2back_with_simultaneous_reads_cg (int wr_fifo_depth, int rd_fifo_depth) with function sample (int back2back_writes, int nof_reads);
		nof_back_to_back_writes: coverpoint back2back_writes {
			bins values[] = {[2 : wr_fifo_depth]};
		}
		nof_reads_val: coverpoint nof_reads{
			bins \0..1 = {[0:1]};
			bins values[] = {[2 : rd_fifo_depth]};
		}
		nof_back_to_back_writes_x_nof_reads_val: cross nof_back_to_back_writes, nof_reads_val;
	endgroup

	covergroup alm_empty_x_alm_full_thresholds_cg with function sample (bit[P-1 : 0] alm_empty_threshold, bit[P-1 : 0] alm_full_threshold);
		alm_empty_threshold_val: coverpoint alm_empty_threshold {
			bins min = {0};
			bins middle[P] = {[ 1 : 2**(P) - 2]};
			bins max = {2**(P) - 1};
		}
		alm_full_threshold_val: coverpoint alm_full_threshold {
			bins min = {0};
			bins middle[P] = {[ 1 : 2**(P) - 2]};
			bins max = {2**(P) - 1};
		}
		empty_thresh_x_full_thresh: cross alm_empty_threshold_val, alm_full_threshold_val;
	endgroup

	covergroup overflow_cg with function sample (bit overflow);
		overflow_val: coverpoint overflow {
			bins \0 = {0};
			bins \1 = {1};
		}
	endgroup

	covergroup underflow_cg with function sample (bit underflow);
		underflow_val: coverpoint underflow {
			bins \0 = {0};
			bins \1 = {1};
		}
	endgroup
	
	covergroup fill_level_status_on_write_cg with function sample (bit empty, bit alm_empty, bit alm_full, bit full);
    	empty_val: coverpoint empty {
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	alm_empty_val: coverpoint alm_empty {
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	alm_full_val: coverpoint alm_full {
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	full_val: coverpoint full{
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	empty_val_x_alm_empty_val_x_alm_full_val_x_full_val: cross empty_val, alm_empty_val, alm_full_val, full_val {
	    	ignore_bins full_and_empty = empty_val_x_alm_empty_val_x_alm_full_val_x_full_val with (empty_val == 1 && full_val == 1);
	    	ignore_bins empty_without_alm_empty = empty_val_x_alm_empty_val_x_alm_full_val_x_full_val with (empty_val == 1 && alm_empty_val == 0);
	    	ignore_bins full_without_alm_full = empty_val_x_alm_empty_val_x_alm_full_val_x_full_val with (full_val == 1 && alm_full_val == 0);
    	}
	endgroup
	
	covergroup fill_level_status_on_read_cg with function sample (bit empty, bit alm_empty, bit alm_full, bit full);
    	empty_val: coverpoint empty {
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	alm_empty_val: coverpoint alm_empty {
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	alm_full_val: coverpoint alm_full {
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	full_val: coverpoint full{
        	bins \0 = {0};
        	bins \1 = {1};
    	}
    	empty_val_x_alm_empty_val_x_alm_full_val_x_full_val: cross empty_val, alm_empty_val, alm_full_val, full_val {
	    	ignore_bins full_and_empty = empty_val_x_alm_empty_val_x_alm_full_val_x_full_val with (empty_val == 1 && full_val == 1);
	    	ignore_bins empty_without_alm_empty = empty_val_x_alm_empty_val_x_alm_full_val_x_full_val with (empty_val == 1 && alm_empty_val == 0);
	    	ignore_bins full_without_alm_full = empty_val_x_alm_empty_val_x_alm_full_val_x_full_val with (full_val == 1 && alm_full_val == 0);
    	}
	endgroup


	/*
	 * Constructor for the coverage collector
	 * it instantiates the analysis ports and the covergroups
	 * @see uvm_pkg::uvm_component.new
	 * @param name -
	 * @param parent -
	 */
	function new(string name, uvm_component parent);
		super.new(name, parent);

		write_port = new("write_port", this);
		read_port = new("read_port", this);

		alm_empty_threshold_cg = new();
		alm_empty_threshold_cg.set_inst_name({get_full_name(), ".alm_empty_threshold_cg"});
		alm_full_threshold_cg = new();
		alm_full_threshold_cg.set_inst_name({get_full_name(), ".alm_full_threshold_cg"});
		empty_cg = new();
		empty_cg.set_inst_name({get_full_name(), ".empty_cg"});
		full_cg = new();
		full_cg.set_inst_name({get_full_name(), ".full_cg"});
		wr_with_rd_cg = new();
		wr_with_rd_cg.set_inst_name({get_full_name(), ".wr_with_rd_cg"});
		wr_en_back2back_with_simultaneous_reads_cg = new((1 << P) * M / N, (1 << P));
		wr_en_back2back_with_simultaneous_reads_cg.set_inst_name({get_full_name(), ".wr_en_back2back_with_simultaneous_reads_cg"});
		alm_empty_x_alm_full_thresholds_cg = new();
		alm_empty_x_alm_full_thresholds_cg.set_inst_name({get_full_name(), ".alm_empty_x_alm_full_thresholds_cg"});
		overflow_cg = new();
		overflow_cg.set_inst_name({get_full_name(), ".overflow_cg"});
		underflow_cg = new();
		underflow_cg.set_inst_name({get_full_name(), ".underflow_cg"});
		fill_level_status_on_write_cg = new();
		fill_level_status_on_write_cg.set_inst_name({get_full_name(), ".fill_level_status_on_write_cg"});
		fill_level_status_on_read_cg = new();
		fill_level_status_on_read_cg.set_inst_name({get_full_name(), ".fill_level_status_on_read_cg"});
	endfunction

	/*
	 *  Build phase from the UVM methodology
	 * @see uvm_pkg::uvm_component.build_phase
	 * @param phase -
	 */
	virtual function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		if(!uvm_config_db#(virtual amiq_fifo_status_if)::get(this, "", "fifo_status_vif", status_vif))
			`uvm_fatal("ENV_COV_COLL_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_status_vif", get_full_name()));

		if(!uvm_config_db#(virtual amiq_fifo_control_if)::get(this, "", "fifo_control_vif", control_vif))
			`uvm_fatal("ENV_COV_COLL_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_control_vif", get_full_name()));

		if(!uvm_config_db#(virtual amiq_fifo_block_if)::get(this, "", "fifo_block_vif", block_vif))
			`uvm_fatal("ENV_COV_COLL_NOVIF_ERR", $sformatf("Virtual interface must be set for: %s.fifo_block_vif", get_full_name()));
	endfunction

	/*
	 * Task for taking various actions during simulation
	 * @see uvm_pkg::uvm_component.run_phase
	 * @param phase -
	 */
	virtual task run_phase(uvm_phase phase);
		forever begin
			if (status_vif.alm_empty) begin
				//  we haven't sampled the first value or alm_empty_thresh changed
				// had_alm_empty is 0 until the first alm_empty posedge
				// this way, the default value of prev_alm_empty_thresh will be the first value actually used
				if (!had_alm_empty || control_vif.alm_empty_thresh != prev_status_alm_empty_thresh) begin
					alm_empty_threshold_cg.sample(control_vif.alm_empty_thresh);
				end
				prev_status_alm_empty_thresh = control_vif.alm_empty_thresh;
			end

			if (status_vif.alm_full) begin
				// we haven't sampled the first value or alm_full_thresh changed
				// had_alm_full is 0 until the first alm_full posedge
				// this way, the default value of prev_alm_full_thresh will be the first value actually used
				if (!had_alm_full || control_vif.alm_full_thresh != prev_status_alm_full_thresh) begin
					alm_full_threshold_cg.sample(control_vif.alm_full_thresh);
				end
				prev_status_alm_full_thresh = control_vif.alm_full_thresh;
			end

			// sample empty, alm_empty values
			empty_cg.sample(status_vif.empty, status_vif.alm_empty);

			// sample full, alm_full values
			full_cg.sample(status_vif.full, status_vif.alm_full);

			// sample wr_en, rd_en
			wr_with_rd_cg.sample(block_vif.wr_en, block_vif.rd_en);

			// Reset the counters and flags
			if (!block_vif.rst_n) begin
				nof_back2back_wr = 0;
				nof_reads        = 0;
			end
			else begin
				// When write is detected, count it
				if (block_vif.wr_en) begin
					nof_back2back_wr = nof_back2back_wr + 1;
				end
				else begin
					// Sample the covergroup
					wr_en_back2back_with_simultaneous_reads_cg.sample(nof_back2back_wr, nof_reads);

					// Reset the counters
					nof_reads        = 0;
					nof_back2back_wr = 0;
				end
				// When read is detected, count it
				if (block_vif.rd_en) begin
					nof_reads = nof_reads + 1;
				end
			end

			if (!had_alm_full && block_vif.alm_full)
				had_alm_full = 1;
			if (!had_alm_empty && block_vif.alm_empty)
				had_alm_empty = 1;

			// both alm_full and alm_empty were active at least once during a simulation
			if (had_alm_empty && had_alm_full) begin
				if (block_vif.alm_empty || block_vif.alm_full) begin
					// the first values of the thresh haven't been sampled yet or one of the thresholds has changed
					if (!sampled_first_thresh_values || block_vif.alm_empty_thresh != prev_block_alm_empty_thresh || block_vif.alm_full_thresh != prev_block_alm_full_thresh) begin
						alm_empty_x_alm_full_thresholds_cg.sample(block_vif.alm_empty_thresh, block_vif.alm_full_thresh);
						// update the thresh values
						prev_block_alm_empty_thresh = control_vif.alm_empty_thresh;
						prev_block_alm_full_thresh = control_vif.alm_full_thresh;
						// mark the first sample
						if (!sampled_first_thresh_values)
							sampled_first_thresh_values = 1;
					end
				end
			end

			// sample overflow and fill level
			if (block_vif.wr_en) begin
				overflow_cg.sample((block_vif.full == 1));
				fill_level_status_on_write_cg.sample(block_vif.empty, block_vif.alm_empty, block_vif.alm_full, block_vif.full);
			end
			// sample underflow and fill level
			if (block_vif.rd_en) begin
				underflow_cg.sample((block_vif.empty == 1));
				fill_level_status_on_read_cg.sample(block_vif.empty, block_vif.alm_empty, block_vif.alm_full, block_vif.full);
			end
		

			@(posedge status_vif.clk);
		end
	endtask

	/*
	 * Coverage collector receives collected items from the monitor (sometimes it receives it from the scoreboard)
	 * the analysis port is the communication channel between the coverage collector and the monitor (or the scoreboard)
	 * every time an item is received this function is being called
	 * @param item - item received from the monitor
	 */
	function void write_in_port(amiq_fifo_write_item item);
	endfunction

	/*
	 * Coverage collector receives collected items from the monitor (sometimes it receives it from the scoreboard)
	 * the analysis port is the communication channel between the coverage collector and the monitor (or the scoreboard)
	 * every time an item is received this function is being called
	 * @param item - item received from the monitor
	 */
	function void write_out_port(amiq_fifo_read_item item);
	endfunction
endclass

`endif
