// Conv Weight ROM: 32 channels × 77 weights (11×7 kernel), 8-bit each
// Uses 5x S018V3EBCDSP_X8Y4D128_PR (32 depth × 128 bits) in parallel.
// Total output: 5×128 = 640 bits, using 616 bits (77×8).
// TB loads data via hierarchical access to sram_inst[i].mem_array[].

module Conv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic [0:77*8-1] data_out
);

    wire cen = ~en;  // SRAM CEN is active low
    wire wen = 1'b1; // always read

    // 5 SRAM instances, each 32 depth × 128 bits
    wire [127:0] sram_q [0:4];

    genvar gi;
    generate
        for (gi = 0; gi < 5; gi++) begin : sram_inst
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

    // Pack SRAM outputs into data_out[0:615]
    // sram_inst[0].Q = bits [0:127]   → weights[0:15]  (16 weights × 8 bits)
    // sram_inst[1].Q = bits [128:255] → weights[16:31]
    // sram_inst[2].Q = bits [256:383] → weights[32:47]
    // sram_inst[3].Q = bits [384:511] → weights[48:63]
    // sram_inst[4].Q = bits [512:615] → weights[64:76] (13 weights × 8 bits = 104 bits, pad 24)
    always_comb begin
        for (int w = 0; w < 77; w++) begin
            automatic int sram_idx = w / 16;
            automatic int bit_offset = (w % 16) * 8;
            for (int b = 0; b < 8; b++) begin
                data_out[w*8 + b] = sram_q[sram_idx][bit_offset + b];
            end
        end
    end

endmodule
