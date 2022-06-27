//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_ENUM
`define AMIQ_FIFO_WRITE_ENUM

// Typedefs for the write agent
typedef enum {
	_2 = 2**1, _4 = 2**2, _8 = 2**3, _16 = 2**4, _32 = 2**5, _64 = 2**6, _128 = 2**7, _256 = 2**8, _512 = 2**9, _1024 = 2**10,
	_2048 = 2**11, _4096 = 2**12, _8192 = 2**13, _16384 = 2**14, _32768 = 2**15, _65536 = 2**16
} alm_thresh_val_t;

typedef alm_thresh_val_t lof_alm_thresh_val[$];

typedef enum {
	_0 = 0, _1_TO_10 = 1, _11_TO_50 = 2, _51_TO_MAX = 3
} distance_intervals_t;

`endif
