// PostProcess Linear Weight ROM: 288 entries, 2 output neurons
// Uses 1x S018V3EBCDSP_X64Y4D32_PR (256 depth × 32 bits) for entries 0-255
//   and 1x S018V3EBCDSP_X8Y4D32_PR  (32 depth × 32 bits)  for entries 256-287
// Each 32-bit word stores {weight1[7:0], weight0[7:0]} in [15:8] and [7:0].
// TB loads via sram_lo.mem_array[] and sram_hi.mem_array[].

module PostProcess_Linear_WeightROM (
    input clk,
    input rst_b,
    input en,
    input [8:0] iter,
    output signed [7:0] weight0,
    output signed [7:0] weight1
);

    wire cen = ~en;
    wire wen = 1'b1;

    // SRAM 0: entries 0-255 (256 depth × 32 bits)
    wire [31:0] sram_lo_q;
    S018V3EBCDSP_X64Y4D32_PR sram_lo (
        .Q   (sram_lo_q),
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .A   (iter[7:0]),
        .D   (32'd0)
    );

    // SRAM 1: entries 256-287 (32 depth × 32 bits)
    wire [31:0] sram_hi_q;
    S018V3EBCDSP_X8Y4D32_PR sram_hi (
        .Q   (sram_hi_q),
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .A   (iter[4:0]),
        .D   (32'd0)
    );

    // Select based on iter range
    reg use_hi; 
    always @(posedge clk) begin
        use_hi <= iter[8];
    end
    wire [31:0] sram_q = use_hi ? sram_hi_q : sram_lo_q;

    assign weight0 = sram_q[7:0];
    assign weight1 = sram_q[15:8];

endmodule
