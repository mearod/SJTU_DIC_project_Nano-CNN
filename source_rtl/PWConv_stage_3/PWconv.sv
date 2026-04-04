// PWConv Stage 3: (32,18,2) → (32,18,2)
// Receives all 32 input channels for 4 spatial positions from DWConv buffer.
// Processes 32 output channels sequentially, one per cycle.
// Pipeline latency: PWconv_MultAdd_cell (3) + RescaleReLu (2) = 5.

module PWconv (
    input clk,
    input rst_b,
    input en,
    input start,                                       // pulse from DWconv buffer_ready
    input [3:0] pos_in,                                // position from DWconv
    input signed [7:0] input_data [3:0][31:0],         // 4 spatial × 32 channels

    output valid_out,
    output [4:0] cnt_out,
    output [3:0] pos_out,
    output signed [7:0] output_data [3:0]              // 4 spatial output values
);

    // Pipeline latency: PWconv_MultAdd_cell (3) + RescaleReLu (2) = 5
    localparam PIPE_LATENCY = 5;

    // ===== Processing control =====
    // On 'start' pulse, begin processing 32 output channels
    logic [4:0] proc_cnt;  // 0-31: processing, 32+: idle
    logic processing;

    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            proc_cnt <= 5'd0;
        end else if (start | processing) begin
            proc_cnt <= proc_cnt + 1;
        end
    end
    assign processing = start | (proc_cnt != 5'd0);



    // ===== Pipeline valid tracking =====
    logic [PIPE_LATENCY-1:0] valid_pipe;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            valid_pipe <= '0;
        else
            valid_pipe <= {valid_pipe[PIPE_LATENCY-2:0], processing};
    end
    wire pipe_out_valid = valid_pipe[PIPE_LATENCY-1];
    assign valid_out = pipe_out_valid;

    // ===== Position counter =====
    logic [3:0] pos_out_reg;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            pos_out_reg <= 0;
        end else if (pipe_out_valid && cnt_out == 5'd31) begin
            pos_out_reg <= (pos_out_reg == 4'd8) ? 4'd0 : pos_out_reg + 1;
        end
    end
    assign pos_out = pos_out_reg;

    // ===== Output channel counter =====
    logic [4:0] cnt_out_reg;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            cnt_out_reg <= 0;
        else if (pipe_out_valid)
            cnt_out_reg <= cnt_out_reg + 1;
    end
    assign cnt_out = cnt_out_reg;

    // ===== Weight and Bias ROMs =====
    wire [0:32*8-1] pw_weights_flat;
    wire signed [15:0] pw_bias;

    PWconv_WeightROM weight_rom (
        .clk(clk), .rst_b(rst_b),
        .addr(proc_cnt[4:0]), .en(en),
        .data_out(pw_weights_flat)
    );

    PWconv_BiasRom bias_rom (
        .clk(clk), .rst_b(rst_b),
        .addr(proc_cnt[4:0]), .en(en),
        .data_out(pw_bias)
    );

    // ===== PWConv computation =====
    wire signed [7:0] computed_2d [1:0][1:0];

    PWconv_MultAdd mult_add_inst (
        .clk(clk), .rst_b(rst_b), .en(en),
        .conv_weights(pw_weights_flat),
        .input_data(input_data),
        .bias(pw_bias),
        .output_data(computed_2d)
    );

    // ===== Output: flatten 2×2 → 4 =====
    assign output_data[0] = computed_2d[0][0];
    assign output_data[1] = computed_2d[0][1];
    assign output_data[2] = computed_2d[1][0];
    assign output_data[3] = computed_2d[1][1];

endmodule
