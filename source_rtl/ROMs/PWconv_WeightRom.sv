// PWConv Weight ROM: 32 output channels × 32 input channels, 8-bit each
// Uses 2x S018V3EBCDSP_X8Y4D128_PR (32 depth × 128 bits).
// 32 weights × 8 bits = 256 bits = 2 × 128 bits.
// TB loads via sram_inst[i].mem_array[].

module PWconv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic [0:32*8-1] data_out
);

    wire cen = ~en;
    wire wen = 1'b1;

    wire [127:0] sram_q [0:1];

    genvar gi;
    generate
        for (gi = 0; gi < 2; gi++) begin : sram_inst
            S018V3EBCDSP_X8Y4D128_PR u_sram (
                .Q   (sram_q[gi]),
                .CLK (clk),
                .CEN (cen),
                .WEN (wen),
                .A   (addr),
                .D   (128'd0)
            );
        end
    endgenerate

    // sram_inst[0].Q → weights[0:15]  (128 bits)
    // sram_inst[1].Q → weights[16:31] (128 bits)
    always_comb begin
        for (int w = 0; w < 32; w++) begin
            automatic int sram_idx = w / 16;
            automatic int bit_offset = (w % 16) * 8;
            for (int b = 0; b < 8; b++) begin
                data_out[w*8 + b] = sram_q[sram_idx][bit_offset + b];
            end
        end
    end

endmodule
