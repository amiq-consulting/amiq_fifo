//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_TB_TOP
`define AMIQ_FIFO_TB_TOP

/*
 * Top level module where DUT and interfaces are instantiated
 */
module amiq_fifo_tb_top;
  // UVM macros need to be included while UVM types need to be imported
  `include "uvm_macros.svh"
	import uvm_pkg::*;

	// import the test package
	import amiq_fifo_test_pkg::*;

	logic clk;

	// control interface instance
	amiq_fifo_control_if fifo_control_if(.clk(clk));
	// write interface instance
	amiq_fifo_write_if fifo_write_if(.clk(clk), .rst_n(fifo_control_if.rst_n));
	// read interface instance
	amiq_fifo_read_if fifo_read_if(.clk(clk), .rst_n(fifo_control_if.rst_n));
	// status interface instance
	amiq_fifo_status_if fifo_status_if(.clk(clk), .rst_n(fifo_control_if.rst_n));

	// DUT instantiation
	amiq_fifo DUT(
		.clk(clk),
		.rst_n(fifo_control_if.rst_n),
		.rd_en(fifo_read_if.rd_en),
		.wr_en(fifo_write_if.wr_en),
		.wr_data(fifo_write_if.wr_data),
		.alm_full_thresh(fifo_control_if.alm_full_thresh),
		.alm_empty_thresh(fifo_control_if.alm_empty_thresh),
		.alm_full(fifo_status_if.alm_full),
		.full(fifo_status_if.full),
		.alm_empty(fifo_status_if.alm_empty),
		.empty(fifo_status_if.empty),
		.rd_data(fifo_read_if.rd_data)
	);

	// block interface instance
	amiq_fifo_block_if block_if(.clk(clk), .rst_n(fifo_control_if.rst_n));
	// assign signals to block interface
	assign block_if.rd_en = DUT.rd_en;
	assign block_if.wr_en = DUT.wr_en;
	assign block_if.wr_data = DUT.wr_data;
	assign block_if.alm_full_thresh = DUT.alm_full_thresh;
	assign block_if.alm_empty_thresh = DUT.alm_empty_thresh;
	assign block_if.alm_full = DUT.alm_full;
	assign block_if.full = DUT.full;
	assign block_if.alm_empty = DUT.alm_empty;
	assign block_if.empty = DUT.empty;
	assign block_if.rd_data = DUT.rd_data;

	initial begin

		// Propagate the interface to all the components that need them
		uvm_config_db#(virtual amiq_fifo_write_if)::set(null, "uvm_test_top.env.*", "fifo_write_vif", fifo_write_if);
		uvm_config_db#(virtual amiq_fifo_read_if)::set(null, "uvm_test_top.env.*", "fifo_read_vif", fifo_read_if);
		uvm_config_db#(virtual amiq_fifo_status_if)::set(null, "uvm_test_top.env.*", "fifo_status_vif", fifo_status_if);
		uvm_config_db#(virtual amiq_fifo_control_if)::set(null, "uvm_test_top.*", "fifo_control_vif", fifo_control_if);
		uvm_config_db#(virtual amiq_fifo_block_if)::set(null, "uvm_test_top.*", "fifo_block_vif", block_if);

		// Instantiate the test given on command line and start all the phases of the test (build, connect, run, etc.)
		run_test();
	end

	initial begin
		// initialize clock and reset signals
		clk=0;
		fifo_control_if.rst_n=1;
		// initialize thresh values
		fifo_control_if.alm_empty_thresh = 2;
		fifo_control_if.alm_full_thresh = 2;

		// reset generator
		#1 fifo_control_if.rst_n=0;
		#20 fifo_control_if.rst_n=1;
	end

	// clock generator
	always #5 clk=~clk;

endmodule

`endif
