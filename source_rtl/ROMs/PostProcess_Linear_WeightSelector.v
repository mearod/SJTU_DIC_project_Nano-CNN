// PostProcess Linear Weight ROM: 288 entries, 2 output neurons
// Registered output (1-cycle latency) to match PostProcess timing.
// Testbench loads mem0/mem1 via hierarchical access.

module PostProcess_Linear_WeightROM (
    input clk,
    input rst_b,
    input en,
    input [8:0] iter,
    output reg signed [7:0] weight0,
    output reg signed [7:0] weight1
);

    reg signed [15:0] mem [0:287]; // weights for output neuron 0

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            weight0 <= 0;
            weight1 <= 0;
        end else if (en) begin
            weight0 <= mem[iter][7:0];
            weight1 <= mem[iter][15:8];
        end
    end

endmodule
