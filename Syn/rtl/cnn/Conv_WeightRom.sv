// Conv Weight ROM: 32 channels × 77 weights (11×7 kernel), 8-bit each
// Combinational output. Testbench loads data via hierarchical access to mem[][].

module Conv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic [0:77*8-1] data_out
);

    logic signed [7:0] mem [0:31][0:76]; // 32 channels × 77 weights

    always_comb begin
        for (int i = 0; i < 77; i++) begin
            for (int b = 0; b < 8; b++) begin
                data_out[i*8 + b] = mem[addr][i][b];
            end
        end
    end

endmodule
