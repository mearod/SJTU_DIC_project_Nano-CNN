module Conv_MultAdd (
    input  logic    clk,
    input  logic    rst_b,
    input  logic    en,
    input  logic signed  conv_weights [0:77*8-1],
    input  logic signed [7:0]  input_data [11:0][9:0], 
    input  logic signed [7:0]  bias,
    output logic signed [7:0] output_data [1:0][3:0]
);

    // 用于连接 cell 的 32-bit 输出到 RescaleReLu 的输入
    logic signed [31:0] cell_out [1:0][3:0];

    // 使用 generate block 展开 8 个并行的卷积核计算单元 (2行 x 4列)
    genvar r, c;
    generate
        for (r = 0; r < 2; r++) begin : row_gen
            for (c = 0; c < 4; c++) begin : col_gen
                
                // 1. 数据切片：为当前 cell 准备对应的 11x7 输入窗口 (滑动窗口)
                logic signed [7:0] cell_in [10:0][6:0];
                
                always_comb begin
                    for (int i = 0; i < 11; i++) begin
                        for (int j = 0; j < 7; j++) begin
                            // 根据行列索引 r 和 c 进行偏移，提取子窗口
                            cell_in[i][j] = input_data[r + i][c + j];
                        end
                    end
                end

                // 2. 例化底层的 77维 8bit 点乘运算流水线单元
                Conv_MultAdd_cell cell_inst (
                    .clk(clk),
                    .conv_weights(conv_weights),  // 所有 cell 共享相同的权重
                    .input_data(cell_in),         // 当前 cell 专属的 11x7 输入窗口
                    .bias(bias),                  // 所有 cell 共享相同的 bias
                    .output_data(cell_out[r][c])  // 32-bit 中间输出
                );

                // 3. 例化后处理模块：重缩放与激活 (Rescale & ReLU)
                RescaleReLu #(
                    .M0(8'sd59),
                    .N(8'd11)
                ) rescalerelu (
                    // 顶层没有复位和使能端口，所以固定接 1 (active low reset & high enable)
                    .rst_b(1'b1),
                    .clk(clk),
                    .en(en),
                    .data_in(cell_out[r][c]),      // 接入本单元的 32-bit 乘加和
                    .data_out(output_data[r][c])   // 最终 8-bit 输出直连到顶层端口
                );

            end
        end
    endgenerate

endmodule