module DWconv_MultAdd (
    input  logic        clk,
    input  logic        rst_b,
    input  logic        en,
    input  logic signed [0:9*8-1] conv_weights ,
    input  logic signed [7:0]  input_data [3:0][3:0], 
    input  logic signed [15:0]  bias,
    output logic signed [7:0] output_data [1:0][1:0]
);

    // 声明中间线网：用于连接 Cell 的 32-bit 输出到 RescaleReLu 的输入
    logic signed [31:0] cell_out [1:0][1:0];

    // 使用 generate block 展开 4 个并行的 3x3 卷积计算核心 (2行 x 2列)
    genvar r, c;
    generate
        for (r = 0; r < 2; r++) begin : row_gen
            for (c = 0; c < 2; c++) begin : col_gen
                
                // 1. 数据切片：为当前 cell 提取对应的 3x3 滑动窗口输入
                logic signed [7:0] cell_in [2:0][2:0];
                
                always_comb begin
                    for (int i = 0; i < 3; i++) begin
                        for (int j = 0; j < 3; j++) begin
                            // 依据行列索引 (r, c) 进行偏移映射
                            cell_in[i][j] = input_data[r + i][c + j];
                        end
                    end
                end

                // 2. 例化 3x3 点乘流水线运算单元 (复用上一轮设计的 2 级完美流水线)
                DWconv_MultAdd_cell cell_inst (
                    .clk(clk),
                    .conv_weights(conv_weights),  // 所有核共享相同的 3x3 权重
                    .input_data(cell_in),         // 当前核专属的 3x3 输入窗口
                    .bias(bias),                  // 所有核共享相同的 bias
                    .output_data(cell_out[r][c])  // 32-bit 乘加累积中间结果
                );

                // 3. 例化重缩放与激活模块 (Rescale & ReLU)
                RescaleReLu #(
                    .M0(8'sd59), // 保持前面提供的缩放系数
                    .N(8'd11)
                ) rescalerelu_inst (
                    .rst_b(rst_b),                 // 接入顶层复位
                    .clk(clk),
                    .en(en),                       // 接入顶层使能
                    .data_in(cell_out[r][c]),      // 接入本单元的 32-bit 和
                    .data_out(output_data[r][c])   // 最终 8-bit 输出直连到顶层端口
                );

            end
        end
    endgenerate

endmodule