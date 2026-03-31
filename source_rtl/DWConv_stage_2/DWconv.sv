`define PIPE_STAGE_NUM 3
`define BUFFER_STAGE_NUM 32
//every cycle use 4*4 *8bit input_data, 1 weight core ,output 2*2 *8bit output_data
//select data/weight/bias -> Mult -> Add -> RescaleReLu(Output)
module DWconv (
    input clk,
    input rst_b,
    input en,
    input [4:0] cnt_in,  // 32
    input [3:0] pos_in,  // 9
    input [7:0] dwconv_weights [2:0][2:0],
    input [7:0] input_data [3:0][3:0],  // 2*4*8
    output [4:0] cnt_out,
    output [3:0] pos_out,
    output [7:0] pconv_weights [31:0], //???
    output [7:0] output_data [3:0][31:0],

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


//next stage buffer
wire data_computed_flag = (pipe_stage_shifter_reg[`BUFFER_STAGE_NUM - 1] == 1'b1) ? 1'b1 : 1'b0; // Valid output when the pipeline is at the last stage
logic [7:0] data_computed [1:0][1:0];

logic [31:0] buffer_stage_shifter_reg;

always_ff @(posedge clk or negedge rst_b) begin
    if (!rst_b) begin
        buffer_stage_shifter_reg <= '0;
    end else if (en && data_computed_flag) begin
        buffer_stage_shifter_reg <= {buffer_stage_shifter_reg[`BUFFER_STAGE_NUM-2:0], 1'b1}; // Shift in a '1' to indicate progress through the pipeline
    end else begin
        buffer_stage_shifter_reg <= {buffer_stage_shifter_reg[`BUFFER_STAGE_NUM-2:0], 1'b0};
    end
end

Buffer_4x32x8 #(
    .CHANNELS(32),
    .DATA_W(8)
) buffer_inst (
    .clk(clk),
    .rst_n(rst_b),
    .wr_en(valid_out || data_computed_flag), // 写使能与当前模块输出有效信号同步
    .wr_data(data_computed), // 将当前模块的输出数据写入缓冲区
    .rd_data(output_data) // 从缓冲区读取数据供下一阶段使用
);

always_comb begin
    valid_out = (buffer_stage_shifter_reg[`BUFFER_STAGE_NUM - 1] == 1'b1) ? 1'b1 : 1'b0; // 输出有效信号与缓冲区状态同步
end

//weighes and bias sram
logic [4:0] pconv_weight_addr;
logic [7:0] pconv_weights [31:0];
logic [0:32*8-1] pconv_weights_flattened;
always_ff begin
    pconv_weight_addr = buffer_stage_shifter_reg[`BUFFER_STAGE_NUM-2] ? cnt_out_reg+1 : 0; // 直接使用输入计数器作为地址
end
PWconv_WeightROM Pweight_rom_inst (
    .clk(clk),
    .rst_b(rst_b),
    .addr(pconv_weight_addr), // 使用输入计数器作为地址
    .en(en),       // 使能信号与输入同步
    .data_out(pconv_weights_flattened) // 输出选定的权重数据
);

// convolution computation

endmodule
