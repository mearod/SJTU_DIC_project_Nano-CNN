// DWConv Weight ROM: 32 channels × 9 weights (3×3 kernel), 8-bit each
// Uses 1x S018V3EBCDSP_X8Y4D72_PR (32 depth × 72 bits).
// 9 weights × 8 bits = 72 bits, exact fit.
// TB loads via sram_inst.mem_array[].

module DWconv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic [0:9*8-1] data_out
);

    wire cen = ~en;
    wire wen = 1'b1;
    wire [71:0] sram_q;

    S018V3EBCDSP_X8Y4D72_PR sram_inst (
        .Q   (sram_q),
        .CLK (clk),
        .CEN (cen),
        .WEN (wen),
        .A   (addr),
        .D   (72'd0)
    );

    // Map SRAM output to data_out
    always_comb begin
        for (int i = 0; i < 9; i++) begin
            for (int b = 0; b < 8; b++) begin
                data_out[i*8 + b] = sram_q[i*8 + b];
            end
        end
    end

endmodule
