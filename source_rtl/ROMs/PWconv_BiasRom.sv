// PWConv Bias ROM: 32 channels, 16-bit each
// Combinational output.

module PWconv_BiasRom (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,
    input  logic        en,
    output logic signed [15:0] data_out
);

    logic signed [15:0] mem [0:31];

    assign data_out = mem[addr];

endmodule
