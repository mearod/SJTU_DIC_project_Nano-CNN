module Rescale_Shifter #(  // 只 shift，不做 relu
    parameter [7:0] N = 8'd11
) (
    input rst_b,
    input clk,
    input en,
    input signed [31:0] data_in,
    output reg signed [7:0] data_out
);

    wire signed [31:0] shifted;
    assign shifted = data_in >>> N;
    always @(posedge clk or negedge rst_b) begin
        if (~rst_b) begin
            data_out <= 0;
        end else if (en) begin
            data_out <= (shifted < -128) ? -8'sd128 : ((shifted > 127) ? 8'sd127 : shifted[7:0]);
        end else begin
            data_out <= data_out;
        end
    end

endmodule
