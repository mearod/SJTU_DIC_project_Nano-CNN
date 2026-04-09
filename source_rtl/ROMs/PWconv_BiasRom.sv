// PWConv Bias ROM: 32 channels, 16-bit each
// Uses 1x S018V3EBCDSP_X8Y4D32_PR (32 depth × 32 bits).
// Only lower 16 bits used.
// TB loads via sram_inst.mem_array[].

module PWconv_BiasRom (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic signed [15:0] data_out
);

    wire cen = ~en;
    wire wen = 1'b1;
    wire [31:0] sram_q;

    S018V3EBCDSP_X8Y4D32_PR sram_inst (
        .Q   (sram_q),
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .A   (addr),
        .D   (32'd0)
    );

    assign data_out = sram_q[15:0];

endmodule
