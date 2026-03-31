`define PIPE_STAGE_NUM 3

module PWconv (
    input clk,
    input rst_b,
    input en,
    input [4:0] cnt_in,  // 32
    input [3:0] pos_in,  // 9
    input [7:0] pconv_weights [31:0], // ???
    input [7:0] input_data [3:0][31:0], 
    output [4:0] cnt_out,
    output [3:0] pos_out,
    output [7:0] output_data [3:0],

    input valid_in,
    output valid_out
);

//state control
logic [`PIPE_STAGE_NUM-1:0] pipe_stage_shifter_reg;

always_ff @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
        pipe_stage_shifter_reg <= '0;
    end else if (en && valid_in) begin
        pipe_stage_shifter_reg <= {pipe_stage_shifter_reg[`PIPE_STAGE_NUM-2:0], 1'b1}; // Shift in a '1' to indicate progress through the pipeline
    end else begin
        pipe_stage_shifter_reg <= {pipe_stage_shifter_reg[`PIPE_STAGE_NUM-2:0], 1'b0};
    end
end


logic [4:0] cnt_out_reg;
logic [3:0] pos_out_reg;

always_ff @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
        cnt_out_reg <= 0;
    end else if (pipe_stage_shifter_reg[`PIPE_STAGE_NUM - 1] == 1'b1) begin
        cnt_out_reg <= cnt_out_reg + 1; // Output the current stage of the pipeline
    end else begin
        cnt_out_reg <= 0; // Reset output when enable is low
    end
end

always_ff @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
        pos_out_reg <= 0;
    end else if (cnt_out_reg == 5'd31) begin
        if(pos_out_reg == 4'd8) begin
            pos_out_reg <= 0; // Reset position output after reaching the last position
        end else begin
            pos_out_reg <= pos_out_reg + 1; // Move to the next position
        end
    end else begin
        pos_out_reg <= pos_out_reg;
    end 
end
endmodule