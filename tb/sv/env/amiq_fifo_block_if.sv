//----------------------------------------------------------------------
// Created by edaibr on Fri Feb 11 13:53:21 EET 2022
// Company name: amiq
// Project name: fifo
// Additional details:
// none
//----------------------------------------------------------------------

`ifndef AMIQ_FIFO_BLOCK_IF
`define AMIQ_FIFO_BLOCK_IF


/*
 * Interface for encapsulating the signals of a protocol
 * @param clk Clock signal
 * @param rst_n Reset signal - active low
 */
interface amiq_fifo_block_if#(parameter N = `N, parameter M = `M, parameter P = `P)(input logic clk, input logic rst_n);

	// Protocol signals

	/*
	 * Read enable
	 * The consumer asserts this control signal to indicate valid read data
	 */
	logic rd_en;
	/*
	 * Write enable
	 * The producer asserts this control signal to indicate valid write data
	 */
	logic wr_en;
	/*
	 * Data signal validated by the wr_en signal
	 * The data bus width is parameterizable within 1..N bits
	 */
	logic [(N-1):0] wr_data;
	/*
	 * It is used to configure how many spaces are necessary to be empty in order to have the alm_full signal asserted
	 */
	logic [(P-1):0] alm_full_thresh;
	/*
	 * It is used to configure how many spaces are necessary to be filled in order to have the alm_empty signal asserted
	 */
	logic [(P-1):0] alm_empty_thresh;
	/*
	 * It is used as a safety mechanism to avoid the writing of the entire FIFO memory
	 * It is asserted when the fill level of the FIFO is between FIFO_depth and FIFO_depth - alm_full_thresh
	 */
	logic alm_full;
	/*
	 * Status signal used to mark that all the FIFO positions are used and there is no free space for more data
	 */
	logic full;
	/*
	 * It is used as a safety mechanism to avoid the situation when the FIFO memory is almost empty
	 * It is asserted when the fill level of the FIFO is between empty and alm_empty_thresh
	 */
	logic alm_empty;
	/*
	 * Status signal used to mark the FIFO does not contain any valid data
	 */
	logic empty;
	/*
	 * Data signal validated by the rd_en signal
	 * The data bus width is parameterizable within 1..M bits
	 */
	logic [(M-1):0] rd_data;

	// enabler of interface checkers
	logic has_checks;
	// disable unknown data checks
	logic disable_unknown_data_check;

	// After reset, some signals should have expected values.
	property AMIQ_FIFO_VALUE_AFTER_RESET_PROPERTY(logic reset_signal);
		@(posedge clk) disable iff (!has_checks) $fell(reset_signal) |->
			empty === 1 && alm_empty === 1 && alm_full === 0 && full === 0;
	endproperty

	// Signal values after reset
	AMIQ_FIFO_RESET_VALUES_CHK: assert property(AMIQ_FIFO_VALUE_AFTER_RESET_PROPERTY(rst_n)) else
		$error("Wrong values after reset");

	// Flag used to enable/disable the unknown data check.
	bit check_x_on_output;

	always @(posedge clk)
	begin
		// wr_en and !full means we have a write request and we can write in the FIFO,
		// so raise the flag.
		if (wr_en && !full && check_x_on_output == 0)
			check_x_on_output <= 1;
	end

	property AMIQ_FIFO_CHECK_FOR_X_Z_VALUES_PROPERTY(logic signal);
		@(posedge clk) disable iff(!rst_n || !has_checks) !$isunknown(signal);
	endproperty

	property AMIQ_FIFO_CHECK_FOR_DATA_BUS_X_Z_VALUES_PROPERTY(logic control_signal, logic signal);
		disable iff (!rst_n || !has_checks || disable_unknown_data_check || !check_x_on_output) @(posedge clk) 
			control_signal |-> !$isunknown(signal);
	endproperty

	// If we have X on the input, it should not propagate to the output.
	AMIQ_FIFO_CHECK_RD_DATA_FOR_X_CHECK: assert property (AMIQ_FIFO_CHECK_FOR_DATA_BUS_X_Z_VALUES_PROPERTY(rd_en && !empty, rd_data)) else
		$error("Had X on rd_data");
	// empty should not be unknown
	AMIQ_FIFO_CHECK_EMPTY_FOR_X_CHECK: assert property (AMIQ_FIFO_CHECK_FOR_X_Z_VALUES_PROPERTY(empty)) else
		$error("Had X on empty");
	// alm_empty should not be unknown
	AMIQ_FIFO_CHECK_ALM_EMPTY_FOR_X_CHECK: assert property (AMIQ_FIFO_CHECK_FOR_X_Z_VALUES_PROPERTY(alm_empty)) else
		$error("Had X on alm_empty");
	// alm_full should not be unknown
	AMIQ_FIFO_CHECK_ALM_FULL_FOR_X_CHECK: assert property (AMIQ_FIFO_CHECK_FOR_X_Z_VALUES_PROPERTY(alm_full)) else
		$error("Had X on alm_full");
	// full should not be unknown
	AMIQ_FIFO_CHECK_FULL_FOR_X_CHECK: assert property (AMIQ_FIFO_CHECK_FOR_X_Z_VALUES_PROPERTY(full)) else
		$error("Had X on full");

	// number of bits in the FIFO
	bit [P + $clog2(M) : 0] fill;
	// maximum number of entries in the FIFO
	localparam FIFO_SIZE = 1 << P;
	// maximum number of bits in the FIFO, FIFO_SIZE entries of size M,
	// meaning maximum M reads
	localparam MEM_SIZE  = FIFO_SIZE * M;

	always @(posedge clk or negedge rst_n) begin
		// reset the fill on hard/soft reset
		if (!rst_n) begin
			fill <= 0;
		end
		else begin
			// if we have both a read and a write
			if (wr_en && rd_en) begin
				// If we can do both - not empty for read, check that we don't go over
				// the maximum for the write.
				if (!empty && !full) begin
					fill <= fill + N - M;
				end
				// If we can only do the write
				else if (empty && !full) begin
					fill <= fill + N;
				end
				// If we can only do the read
				else if (!empty) begin
					fill <= fill - M;
				end
			end
			// if we only have a write and the FIFO is not full, update the fill
			else if (wr_en && !rd_en && !full) begin
				fill <= fill + N;
			end
			// if we only have a read and the FIFO is not empty, update the fill
			else if (!wr_en && rd_en && !empty) begin
				fill <= fill - M;
			end
		end
	end

	property AMIQ_FIFO_EMPTY_ASSERTED_1_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks) empty |-> fill < M;
	endproperty
	property AMIQ_FIFO_EMPTY_ASSERTED_2_PROPERTY;
		 @(posedge clk) disable iff(!rst_n || !has_checks)fill < M |-> empty;
	endproperty
	property AMIQ_FIFO_ALM_EMPTY_ASSERTED_1_PROPERTY;
		@(posedge clk)disable iff(!rst_n || !has_checks) alm_empty |-> fill <= M * $past(alm_empty_thresh);
	endproperty
	property AMIQ_FIFO_ALM_EMPTY_ASSERTED_2_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks) fill <= M * $past(alm_empty_thresh) |-> alm_empty;
	endproperty
	property AMIQ_FIFO_ALM_FULL_ASSERTED_1_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks) alm_full |-> fill >= N * (FIFO_SIZE - $past(alm_full_thresh));
	endproperty
	property AMIQ_FIFO_ALM_FULL_ASSERTED_2_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks) fill >= N * (FIFO_SIZE - $past(alm_full_thresh)) |-> alm_full;
	endproperty
	property AMIQ_FIFO_FULL_ASSERTED_1_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks) full |-> fill + N > MEM_SIZE;
	endproperty
	property AMIQ_FIFO_FULL_ASSERTED_2_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks) fill + N > MEM_SIZE |-> full;
	endproperty
	property AMIQ_FIFO_NOT_FULL_AND_EMPTY_PROPERTY;
		@(posedge clk) disable iff(!rst_n || !has_checks || N > MEM_SIZE) !(full && empty);
	endproperty

	// If empty is asserted, we should have less than M bits of data left in the buffer, not enough for a
	// read. Cause for effect.
	AMIQ_FIFO_EMPTY_ASSERTED_1_CHECK: assert property (AMIQ_FIFO_EMPTY_ASSERTED_1_PROPERTY) else
		$error("empty was asserted, although we still had enough bits for another read");
	// If we have less than M bits of data left in the buffer, not enough for a read, empty should be asserted.
	// Effect for cause.
	AMIQ_FIFO_EMPTY_ASSERTED_2_CHECK: assert property (AMIQ_FIFO_EMPTY_ASSERTED_2_PROPERTY) else
		$error("Less than M bits available, but empty was not asserted");
	// If alm_empty is asserted, we have less entries than the current alm_empty threshold.
	// Cause for effect. We are using $past since the value of alm_empty was determined using the value available
	// last cycle, which could have changed this cycle.
	AMIQ_FIFO_ALM_EMPTY_ASSERTED_1_CHECK: assert property (AMIQ_FIFO_ALM_EMPTY_ASSERTED_1_PROPERTY) else
		$error("alm_empty was asserted, although the fill level was not at the threshold");
	// If we have less entries than the current alm_empty threshold, alm_empty should be asserted.
	// Effect for cause. We are using $past since the value of alm_empty was determined using the value available
	// last cycle, which could have changed this cycle.
	AMIQ_FIFO_ALM_EMPTY_ASSERTED_2_CHECK: assert property (AMIQ_FIFO_ALM_EMPTY_ASSERTED_2_PROPERTY) else
		$error("The fill level was at the threshold, but alm_empty was not asserted");
	// If alm_full is asserted, we have more entries than the current alm_full threshold.
	// Cause for effect. We are using $past since the value of alm_empty was determined using the value available
	// last cycle, which could have changed this cycle.
	AMIQ_FIFO_ALM_FULL_ASSERTED_1_CHECK: assert property (AMIQ_FIFO_ALM_FULL_ASSERTED_1_PROPERTY) else
		$error("alm_full was asserted, although the fill level was not at the threshold");
	// If we have more entries than the current alm_full threshold, alm_full should be asserted.
	// Effect for cause. We are using $past since the value of alm_empty was determined using the value available
	// last cycle, which could have changed this cycle.
	AMIQ_FIFO_ALM_FULL_ASSERTED_2_CHECK: assert property (AMIQ_FIFO_ALM_FULL_ASSERTED_2_PROPERTY) else
		$error("The fill level was at the threshold, but alm_full was not asserted");
	// If full is asserted, we should have less than N bits of space left in the buffer, not enough for a write.
	// Cause for effect.
	AMIQ_FIFO_FULL_ASSERTED_1_CHECK: assert property (AMIQ_FIFO_FULL_ASSERTED_1_PROPERTY) else
		$error("full was asserted, although we still had enough space for another write");
	// If we have less than N bits of space left in the buffer, not enough for a write, full should be asserted.
	// Effect for cause.
	AMIQ_FIFO_FULL_ASSERTED_2_CHECK: assert property (AMIQ_FIFO_FULL_ASSERTED_2_PROPERTY) else
		$error("Less than N bits of space available, but full was not asserted");
	// The FIFO must not be empty and full at the same time.
	AMIQ_FIFO_NOT_FULL_AND_EMPTY_CHECK: assert property (AMIQ_FIFO_NOT_FULL_AND_EMPTY_PROPERTY) else
		$error("FIFO is full and empty at the same time");

	`ifdef ABV_ON
	// an array to store the data from the writes on the FIFO,
	// in order to check if the output data matches what we expect
	bit [0 : MEM_SIZE - 1] mem;
	// the position where we start reading from
	bit [MEM_SIZE / M - 1 : 0] rdaddr;
	// the position where we start writing to
	bit [MEM_SIZE / N - 1 : 0] wraddr;
	// the expected value of the output
	bit [M - 1 : 0] expected_rd_data;

	always @(posedge clk or negedge rst_n) begin
		// only on hard reset, reset the memory
		if (!rst_n) begin
			for (int i = 0; i < MEM_SIZE; i++) begin
				mem[i] <= 0;
			end
		end
		// on soft and hard reset, reset the pointers
		if (!rst_n)
		begin
			rdaddr <= 0;
			wraddr <= 0;
		end
		else
		begin
			if (rd_en && !empty) begin
				rdaddr <= rdaddr + 1;
			end
			// if we have a write request, and the FIFO is not full or
			// we have a read request and the result of both operations
			// will not push the fill over the MEM_SIZE limit,
			// increment the write address and write N bits of data to
			// the memory, starting at wraddr * N.
			// since it's a circular buffer, the index used will
			// be kept in the interval [0, MEM_SIZE - 1]
			if (wr_en && !full) begin
				wraddr <= wraddr + 1;
				for (int i = 0; i < N; i++) begin
					mem[(i + wraddr * N) % MEM_SIZE] <= wr_data[N - 1 - i];
				end
			end
		end
	end

	// if we have a read request and the FIFO is not empty,
	// increment the read address and get M bits of data
	// from the memory, starting at rdaddr * M.
	// since it's a circular buffer, the index used
	// will be kept in the interval [0, MEM_SIZE - 1]
	genvar j;
	generate
		for (j = 0; j <= M - 1; j++) begin
			assign expected_rd_data[M - 1 - j] = (!rst_n) ? 0 : ((rd_en && !empty) ? mem[(j + rdaddr * M) % (MEM_SIZE)] : 0);
		end
	endgenerate

	// Any output should match its input.
	AMIQ_FIFO_EXPECTED_OUTPUT_CHECK: assert property (disable iff (!rst_n) @(posedge clk) rd_en && !empty |-> rd_data == expected_rd_data) else
		$error("Mismatched data: expected %x got %x", expected_rd_data, rd_data);

	// COVERAGE
	// Check that we can go from empty to almost empty to almost full to full to almost full to almost
	// empty back to empty.
	sequence EMPTY_TO_FULL_SEQ;
		empty ##[1:$] (alm_empty && !empty) ##[1:$] (alm_full && !full) ##[1:$] full;
	endsequence
	sequence FULL_TO_EMPTY_SEQ;
		full ##[1:$] (alm_full && !full) ##[1:$] (alm_empty && !empty) ##[1:$] empty;
	endsequence
	AMIQ_FIFO_EMPTY_TO_FULL_TO_EMPTY_COVER: cover property(@(posedge clk) disable iff(!rst_n) EMPTY_TO_FULL_SEQ ##0 FULL_TO_EMPTY_SEQ);
	// The FIFO is full, we read enough so it's no longer full, then we write until it's full again.
	AMIQ_FIFO_FULL_2_NOT_FULL_2_FULL: cover property(@(posedge clk) disable iff(!rst_n) full ##[1:$] !full ##[1:$] full);
	// The FIFO is empty, we write enough so it's not longer empty, then we read until it's empty again.
	AMIQ_FIFO_EMPTY_2_NOT_EMPTY_2_EMPTY: cover property(@(posedge clk) disable iff(!rst_n) empty ##[1:$] !empty ##[1:$] empty);
	// Write when FIFO is full - overflow
	AMIQ_FIFO_WRITE_FULL: cover property (disable iff (!rst_n) @(posedge clk) full && wr_en);
	// Read when FIFO is empty - underflow
	AMIQ_FIFO_READ_EMPTY: cover property ( disable iff (!rst_n) @(posedge clk) empty && rd_en);
	// Write data is not constant
	AMIQ_FIFO_WRITE_DATA_CAN_CHANGE_VALUE: cover property (disable iff(!rst_n) @(posedge clk) wr_data != $past(wr_data));
	// Read data is not constant
	AMIQ_FIFO_READ_DATA_CAN_CHANGE_VALUE: cover property (disable iff(!rst_n) @(posedge clk) rd_data != $past(rd_data));
	// Hard reset when FIFO is full.
	AMIQ_FIFO_RESET_WHEN_FULL: cover property (@(posedge clk) full && rst_n |=> !rst_n);
	// Hard reset when FIFO is empty.
	AMIQ_FIFO_RESET_WHEN_EMPTY: cover property (@(posedge clk) empty && rst_n |=> !rst_n);
	// Hard reset when FIFO is almost full.
	AMIQ_FIFO_RESET_WHEN_ALM_FULL: cover property (@(posedge clk) alm_full && rst_n |=> !rst_n);
	// Hard reset when FIFO is almost empty.
	AMIQ_FIFO_RESET_WHEN_ALM_EMPTY: cover property (@(posedge clk) alm_empty && rst_n |=> !rst_n);
	// Almost full is asserted while the FIFO is not full.
	AMIQ_FIFO_ALM_FULL_NOT_FULL: cover property (@(posedge clk) alm_full && !full);
	// Almost empty is asserted while the FIFO is not empty.
	AMIQ_FIFO_ALM_EMPTY_NOT_EMPTY: cover property (@(posedge clk) alm_empty && !empty);
	// Sanity cover that we had at least one read that returned data.
	AMIQ_FIFO_OUTPUT_FOR_INPUT: cover property (@(posedge clk) rd_en && !empty |=> rd_data == expected_rd_data);
	// Property for the value of wr_data.
	property WR_DATA_VALUE_PROPERTY(min, max);
		@(posedge clk) wr_en && wr_data inside {[min: max]};
	endproperty
	// Minimum value for wr_data, 0.
	AMIQ_FIFO_WR_DATA_MIN_VAL_COV: cover property(WR_DATA_VALUE_PROPERTY(0, 0));
	// Maximum value for wr_data, 2 ^ N - 1.
	AMIQ_FIFO_WR_DATA_MAX_VAL_COV: cover property(WR_DATA_VALUE_PROPERTY(((1 << N) - 1), ((1 << N) - 1)));
	// Regular value for write data, between 1 and 2 ^ N - 2. Can't split into intervals in formal.
	AMIQ_FIFO_WR_DATA_REGULAR_VAL_COV: cover property (WR_DATA_VALUE_PROPERTY(1, ((1 << N) - 2)));
	// Property for the number of cycles between two assertions of the same signal(wr_en or rd_en).
	property NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(min, max, signal);
		@(posedge clk) disable iff(!rst_n) signal ##1 !signal[*min:max] ##1 signal;
	endproperty
	// Two writes in a row.
	AMIQ_FIFO_NO_DELAY_BETWEEN_WRITES_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(0, 0, wr_en));
	// Delay of 1 to 10 cycles between two writes.
	AMIQ_FIFO_1_TO_10_CYCLES_BETWEEN_WRITES_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(1, 10, wr_en));
	// Delay of 11 to 50 cycles between two writes.
	AMIQ_FIFO_11_TO_50_CYCLES_BETWEEN_WRITES_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(11, 50, wr_en));
	// Delay of over 50 cycles between two writes.
	AMIQ_FIFO_OVER_50_CYCLES_BETWEEN_WRITES_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(51, $, wr_en));
	// Property for the number of cycles a signal(wr_en or rd_en) is asserted in a row.
	property NOF_TRANSACTIONS_IN_A_ROW_PROPERTY(min, max, signal);
		@(posedge clk) disable iff(!rst_n) signal[*min: max] ##1 !signal;
	endproperty
	// Two writes in a row already covered in NO_DELAY_BETWEEN_WRITES_COV.
	// Starting from an empty FIFO, we need FIFO_SIZE * M / N writes in a row, without any reads, to fill the FIFO.
	AMIQ_FIFO_FULL_WRITES_IN_A_ROW_COV: cover property (NOF_TRANSACTIONS_IN_A_ROW_PROPERTY((FIFO_SIZE * M / N), (FIFO_SIZE * M / N), wr_en));
	// Between 3 and maximum - 1 writes in a row..
	AMIQ_FIFO_3_TO_FULL_MINUS_1_WRITES_IN_A_ROW_COV: cover property (NOF_TRANSACTIONS_IN_A_ROW_PROPERTY(3, (FIFO_SIZE * M / N - 1), wr_en));
	// Property for the value of rd_data.
	property RD_DATA_VALUE_PROPERTY(min, max);
		@(posedge clk) rd_en && !empty |=> rd_data inside {[min: max]};
	endproperty
	// Minimum value for rd_data, 0.
	AMIQ_FIFO_RD_DATA_MIN_VAL_COV: cover property(RD_DATA_VALUE_PROPERTY(0, 0));
	// Maximum value for rd_data, 2 ^ N - 1.
	AMIQ_FIFO_RD_DATA_MAX_VAL_COV: cover property(RD_DATA_VALUE_PROPERTY(((1 << N) - 1), ((1 << N) - 1)));
	// Regular value for read data, between 1 and 2 ^ N - 2. Can't split into intervals in formal.
	AMIQ_FIFO_RD_DATA_REGULAR_VAL_COV: cover property (RD_DATA_VALUE_PROPERTY(1, ((1 << N) - 2)));
	// Two reads in a row.
	AMIQ_FIFO_NO_DELAY_BETWEEN_READS_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(0, 0, rd_en));
	// Delay of 1 to 10 cycles between two reads.
	AMIQ_FIFO_1_TO_10_CYCLES_BETWEEN_READS_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(1, 10, rd_en));
	// Delay of 11 to 50 cycles between two reads.
	AMIQ_FIFO_11_TO_50_CYCLES_BETWEEN_READS_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(11, 50, rd_en));
	// Delay of over 50 cycles between two reads.
	AMIQ_FIFO_OVER_50_CYCLES_BETWEEN_READS_COV: cover property (NOF_CYCLES_BETWEEN_TRANSACTIONS_PROPERTY(51, $, rd_en));
	// Two writes in a row already covered in NO_DELAY_BETWEEN_WRITES_COV.
	// Starting from an empty FIFO, we need FIFO_SIZE * M / N writes in a row, without any reads, to fill the FIFO.
	AMIQ_FIFO_FULL_READS_IN_A_ROW_COV: cover property (NOF_TRANSACTIONS_IN_A_ROW_PROPERTY((FIFO_SIZE * M / N), (FIFO_SIZE * M / N), rd_en));
	// Between 3 and maximum - 1 writes in a row.
	AMIQ_FIFO_3_TO_FULL_MINUS_1_READS_IN_A_ROW_COV: cover property (NOF_TRANSACTIONS_IN_A_ROW_PROPERTY(3, (FIFO_SIZE * M / N - 1), rd_en));
	// Property for checking the value of a threshold when the corresponding status signal is asserted.
	property THRESHOLD_VALUE_PROPERTY(min, max, signal, thresh_signal);
		disable iff (clear || !rst_n) @(posedge clk) signal && $past(thresh_signal) inside {[min: max]};
	endproperty
	// alm_empty asserted for alm_empty_thresh 0.
	AMIQ_FIFO_MIN_VAL_ALM_EMPTY_THRESH_COV: cover property (THRESHOLD_VALUE_PROPERTY(0, 0, alm_empty, alm_empty_thresh));
	// alm_empty asserted for alm_empty_thresh 2 ^ P - 1.
	AMIQ_FIFO_MAX_VAL_ALM_EMPTY_THRESH_COV: cover property (THRESHOLD_VALUE_PROPERTY(((1 << P) - 1), ((1 << P) - 1), alm_empty, alm_empty_thresh));
	// alm_empty asserted for alm_empty_thresh between 1 and 2 ^ P - 2. Can't split into intervals in formal.
	AMIQ_FIFO_REGULAR_VAL_ALM_EMPTY_THRESH_COV: cover property (THRESHOLD_VALUE_PROPERTY(1, ((1 << P) - 2), alm_empty, alm_empty_thresh));
	// alm_full asserted for alm_full_thresh 0
	AMIQ_FIFO_MIN_VAL_ALM_FULL_THRESH_COV: cover property (THRESHOLD_VALUE_PROPERTY(0, 0, alm_full, alm_full_thresh));
	// alm_full asserted for alm_full_thresh 2 ^ P - 1
	AMIQ_FIFO_MAX_VAL_ALM_FULL_THRESH_COV: cover property (THRESHOLD_VALUE_PROPERTY(((1 << P) - 1), ((1 << P) - 1), alm_full, alm_full_thresh));
	// alm_full asserted for alm_full_thresh between 1 and 2 ^ P - 2. Can't split into intervals in formal.
	AMIQ_FIFO_REGULAR_VAL_ALM_FULL_THRESH_COV: cover property (THRESHOLD_VALUE_PROPERTY(1, ((1 << P) - 2), alm_full, alm_full_thresh));
	// Property for different values of signals or combination of signals.
	property SIGNAL_VAL_PROPERTY(signal);
		disable iff (!rst_n) @(posedge clk) signal;
	endproperty
	// Coverage that empty is asserted.
	AMIQ_FIFO_EMPTY_COV: cover property (SIGNAL_VAL_PROPERTY(empty));
	// Coverage that empty is deasserted.
	AMIQ_FIFO_NOT_EMPTY_COV: cover property (SIGNAL_VAL_PROPERTY(!empty));
	// Coverage that alm_empty is asserted.
	AMIQ_FIFO_ALM_EMPTY_COV: cover property (SIGNAL_VAL_PROPERTY(alm_empty));
	// Coverage that alm_empty is deasserted.
	AMIQ_FIFO_NOT_ALM_EMPTY_COV: cover property (SIGNAL_VAL_PROPERTY(!alm_empty));
	// Coverage that full is asserted.
	AMIQ_FIFO_FULL_COV: cover property (SIGNAL_VAL_PROPERTY(full));
	// Coverage that full is deasserted.
	AMIQ_FIFO_NOT_FULL_COV: cover property (SIGNAL_VAL_PROPERTY(!full));
	// Coverage that alm_full is asserted.
	AMIQ_FIFO_ALM_FULL_COV: cover property (SIGNAL_VAL_PROPERTY(alm_full));
	// Coverage that alm_full is deasserted.
	AMIQ_FIFO_NOT_ALM_FULL_COV: cover property (SIGNAL_VAL_PROPERTY(!alm_full));
	// Coverage that wr_en is asserted.
	AMIQ_FIFO_WRITE_COV: cover property (SIGNAL_VAL_PROPERTY(wr_en));
	// Coverage that wr_en is deasserted.
	AMIQ_FIFO_NOT_WRITE_COV: cover property (SIGNAL_VAL_PROPERTY(!wr_en));
	// Coverage that rd_en is asserted.
	AMIQ_FIFO_READ_COV: cover property (SIGNAL_VAL_PROPERTY(rd_en));
	// Coverage that rd_en is deasserted.
	AMIQ_FIFO_NOT_READ_COV: cover property (SIGNAL_VAL_PROPERTY(!rd_en));
	// Read and write at the same time.
	AMIQ_FIFO_WRITE_READ_COV: cover property (SIGNAL_VAL_PROPERTY(wr_en && rd_en));
	// Write no read.
	AMIQ_FIFO_WRITE_NOT_READ_COV: cover property (SIGNAL_VAL_PROPERTY(wr_en && !rd_en));
	// Read no write.
	AMIQ_FIFO_NOT_WRITE_READ_COV: cover property (SIGNAL_VAL_PROPERTY(!wr_en && rd_en));
	// Idle cycle, no write no read.
	AMIQ_FIFO_NOT_WRITE_NOT_READ_COV: cover property (SIGNAL_VAL_PROPERTY(!wr_en && !rd_en));

	/*
	 * Auxiliary code for coverage on 5 back-to-back writes and 3 (not necessarily back-to-back) reads
	 * Cannot implement the same coverage as simulation because of formal limitations
	 * Can be scaled by using a flag array, additional if-branches and one more cover per scenario
	 */

	// Back-to-back writes counter
	int nof_back2back_wr;
	// Reads counter
	int nof_reads;
	// Flag for triggering the coverage
	bit trigger_coverage;

	always @(posedge clk or negedge rst_n) begin
		// Reset the counters and flags
		if (!rst_n) begin
			nof_back2back_wr <= 0;
			nof_reads        <= 0;
			trigger_coverage <= 0;
		end
		else begin
			// Flag should only be asserted for one clock cycle
			if (trigger_coverage == 1) begin
				trigger_coverage <= 0;
			end
			// When write is detected, count it
			if (wr_en) begin
				nof_back2back_wr <= nof_back2back_wr + 1;
			end
			else begin
				// When we get the scenario we wanted, trigger the coverage
				if (nof_back2back_wr == 5 && nof_reads == 3) begin
					trigger_coverage <= 1;
				end
				// Reset the counters
				nof_reads        <= 0;
				nof_back2back_wr <= 0;
			end
			// When read is detected, count it
			if (rd_en) begin
				nof_reads <= nof_reads + 1;
			end
		end
	end
	// Can have 5 writes in a row and, in parallel, 3 reads, not necessarily in a row.
	AMIQ_FIFO_5_WRITE_B2B_3_READS_COV: cover property (@(posedge clk) disable iff(!rst_n) trigger_coverage);

	`endif

endinterface

`endif
