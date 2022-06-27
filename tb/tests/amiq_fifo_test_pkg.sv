//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_TEST_PKG
`define AMIQ_FIFO_TEST_PKG

/*
 * Package for encapsulating components used by the tests
 * Includes or imports all associated files and the UVM package
 */
package amiq_fifo_test_pkg;
	// UVM macros need to be included while UVM types need to be imported
	`include "uvm_macros.svh"
	import uvm_pkg::*;

	import amiq_fifo_write_agent_pkg::*;
	import amiq_fifo_read_agent_pkg::*;
	import amiq_fifo_env_pkg::*;

	`include "amiq_fifo_base_test.svh"
	`include "amiq_fifo_random_test.svh"
	`include "amiq_fifo_multiple_reset_test.svh"
	`include "amiq_fifo_set_thresh_test.svh"
endpackage

`endif
