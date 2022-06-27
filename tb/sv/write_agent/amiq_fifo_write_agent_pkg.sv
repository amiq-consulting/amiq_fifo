//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_AGENT_PKG
`define AMIQ_FIFO_WRITE_AGENT_PKG

/*
 * Package for encapsulating components of the agent
 * Includes or imports all associated files and the UVM package
 */
package amiq_fifo_write_agent_pkg;
  // UVM macros need to be included while UVM types need to be imported
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  `include "amiq_fifo_write_defines.svh"
  `include "amiq_fifo_write_types.svh"
  `include "amiq_fifo_write_config_obj.svh"
  `include "amiq_fifo_write_item.svh"
  `include "amiq_fifo_write_sequencer.svh"
  `include "amiq_fifo_write_seq.svh"
  `include "amiq_fifo_write_driver.svh"
  `include "amiq_fifo_write_monitor.svh"
  `include "amiq_fifo_write_coverage_collector.svh"
  `include "amiq_fifo_write_agent.svh"

endpackage

`endif 
