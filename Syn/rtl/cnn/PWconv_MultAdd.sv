module PWconv_MultAdd (
    input  logic        clk,
    input  logic        rst_b,
    input  logic        en,
    input  logic signed [0:32*8-1] conv_weights ,
    input  logic signed [7:0]  input_data [3:0][31:0], // 4个空间像素，每个32通道
    input  logic signed [15:0]  bias,
    output logic signed [7:0] output_data [1:0][1:0]   // 映射回 2x2 空间像素
);

    // 中间线网：连接 Cell 的 32-bit 输出到 RescaleReLu
    logic signed [31:0] cell_out [1:0][1:0];

    genvar r, c;
    generate
        for (r = 0; r < 2; r++) begin : row_gen
            for (c = 0; c < 2; c++) begin : col_gen
                
                // 1. 数据映射路由
                // 逐点卷积无重叠窗口，直接将 4 个输入特征 (0,1,2,3) 
                // 映射到 2x2 的输出网格 (r*2+c)
                
                PWconv_MultAdd_cell cell_inst (
                    .clk(clk),
                    .conv_weights(conv_weights),           // 共享相同的通道权重
                    .input_data(input_data[r * 2 + c]),    // 提取对应像素的 32 通道数据
                    .bias(bias),                           // 共享 bias
                    .output_data(cell_out[r][c])           // 32-bit 中间累加和
                );

                // 2. 例化后处理模块：重缩放与激活 (Rescale & ReLU)
                RescaleReLu #(
                    .M0(8'sd69),
                    .N(8'd13)
                ) rescalerelu_inst (
                    .rst_b(rst_b),                 // 顶层复位控制流向后处理模块
                    .clk(clk),
                    .en(en),                       // 顶层使能卡住后处理更新
                    .data_in(cell_out[r][c]),
                    .data_out(output_data[r][c])   // 最终 8-bit ReLU 结果
                );

            end
        end
    endgenerate

endmodule