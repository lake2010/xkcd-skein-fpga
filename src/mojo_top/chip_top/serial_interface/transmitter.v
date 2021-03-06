module transmitter (
	input clk_i,
	input rst_i,
	input tx_busy_i,
	input send_nonce_i,
	input send_ping_i,
	input byte_counter_zero_i,
	input chip_enabled_i,
	input [7:0] nonce_byte_i,
	input [9:0] nonce_bits_off_i,

	output reg tx_new_o,
	output reg [7:0] tx_data_o,
	output reg reset_ping_waiting_o,
	output reg reset_nonce_waiting_o,
	output reg reset_byte_counter_o,
	output reg decrement_byte_counter_o
);

reg [2:0] state, nextstate;

localparam	IDLE		= 0,
			SEND_PING	= 1,
			SEND_NONCE	= 2,
			SEND_BITS_OFF_1 = 3,
			SEND_BITS_OFF_2 = 4,
			FOOTER		= 5;

always @(*) begin
	nextstate = IDLE;
	tx_new_o = 1'b0;
	tx_data_o = 8'bxxxxxxxx;
	reset_ping_waiting_o = 1'b0;
	reset_nonce_waiting_o = 1'b0;
	reset_byte_counter_o = 1'b0;
	decrement_byte_counter_o = 1'b0;

	case (state)
		IDLE:
		if (tx_busy_i) begin
			nextstate = IDLE;
		end else begin
			if (chip_enabled_i) begin
				if (send_nonce_i) begin
					nextstate = SEND_NONCE;
					reset_nonce_waiting_o = 1'b1;
					reset_byte_counter_o = 1'b1;
					tx_new_o = 1'b1;
					tx_data_o = 8'd100;
				end else begin
					if (send_ping_i) begin
						nextstate = SEND_PING;
						reset_ping_waiting_o = 1'b1;
						tx_new_o = 1'b1;
						tx_data_o = 8'd100;
					end else begin
						nextstate = IDLE;
					end
				end
			end
		end

		SEND_PING:
		if (tx_busy_i) begin
			nextstate = SEND_PING;
		end else begin
			nextstate = FOOTER;
			tx_new_o = 1'b1;
			if (chip_enabled_i)
				tx_data_o = 8'd49;
			else
				tx_data_o = 8'd48;
		end

		SEND_NONCE:
		if (tx_busy_i) begin
			nextstate = SEND_NONCE;
		end else begin
			decrement_byte_counter_o = 1'b1;
			tx_new_o = 1'b1;
			tx_data_o = nonce_byte_i;
			if (byte_counter_zero_i)
				nextstate = SEND_BITS_OFF_1;
			else
				nextstate = SEND_NONCE;
		end

		SEND_BITS_OFF_1:
		if (tx_busy_i) begin
			nextstate = SEND_BITS_OFF_1;
		end else begin
			tx_new_o = 1'b1;
			tx_data_o = nonce_bits_off_i[7:0];
			nextstate = SEND_BITS_OFF_2;
		end

		SEND_BITS_OFF_2:
		if (tx_busy_i) begin
			nextstate = SEND_BITS_OFF_2;
		end else begin
			tx_new_o = 1'b1;
			tx_data_o = {6'b000000, nonce_bits_off_i[9:8]};
			nextstate = FOOTER;
		end

		FOOTER:
		if (tx_busy_i) begin
			nextstate = FOOTER;
		end else begin
			nextstate = IDLE;
			tx_new_o = 1'b1;
			tx_data_o = 8'd52;
		end
	endcase
end

always @(posedge clk_i) begin
	if (rst_i) begin
		state <= IDLE;
	end else begin
		state <= nextstate;
	end
end

endmodule
