// PostProcess Sigmoid: LUT-based sigmoid for behavioral simulation.
// Uses 1x S018V3EBCDSP_X64Y4D32_PR (256 depth × 32 bits) for 256-entry FP32 LUT.
// TB loads via sram_inst.mem_array[].

module PostProcess_Sigmoid (
    input clk,
    input rst_b,
    input en,
    input [8:0] iter_in,
    input [7:0] data_in0,
    input [7:0] data_in1,
    output reg [8:0] iter_out,
    output reg valid,
    output [31:0] float32_output0,
    output [31:0] float32_output1
);

    parameter MAX_ITER = 288;

    wire cen = ~en;
    wire wen = 1'b1;

    // Two SRAM instances for parallel lookup of two inputs
    wire [31:0] sram_q0;
    wire [31:0] sram_q1;

    S018V3EBCDSP_X64Y4D32_PR sram_inst0 (
        .Q   (sram_q0),
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .A   (data_in0),
        .D   (32'd0)
    );

    S018V3EBCDSP_X64Y4D32_PR sram_inst1 (
        .Q   (sram_q1),
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .A   (data_in1),
        .D   (32'd0)
    );

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
            valid <= (iter_in == (MAX_ITER-1));
        else
            valid <= valid;
    end

    // Sigmoid LUT read from SRAM (synchronous, data available same cycle as Q)
    assign float32_output0 = sram_q0;
    assign float32_output1 = sram_q1;

endmodule
