module amiq_fifo
	#(
		parameter N = `N,
		parameter M = `M,
		parameter P = `P)
	(
		input clk,
		input rst_n,
		input rd_en,
		input wr_en,
		input [(N-1):0] wr_data,
		input [(P-1):0] alm_full_thresh,
		input [(P-1):0] alm_empty_thresh,

		output reg alm_full,
		output reg full,
		output reg alm_empty,
		output reg empty,
		output reg [(M-1):0] rd_data
	);

	// The maximum number of elements in the FIFO
	localparam FIFO_SIZE = 1 << P;
	localparam MEM_SIZE  = FIFO_SIZE * M;
	// The write address, where new data will be stored
	reg [(MEM_SIZE / N) -1 : 0] wraddr;
	// The read address, indicating the location of the requested data
	reg [(MEM_SIZE / M) -1 : 0] rdaddr;
	// The FIFO memory
	reg [0 : MEM_SIZE - 1] mem;
	// The number of elements in the FIFO
	// Since M and N can differ, we want to account for us reading just
	// parts of a previous write or writing parts of a future read.
	// The size of the memory is calculated relative to M, the size
	// of the output, so everything we calculate will be done multiplying
	// by M. For example, after a read, we consider that we read M,
	// and after a write, we consider that we added N (instead of N / M).
	// In order to account for this, to the P bits we added enough to store
	// the product of 2 ^ P * M, which would be P + log2(M) + 1.
	bit [P + $clog2(M) : 0] fill;

	always @(posedge clk or negedge rst_n) begin
		// on hard reset, reset the memory
		if (!rst_n) begin
			for (int i = 0; i < MEM_SIZE; i++) begin
				mem[i] <= 0;
			end
		end
		// if we have a write request and the FIFO is not full, or
		// we have a read and doing both the read and the write do not
		// push the fill over the MEM_SIZE limit
		if (!(!rst_n)) begin
			if (wr_en && !full) begin
				for (int i = 0; i <= N - 1; i++) begin
					mem[(i + wraddr * N) % (MEM_SIZE)] <= wr_data[N - 1 - i];
				end
			end
		end
	end

	genvar j;
	generate
		for (j = 0; j <= M - 1; j++) begin
			assign rd_data[M - 1 - j] = (!rst_n) ? rd_data[M - 1 - j] : ((rd_en && !empty) ? mem[(j + rdaddr * M) % (MEM_SIZE)] : 'x);
		end
	endgenerate

	always @(posedge clk or negedge rst_n) begin
		// reset the write address for a soft/hard reset
		if (!rst_n) begin
			wraddr   <= 0;
		end
		else if (wr_en) begin
			// if we have a write request and the FIFO is not full, or
			// we have a read and doing both the read and the write do not
			// push the fill over the MEM_SIZE limit
			if (!full)
				wraddr <= (wraddr + 1'b1);
		end
	end

	always @(posedge clk or negedge rst_n) begin
		// reset the read address for a soft/hard reset
		if (!rst_n) begin
			rdaddr   <= 0;
		end
		else if (rd_en) begin
			// if we have a read request and the FIFO is not empty
			if (!empty)
				rdaddr <= rdaddr + 1'b1;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		// reset the flags for a soft/hard reset
		if (!rst_n) begin
			full  <= 1'b0;
			empty <= 1'b1;
		end
		else begin
			casez({ wr_en, rd_en, !full, !empty })
				4'b01?1: begin  // A successful read
					// The FIFO is full if, after we read M bits, we can't write
					// N more bits in the buffer.
					full  <= (fill - M + N > MEM_SIZE);
					// The FIFO is empty if, after this read of M bits, we will have
					//less than M bits of data left in the buffer.
					empty <= (fill - M < M);
				end
				4'b101?: begin  // A successful write
					// The FIFO is full if, after we write N bits, we have less
					// than N bits of space left in the buffer, so writing another
					// N bits would go over the maximum size.
					full  <= (fill + N + N > MEM_SIZE);
					empty <= (fill + N < M);
				end
				4'b11??: begin // Read and write
					// We can do both
					if (!empty && !full) begin
						// The FIFO is full if, after we read M bits and write N, we have
						// less than N bits of space left in the buffer, so writing another
						//  N bits would go over the maximum size.
						full      <= (fill - M + N + N > MEM_SIZE);
						// The FIFO is empty if, after we read M bits and write N, we have
						// less than M bits of space left in the buffer.
						empty     <= (fill - M + N < M);
					end
					// We can only do the write
					else if (empty && !full) begin
						// The FIFO is full if, after we write N, we have
						// less than N bits of space left in the buffer, so writing another
						//  N bits would go over the maximum size.
						full  <= (fill + N + N > MEM_SIZE);
						// The FIFO is empty if, after we write N, we have
						// less than M bits of space left in the buffer.
						empty <= (fill + N < M);
					end
					// We can only do the read
					else if (!empty) begin
						// The FIFO is full if, after we read M bits, we have
						// less than N bits of space left in the buffer, so writing another
						//  N bits would go over the maximum size.
						full      <= (fill - M + N > MEM_SIZE);
						// The FIFO is empty if, after we read M bits, we have
						// less than M bits of space left in the buffer.
						empty     <= (fill - M < M);
					end
				end
				default: begin
					full <= (fill + N > MEM_SIZE);
					empty <= (fill < M);
				end
			endcase
		end
	end

	// Count the number of elements in the FIFO (multiplied by M)
	always @(posedge clk or negedge rst_n) begin
		// reset the flags and the fill for a soft/hard reset
		if (!rst_n) begin
			fill      <= 0;
			alm_empty <= 1;
			alm_full  <= 0;
		end else casez({ wr_en, rd_en, !full, !empty })
				// In order to compare thresholds, we will convert them to the number of
				// bits they represent and the fill used will be the value we expect
				// the fill to have on the next cycle, based on if a read and or/write
				// will happen this cycle.
				4'b01?1: begin // A successful read
					fill <= fill - M;
					if (fill - M <= alm_empty_thresh * M)
						alm_empty <= 1;
					else
						alm_empty <= 0;
					if (fill - M >= (FIFO_SIZE - alm_full_thresh) * N)
						alm_full <= 1;
					else
						alm_full <= 0;
				end
				4'b101?: begin // A successful write
					fill <= fill + N;
					if (fill + N <= alm_empty_thresh * M)
						alm_empty <= 1;
					else
						alm_empty <= 0;
					if (fill + N >= (FIFO_SIZE - alm_full_thresh) * N)
						alm_full <= 1;
					else
						alm_full <= 0;
				end
				4'b11??: begin // Read and write
					// We can do both
					if (!empty && !full) begin
						fill <= fill + N - M;
						if (fill + N - M <= alm_empty_thresh * M)
							alm_empty <= 1;
						else
							alm_empty <= 0;
						if (fill + N - M >= (FIFO_SIZE - alm_full_thresh) * N)
							alm_full <= 1;
						else
							alm_full <= 0;
					end
					// We can only do the write
					else if (empty && !full) begin
						fill <= fill + N;
						if (fill + N <= alm_empty_thresh * M)
							alm_empty <= 1;
						else
							alm_empty <= 0;
						if (fill + N >= (FIFO_SIZE - alm_full_thresh) * N)
							alm_full <= 1;
						else
							alm_full <= 0;
					end
					// We can only do the read
					else if (!empty) begin
						fill <= fill - M;
						if (fill - M <= alm_empty_thresh * M)
							alm_empty <= 1;
						else
							alm_empty <= 0;
						if (fill - M >= (FIFO_SIZE - alm_full_thresh) * N)
							alm_full <= 1;
						else
							alm_full <= 0;
					end
				end
				// For other cases, the fill won't change, but the thresholds might.
				default: begin
					if (fill <= alm_empty_thresh * M)
						alm_empty <= 1;
					else
						alm_empty <= 0;
					if (fill >= (FIFO_SIZE - alm_full_thresh) * N)
						alm_full <= 1;
					else
						alm_full <= 0;
				end
			endcase
	end
endmodule