// PWConv Weight ROM: 32 output channels × 32 input channels, 8-bit each
// Combinational output.

module PWconv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic [0:32*8-1] data_out
);

    logic signed [7:0] mem [0:31][0:31]; // 32 out_ch × 32 in_ch

    always_comb begin
        for (int i = 0; i < 32; i++) begin
            for (int b = 0; b < 8; b++) begin
                data_out[i*8 + b] = mem[addr][i][b];
            end
        end
    end

endmodule
