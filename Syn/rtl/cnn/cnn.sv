// CNN Top Module
// Connects: Conv → DWConv → PWConv → PostProcess
// Manages input feature map window selection for Conv stage.
//
// Input:  30×10 INT8 feature map (loaded externally)
// Output: 2 FP32 sigmoid values (binary classification)

module cnn (
    input clk,
    input rst_b,
    input en,
    input start,                              // pulse to begin processing
    input signed [7:0] feature_window [11:0][9:0], // 12x10 input

    output done,                              // processing complete
    output [31:0] result0,                    // FP32 sigmoid output 0
    output [31:0] result1                     // FP32 sigmoid output 1
);

    // =========================================================================
    // Conv input management
    // =========================================================================
    // Conv needs 12×10 window. For position p, rows [2*p : 2*p+11].
    // Total: 10 positions × 32 channels = 320 valid_in cycles.

    logic [9:0] input_cycle_cnt;  // 0 to 319
    logic conv_feeding;           // high during the 320-cycle input phase

    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            input_cycle_cnt <= 0;
            conv_feeding <= 0;
        end else if (start) begin
            input_cycle_cnt <= 0;
            conv_feeding <= 1;
        end else if (conv_feeding) begin
            if (input_cycle_cnt == 10'd319) begin
                conv_feeding <= 0;
            end else begin
                input_cycle_cnt <= input_cycle_cnt + 1;
            end
        end
    end

    // Position = input_cycle_cnt / 32 = input_cycle_cnt[8:5]
    wire [3:0] input_pos = input_cycle_cnt[8:5];


    wire conv_valid_in = conv_feeding & en;

    // =========================================================================
    // Stage 1: Conv
    // =========================================================================
    logic [4:0] conv_cnt_in;
    wire [4:0] DWconv_sram_cnt;
    wire [3:0] conv_pos_out;
    wire signed [7:0] conv_output [3:0][3:0];
    wire conv_valid_out;


    // ===== Input channel counter (ROM address) ===== (sram has 1 cycle latency, so we can start counting when start signal is given or when valid_in is high)
    logic [4:0] conv_cnt_in;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            conv_cnt_in <= 0;
        else if (en && (start || conv_valid_in))  // Start counting on start signal or when valid_in is high
            conv_cnt_in <= conv_cnt_in + 1;  // 5-bit auto-wraps at 32
    end

    Conv u_conv (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .valid_in(conv_valid_in),
        .input_data(feature_window),
        .cnt_in(conv_cnt_in),
        .DWconv_sram_cnt_out(DWconv_sram_cnt),  // Pass channel index to DWconv
        .cnt_out(),
        .pos_out(conv_pos_out),
        .output_data(conv_output),
        .valid_out(conv_valid_out)
    );

    // =========================================================================
    // Stage 2: DWConv
    // =========================================================================
    wire dw_valid_out;
    wire [3:0] dw_pos_out;
    wire signed [7:0] dw_output [3:0][31:0];

    DWconv u_dwconv (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .valid_in(conv_valid_out),
        .cnt_in(DWconv_sram_cnt),
        .input_data(conv_output),
        .valid_out(dw_valid_out),
        .pos_out(dw_pos_out),
        .output_data(dw_output)
    );

    // =========================================================================
    // Stage 3: PWConv
    // =========================================================================
    wire pw_valid_out;
    wire [4:0] pw_cnt_out;
    wire [3:0] pw_pos_out;
    wire signed [7:0] pw_output [3:0];

    PWconv u_pwconv (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .start(dw_valid_out),
        .pos_in(dw_pos_out),
        .input_data(dw_output),
        .valid_out(pw_valid_out),
        .cnt_out(pw_cnt_out),
        .pos_out(pw_pos_out),
        .output_data(pw_output)
    );

    // =========================================================================
    // Stage 4: PostProcess (Maxpool → Linear → Rescale → Sigmoid)
    // =========================================================================
    wire pp_valid;
    wire [8:0] pp_iter_out;

    PostProcess u_postprocess (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .valid_in(pw_valid_out),
        .cnt_in(pw_cnt_out),
        .pos_in(pw_pos_out),
        .data_in0(pw_output[0]),
        .data_in1(pw_output[1]),
        .data_in2(pw_output[2]),
        .data_in3(pw_output[3]),
        .valid(pp_valid),
        .iter_out(pp_iter_out),
        .float_out0(result0),
        .float_out1(result1)
    );

    assign done = pp_valid;

endmodule