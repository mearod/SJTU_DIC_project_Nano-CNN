`define PIPE_STAGE_NUM 3

module Conv (
    input clk,
    input rst_b,
    input en,
    input [7:0] input_data [11:0][9:0],  // 12*10*8
    output [4:0] cnt_out,
    output [3:0] pos_out,  //0-9
    output [7:0] dwconv_weights [2:0][2:0], //?????
    output [8:0] output_data [3:0][3:0], //4*4*8

    input valid_in,
    output ready_in,
    output switch_map_flag_out,
    output valid_out
);
//state control in
logic [4:0] cnt_in_reg;

always_ff @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
        cnt_in_reg <= 0;
    end else if (en) begin
        cnt_in_reg <= cnt_in_reg + 1; // Increment the counter on each clock cycle when enabled
    end else begin
        cnt_in_reg <= 0; // Reset the counter when not enabled
    end
end

//weighes and bias sram
logic [7:0] conv_weights [10:0][6:0];
logic [0:77*8-1] conv_weights_flattened; // 77 weights for 9 positions + 1 bias per channel

Conv_WeightROM weight_rom_inst (
    .clk(clk),
    .rst_b(rst_b),
    .addr(cnt_in_reg), // 使用输入计数器作为地址
    .en(en),       // 使能信号与输入同步
    .data_out(conv_weights_flattened) // 输出选定的权重数据
);

logic [4:0] dwconv_weight_addr;
logic [7:0] dwconv_weights [2:0][2:0];
logic [0:9*8-1] dwconv_weights_flattened;
always_ff begin
    dwconv_weight_addr = pipe_stage_shifter_reg[`PIPE_STAGE_NUM-2] ? cnt_out_reg+1 : 0; // 直接使用输入计数器作为地址
end //or ff but `PIPE_STAGE_NUM-2
DWconv_WeightROM Dweight_rom_inst (
    .clk(clk),
    .rst_b(rst_b),
    .addr(dwconv_weight_addr), // 使用输入计数器作为地址
    .en(en),       // 使能信号与输入同步
    .data_out(dwconv_weights_flattened) // 输出选定的权重数据
);

//state control out
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
        if(pos_out_reg == 4'd9) begin
            pos_out_reg <= 0; // Reset position output after reaching the last position
        end else begin
            pos_out_reg <= pos_out_reg + 1; // Move to the next position
        end
    end else begin
        pos_out_reg <= pos_out_reg;
    end 
end

wire data_computed_flag = (pipe_stage_shifter_reg[`PIPE_STAGE_NUM - 1] == 1'b1) ? 1'b1 : 1'b0; // Valid output when the pipeline is at the last stage
assign ready_in = (pipe_stage_shifter_reg[0] == 1'b0 || cnt_in_reg == 5'd0) ? 1'b1 : 1'b0; // New input should be ready in next cycle.
assign switch_map_flag_out = (cnt_in_reg == 5'd31 && pos_out_reg == 4'd9) ? 1'b1 : 1'b0; // Flag to indicate when to switch the map


//FIFO_CACHE_2x4X8
logic [7:0] data_computed [1:0][3:0];
logic spliced_data_valid;
always_comb begin
    spliced_data_valid = pos_out_reg != 0 ? 1'b1 : 1'b0; // Data is valid when the counter reaches the last stage of the pipeline
end


logic [7:0] fifo_rd_data [1:0][3:0];

FIFO_2x4X8 #(
    .DEPTH(32)
) fifo_cache_inst (
    .clk(clk),
    .rst_n(rst_b),
    .wr_en(en && data_computed_flag), // Write enable when the module is enabled and input is valid
    .rd_en(spliced_data_valid), // Read enable at the last stage of the pipeline
    .wr_data(data_computed), // Write input data to FIFO
    .rd_data(fifo_rd_data)
);

always_comb begin
    output_data[3] = data_computed[1]; // 直接赋值一整行 ([3:0])
    output_data[2] = data_computed[0];
    output_data[1] = fifo_rd_data[1];
    output_data[0] = fifo_rd_data[0];
    valid_out = spliced_data_valid; // 输出数据有效信号
end

// convolution computation:compute data_computed based on input_data,which will be written into FIFO

endmodule