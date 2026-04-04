// DWConv Weight ROM: 32 channels × 9 weights (3×3 kernel), 8-bit each
// Combinational output.

module DWconv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic [0:9*8-1] data_out
);

    logic signed [7:0] mem [0:31][0:8]; // 32 channels × 9 weights

    always_comb begin
        for (int i = 0; i < 9; i++) begin
            for (int b = 0; b < 8; b++) begin
                data_out[i*8 + b] = mem[addr][i][b];
            end
        end
    end

endmodule
