//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_VIRTUAL_SEQUENCE
`define AMIQ_FIFO_VIRTUAL_SEQUENCE

/*
 * Base virtual sequence. All virtual sequences should inherit this one
 */
class amiq_fifo_base_vseq extends uvm_sequence;
	`uvm_object_utils(amiq_fifo_base_vseq)

	/*
	 * Constructor for the virtual sequence
	 * @see uvm_pkg::uvm_object.new
	 * @param name -
	 */
	function new(string name = "amiq_fifo_base_vseq");
		super.new(name);
	endfunction

	/*
	 * Task to take actions before starting the main code of the current sequence
	 * e.g. raising objections for easier handling of the end of test
	 * @see uvm_pkg::uvm_sequence_base.pre_body
	 */
	virtual task pre_body();
		// add an objection for the end of test mechanism
		uvm_test_done.raise_objection();
	endtask

	/*
	 * Task to take actions after finishing the main code of the current sequence
	 * e.g. dropping objections for easier handling of the end of test
	 * @see uvm_pkg::uvm_sequence_base.post_body
	 */
	virtual task post_body();
		// remove the objection from the end of test mechanism
		uvm_test_done.drop_objection();
	endtask
endclass

/*
 * Example of a virtual sequence
 */
class amiq_fifo_virtual_sequence extends amiq_fifo_base_vseq;
	`uvm_object_utils(amiq_fifo_virtual_sequence)

	// bind this sequence to the virtual sequencer by declaring it as a parent sequencer
	`uvm_declare_p_sequencer(amiq_fifo_virtual_sequencer)

	// sequence for the write agent
	amiq_fifo_write_sequence write_seq;

	// parameter to indicate how many in sequences to run
	rand int unsigned nr_of_write_sequences;

	// constraint the number of sequences for write agent
	constraint nr_of_write_sequences_c {
		soft nr_of_write_sequences == 1000;
	}

	// sequence for the read agent
	amiq_fifo_read_sequence read_seq;

	// parameter to indicate how many in sequences to run
	rand int unsigned nr_of_read_sequences;

	// constraint the number of sequences for write agent
	constraint nr_of_read_sequences_c {
		soft nr_of_read_sequences == 1000;
	}


	/*
	 * Constructor for the virtual sequence
	 * @see uvm_pkg::uvm_object.new
	 */
	function new(string name = "amiq_fifo_virtual_sequence");
		super.new(name);
	endfunction

	/*
	 * The scenario of the sequence is described here in the body task
	 * @see uvm_pkg::uvm_sequence_base.body
	 */
	virtual task body();

		// start sequences in parallel for the read and write agents
		fork
			begin
				for(int i = 0; i < nr_of_write_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started write sequence %0d/%0d",i,nr_of_write_sequences), UVM_LOW)
					`uvm_do_on(write_seq, p_sequencer.write_sequencer);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished write sequence %0d/%0d",i,nr_of_write_sequences), UVM_LOW)
				end
			end

			begin
				for(int i = 0; i < nr_of_read_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started read sequence %0d/%0d",i,nr_of_read_sequences), UVM_LOW)
					`uvm_do_on(read_seq, p_sequencer.read_sequencer);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished read sequence %0d/%0d",i,nr_of_read_sequences), UVM_LOW)
				end
			end
		join
	endtask
endclass

class amiq_fifo_multiple_reset_virtual_sequence extends amiq_fifo_virtual_sequence;
	`uvm_object_utils(amiq_fifo_multiple_reset_virtual_sequence)

	// bind this sequence to the virtual sequencer by declaring it as a parent sequencer
	`uvm_declare_p_sequencer(amiq_fifo_virtual_sequencer)

	// parameter to indicate how many reset sequences to run
	rand int unsigned nr_of_reset_sequences;

	// constraint the number of sequences for write agent
	constraint reset_sequence_c {
		soft nr_of_reset_sequences == 20;
	}

	/*
	 * Constructor for the virtual sequence
	 * @see uvm_pkg::uvm_object.new
	 */
	function new(string name = "amiq_fifo_multiple_reset_virtual_sequence");
		super.new(name);
	endfunction

	/*
	 * The scenario of the sequence is described here in the body task
	 * @see uvm_pkg::uvm_sequence_base.body
	 */
	virtual task body();

		// start sequences in parallel for the read and write agents
		fork
			begin
				for(int i = 0; i < nr_of_write_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started write sequence %0d/%0d",i,nr_of_write_sequences), UVM_LOW)
					`uvm_do_on(write_seq, p_sequencer.write_sequencer);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished write sequence %0d/%0d",i,nr_of_write_sequences), UVM_LOW)
				end
			end

			begin
				for(int i = 0; i < nr_of_read_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started read sequence %0d/%0d",i,nr_of_read_sequences), UVM_LOW)
					`uvm_do_on(read_seq, p_sequencer.read_sequencer);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished read sequence %0d/%0d",i,nr_of_read_sequences), UVM_LOW)
				end
			end
			// reset sequence
			begin
				// delay between resets
				int unsigned reset_delay;
				// number of CC in which reset is active
				int unsigned reset_duration;

				for(int i = 0; i < nr_of_reset_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started reset sequence %0d/%0d",i,nr_of_reset_sequences), UVM_LOW)
					reset_delay = $urandom_range(1, 300);
					reset_duration = $urandom_range(1, 10);
					p_sequencer.drive_reset(reset_delay, reset_duration);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished reset sequence %0d/%0d",i,nr_of_reset_sequences), UVM_LOW)
				end
			end
		join
	endtask
endclass

class amiq_fifo_set_thresh_virtual_sequence extends amiq_fifo_virtual_sequence;
	`uvm_object_utils(amiq_fifo_set_thresh_virtual_sequence)

	// bind this sequence to the virtual sequencer by declaring it as a parent sequencer
	`uvm_declare_p_sequencer(amiq_fifo_virtual_sequencer)

	// parameter to indicate how many reset sequences to run
	rand int unsigned nr_of_set_thresh_sequences;

	// constraint the number of sequences for write agent
	constraint nr_of_set_thresh_sequences_c {
		soft nr_of_set_thresh_sequences == 20;
	}

	/*
	 * Constructor for the virtual sequence
	 * @see uvm_pkg::uvm_object.new
	 */
	function new(string name = "amiq_fifo_set_thresh_virtual_sequence");
		super.new(name);
	endfunction

	/*
	 * The scenario of the sequence is described here in the body task
	 * @see uvm_pkg::uvm_sequence_base.body
	 */
	virtual task body();

		// start sequences in parallel for the read and write agents
		fork
			begin
				for(int i = 0; i < nr_of_write_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started write sequence %0d/%0d",i,nr_of_write_sequences), UVM_LOW)
					`uvm_do_on(write_seq, p_sequencer.write_sequencer);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished write sequence %0d/%0d",i,nr_of_write_sequences), UVM_LOW)
				end
			end

			begin
				for(int i = 0; i < nr_of_read_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started read sequence %0d/%0d",i,nr_of_read_sequences), UVM_LOW)
					`uvm_do_on(read_seq, p_sequencer.read_sequencer);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished read sequence %0d/%0d",i,nr_of_read_sequences), UVM_LOW)
				end
			end
			// reset sequence
			begin
				// delay before setting the values
				int unsigned delay;
				bit [(P-1):0] alm_full_thresh;
				bit [(P-1):0] alm_empty_thresh;

				for(int i = 0; i < nr_of_set_thresh_sequences; i++) begin
					`uvm_info("SEQUENCES STARTING", $sformatf("Started set_thresh sequence %0d/%0d",i,nr_of_set_thresh_sequences), UVM_LOW)
					delay = $urandom_range(1, 300);
					alm_full_thresh = $urandom_range(0, 1 << P);
					alm_empty_thresh = $urandom_range(0, 1 << P);
					p_sequencer.set_thresh(alm_full_thresh, alm_empty_thresh, delay);
					`uvm_info("SEQUENCES FINISHED", $sformatf("Finished set_thresh sequence %0d/%0d",i,nr_of_set_thresh_sequences), UVM_LOW)
				end
			end
		join
	endtask
endclass

`endif
