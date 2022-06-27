//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_READ_ENUM
`define AMIQ_FIFO_READ_ENUM

// Typedefs for the read agent
typedef enum {
	_0 = 0, _1_TO_10 = 1, _11_TO_50 = 2, _51_TO_MAX = 3
} distance_intervals_t;

`endif
