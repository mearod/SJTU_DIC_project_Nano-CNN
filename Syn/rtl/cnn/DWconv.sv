// DWConv Stage 2: (32,20,4) → (32,18,2)
// Receives 4×4 blocks from Conv, computes 3×3 depthwise conv → 2×2 per channel.
// Uses double-buffered Buffer_4x32x8 to accumulate all 32 channels.
// When buffer is full (32 channels), asserts valid_out for PWConv.

module DWconv (
    input clk,
    input rst_b,
    input en,
    input valid_in,
    input [4:0] cnt_in,       // channel index from Conv
    input signed [7:0] input_data [3:0][3:0],  // 4×4 block from Conv

    output valid_out,
    output [3:0] pos_out,
    output signed [7:0] output_data [3:0][31:0]  // 4 spatial × 32 channels (buffer)
);

    // Pipeline latency: DWconv_MultAdd_cell (2 stages) + RescaleReLu (2 stages) = 4
    localparam PIPE_LATENCY = 4;

    // ===== Pipeline valid tracking =====
    logic [PIPE_LATENCY-1:0] valid_pipe;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            valid_pipe <= '0;
        else
            valid_pipe <= {valid_pipe[PIPE_LATENCY-2:0], valid_in};
    end
    wire dw_out_valid = valid_pipe[PIPE_LATENCY-1];

    // ===== Output channel counter =====
    logic [4:0] out_cnt;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            out_cnt <= 0;
        else if (dw_out_valid)
            out_cnt <= out_cnt + 1;  // auto-wraps at 32
    end

    // ===== Position counter =====
    logic [3:0] pos_reg;
    logic [3:0] pos_for_pw;  // latched before increment, for PWconv
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            pos_reg <= 0;
            pos_for_pw <= 0;
        end else if (dw_out_valid && out_cnt == 5'd31) begin
            pos_for_pw <= pos_reg;  // capture current pos before increment
            pos_reg <= (pos_reg == 4'd8) ? 4'd0 : pos_reg + 1;
        end
    end
    assign pos_out = pos_for_pw;

    // ===== Weight and Bias ROMs =====
    wire [0:9*8-1] dw_weights_flat;
    wire signed [15:0] dw_bias;

    DWconv_WeightROM weight_rom (
        .clk(clk), .rst_b(rst_b),
        .addr(cnt_in), .en(en),
        .data_out(dw_weights_flat)
    );

    DWconv_BiasRom bias_rom (
        .clk(clk), .rst_b(rst_b),
        .addr(cnt_in), .en(en),
        .data_out(dw_bias)
    );

    // ===== DWConv computation: 4×4 → 2×2 =====
    wire signed [7:0] data_computed [1:0][1:0];

    DWconv_MultAdd mult_add_inst (
        .clk(clk), .rst_b(rst_b), .en(en),
        .conv_weights(dw_weights_flat),
        .input_data(input_data),
        .bias(dw_bias),
        .output_data(data_computed)
    );

    // ===== Double-buffered storage for PWConv =====
    Buffer_4x32x8 #(.CHANNELS(32), .DATA_W(8)) buffer_inst (
        .clk(clk),
        .rst_n(rst_b),
        .wr_en(dw_out_valid),
        .wr_data(data_computed),
        .rd_data(output_data)
    );

    // ===== Buffer ready signal =====
    // Fires 1 cycle after the last channel (31) is written, when bank has flipped
    logic buffer_ready;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            buffer_ready <= 0;
        else
            buffer_ready <= (dw_out_valid && out_cnt == 5'd31);
    end
    assign valid_out = buffer_ready;

endmodule
