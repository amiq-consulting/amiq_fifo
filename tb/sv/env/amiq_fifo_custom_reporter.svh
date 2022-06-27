//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifdef UVM_VERSION_1_2
  `include "custom_reporter/amiq_fifo_custom_reporter_uvm_1_2.svh"
 `else
  `include "custom_reporter/amiq_fifo_custom_reporter_uvm_1_1.svh"
`endif
