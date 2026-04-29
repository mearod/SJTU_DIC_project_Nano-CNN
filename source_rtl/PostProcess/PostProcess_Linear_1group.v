module PostProcess_Linear_1group (
    input clk,
    input rst_b,
    input en,
    input valid_in,
    input [8:0] iter,
    input [8:0] iter_tmp,
    input signed [7:0] data_in,
    input signed [7:0] weight,
    input signed [31:0] bias,
    output reg signed [31:0] data_out
);
 
    reg signed [31:0] mul_result;

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            mul_result <= 0;
        end else if (en) begin
            if(valid_in) begin
                mul_result <= data_in * weight;
            end
        end
        else begin
            mul_result <= mul_result;
        end
    end

    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            data_out <= 0;
        end else if (en) begin
            if (valid_in) begin
                if(iter == 0) begin
                    data_out <= bias;
                end
                else begin
                    data_out <= data_out + mul_result;
                end
            end
            else if (iter_tmp != 0) begin
                data_out <= data_out + mul_result;
            end
        end
        else begin
            data_out <= data_out;
        end
    end

endmodule
