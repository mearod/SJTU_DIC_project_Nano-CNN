// Conv Stage 1: (1,30,10) → (32,20,4)
// Processes 32 output channels sequentially.
// For each channel: 2×4 output pixels via Conv_MultAdd (pipeline latency = 5).
// FIFO combines consecutive 2-row strips into 4-row blocks for DWConv.
// Position 0: FIFO fill only. Positions 1-9: valid 4×4 output.

module Conv (
    input clk,
    input rst_b,
    input en,
    input valid_in,
    input signed [7:0] input_data [11:0][9:0],  // 12×10 sliding window
    input [4:0] cnt_in,       // channel index from top-level

    output [4:0] DWconv_sram_cnt_out,     // channel index for DWconv
    output [4:0] cnt_out,
    output [3:0] pos_out,
    output logic signed [7:0] output_data [3:0][3:0],  // 4×4 output block
    output valid_out
);

    // Pipeline latency: Input_latch + Conv_MultAdd_cell (3 stages) + RescaleReLu (2 stages) = 6
    localparam PIPE_LATENCY = 6;

    // ===== Pipeline valid shift register =====
    logic [PIPE_LATENCY-1:0] valid_pipe;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            valid_pipe <= '0;
        else
            valid_pipe <= {valid_pipe[PIPE_LATENCY-2:0], (en && valid_in)};
    end
    wire pipe_out_valid = valid_pipe[PIPE_LATENCY-1];

    // ===== DWconv_sram channel counter =====
    logic [4:0] DWconv_sram_cnt_out_reg;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            DWconv_sram_cnt_out_reg <= 0;
        else if (valid_pipe[PIPE_LATENCY-2]) // DWconv_sram_cnt_out connect to DWconv, and DWconv's sram is delayed by 1 cycle when reading, so we use valid_pipe[PIPE_LATENCY-2] to ensure synchronization
            DWconv_sram_cnt_out_reg <= DWconv_sram_cnt_out_reg + 1;  // auto-wraps at 32
    end
    assign DWconv_sram_cnt_out = DWconv_sram_cnt_out_reg;

    // ===== Output channel counter =====
    logic [4:0] cnt_out_reg;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            cnt_out_reg <= 0;
        else if (pipe_out_valid) // cnt_out connect to DWconv, and DWconv's sram is delayed by 1 cycle when reading, so we use valid_pipe[PIPE_LATENCY-2] to ensure synchronization
            cnt_out_reg <= cnt_out_reg + 1;  // auto-wraps at 32
    end
    assign cnt_out = cnt_out_reg;

    // ===== Position counter =====
    logic [3:0] pos_reg;
    logic first_position;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            pos_reg <= 0;
            first_position <= 1;
        end else if (pipe_out_valid && cnt_out_reg == 5'd31) begin
            if (pos_reg == 4'd9) begin
                pos_reg <= 0;
                first_position <= 1;
            end else begin
                pos_reg <= pos_reg + 1;
                first_position <= 0;
            end
        end
    end
    assign pos_out = pos_reg;

    // ===== Weight and Bias ROMs (combinational output) =====
    wire [0:77*8-1] conv_weights_flat;
    wire signed [15:0] conv_bias;

    Conv_WeightROM weight_rom (
        .clk(clk), .rst_b(rst_b),
        .addr(cnt_in), .en(en),
        .data_out(conv_weights_flat)
    );

    Conv_BiasROM bias_rom (
        .clk(clk), .rst_b(rst_b),
        .addr(cnt_in), .en(en),
        .data_out(conv_bias)
    );

    // ===== Convolution computation =====
    wire signed [7:0] data_computed [1:0][3:0];

    Conv_MultAdd mult_add_inst (
        .clk(clk), .rst_b(rst_b), .en(en),
        .conv_weights(conv_weights_flat),
        .input_data(input_data),
        .bias(conv_bias),
        .output_data(data_computed)
    );

    // ===== FIFO: stores previous 2×4 row strip for combining =====
    wire signed [7:0] fifo_rd_data [1:0][3:0];

    FIFO_2x4X8 #(.DEPTH(32)) fifo_inst (
        .clk(clk),
        .rst_n(rst_b),
        .wr_en(pipe_out_valid),
        .rd_en(valid_pipe[PIPE_LATENCY-2]),
        .wr_data(data_computed),
        .rd_data(fifo_rd_data)
    );

    // ===== Output assembly =====
    // Combine FIFO (old 2 rows) + current compute (new 2 rows) → 4×4 block
    assign valid_out = pipe_out_valid && !first_position;

    always_comb begin
        output_data[0] = fifo_rd_data[0];   // old row 0
        output_data[1] = fifo_rd_data[1];   // old row 1
        output_data[2] = data_computed[0];   // new row 0
        output_data[3] = data_computed[1];   // new row 1
    end

endmodule
