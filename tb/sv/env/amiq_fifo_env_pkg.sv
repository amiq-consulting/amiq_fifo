//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_ENV_PKG
`define AMIQ_FIFO_ENV_PKG

/*
 * Package for encapsulating components of the environment
 * Includes or imports all associated files and the UVM package
 */
package  amiq_fifo_env_pkg;
  // UVM macros need to be included while UVM types need to be imported
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  
  // import the agent packages
  import amiq_fifo_write_agent_pkg::*;
  import amiq_fifo_read_agent_pkg::*;
  
  `include "amiq_fifo_custom_reporter.svh"
  `include "amiq_fifo_defines.svh"
  `include "amiq_fifo_env_config_obj.svh"
  `include "amiq_fifo_scoreboard.svh"
  `include "amiq_fifo_env_coverage_collector.svh"
  `include "amiq_fifo_virtual_sequencer.svh"
  `include "amiq_fifo_virtual_sequence_lib.svh"
  `include "amiq_fifo_env.svh"

endpackage

`endif
