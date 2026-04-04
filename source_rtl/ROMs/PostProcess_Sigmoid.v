// PostProcess Sigmoid: LUT-based sigmoid for behavioral simulation.
// 256-entry LUT mapping INT8 (unsigned index) to FP32 IEEE754.
// Registered output (1-cycle latency) matching original SRAM timing.
// Testbench loads sigmoid_lut[] via hierarchical access.

module PostProcess_Sigmoid (
    input clk,
    input rst_b,
    input en,
    input [8:0] iter_in,
    input [7:0] data_in0,
    input [7:0] data_in1,
    output reg [8:0] iter_out,
    output reg valid,
    output reg [31:0] float32_output0,
    output reg [31:0] float32_output1
);

    parameter MAX_ITER = 288;

    // Sigmoid lookup table (256 entries of FP32 in IEEE754 format)
    reg [31:0] sigmoid_lut [0:255];

    // Iter delay
    always @(posedge clk or negedge rst_b) begin
        if (~rst_b)
            iter_out <= 0;
        else if (en)
            iter_out <= iter_in;
    end

    // Valid: high when all 288 linear iterations complete
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b)
            valid <= 0;
        else if (en)
            valid <= (iter_in == (MAX_ITER - 1));
        else
            valid <= valid;
    end

    // Sigmoid LUT read (registered, 1-cycle latency)
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            float32_output0 <= 32'h0;
            float32_output1 <= 32'h0;
        end else if (en && (iter_in == (MAX_ITER - 1))) begin
            float32_output0 <= sigmoid_lut[data_in0];
            float32_output1 <= sigmoid_lut[data_in1];
        end
    end

endmodule
