//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_WRITE_ITEM
`define AMIQ_FIFO_WRITE_ITEM

/*
 * Class for encapsulating protocol item information
 * specific fields/properties
 * field constraints
 * utility functions
 */
class amiq_fifo_write_item extends uvm_sequence_item;

	// data value
	rand bit [(N-1):0] wr_data;

	// transfer delay
	rand int unsigned transfer_delay;

	// Constraints

	// constraint transfer delay
	constraint data_c {
		soft transfer_delay <= 5;
	}

	`uvm_object_utils_begin(amiq_fifo_write_item)
		// Register fields
		`uvm_field_int(wr_data, UVM_DEFAULT)
		`uvm_field_int(transfer_delay, UVM_DEFAULT)
	`uvm_object_utils_end

	/*
	 * Constructor of the item class
	 * @see uvm_pkg::uvm_sequence_item.new
	 * @param name -
	 * @param parent -
	 */
	function new (string name = "amiq_fifo_write_item");
		super.new(name);
	endfunction

	/*
	 * Utility function for converting item information/fields into a string
	 * @return string representation of the item
	 */
	virtual function string convert2string();
		convert2string = $sformatf("%sdata = %0d\t", convert2string, wr_data);
	endfunction
endclass

`endif
