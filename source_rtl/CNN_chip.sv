module CNN_chip(
    input  wire        clk,
    input  wire        rst_b,
    input  wire        en,
    input  wire        start,
    input  wire [31:0] feature_in,  // 将 4组 8-bit 的 feature_in 展平为 32-bit 的外部引脚
    output wire        done,
    output wire [7:0]  result_byte
);

    // =========================================================================
    // 内部连线 (Internal Nets)
    // =========================================================================
    wire net_clk;
    wire net_rst_b;
    wire net_en;
    wire net_start;
    wire [31:0] net_feature_in;
    
    wire net_done;
    wire [7:0] net_result_byte;

    // =========================================================================
    // 输入 Pad 例化 (Input Pads)
    // =========================================================================
    PIW PIW_clk   (.PAD(clk),   .C(net_clk));
    PIW PIW_rst_b (.PAD(rst_b), .C(net_rst_b));
    PIW PIW_en    (.PAD(en),    .C(net_en));
    PIW PIW_start (.PAD(start), .C(net_start));

    // 使用 generate 块批量例化 32 个数据输入 Pad，避免代码冗长
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_piw_feature
            PIW PIW_feature (.PAD(feature_in[i]), .C(net_feature_in[i]));
        end
    endgenerate

    // =========================================================================
    // 输出 Pad 例化 (Output Pads)
    // =========================================================================
    PO8W PO8W_done (.I(net_done), .PAD(done));

    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : gen_po8w_result
            PO8W PO8W_result (.I(net_result_byte[j]), .PAD(result_byte[j]));
        end
    endgenerate

    // =========================================================================
    // 数据格式转换 (1D to 2D Array Mapping)
    // =========================================================================
    // CNN_Top 需要 signed [7:0] feature_in [3:0] 的二维数组格式
    wire signed [7:0] array_feature_in [3:0];
    
    assign array_feature_in[0] = net_feature_in[7:0];
    assign array_feature_in[1] = net_feature_in[15:8];
    assign array_feature_in[2] = net_feature_in[23:16];
    assign array_feature_in[3] = net_feature_in[31:24];

    // =========================================================================
    // 核心逻辑例化 (Core Logic Instantiation)
    // =========================================================================
    CNN_Top inst_CNN_Top (
        .clk         (net_clk),           // 
        .rst_b       (net_rst_b),         // 
        .en          (net_en),            // 
        .start       (net_start),         // 
        .feature_in  (array_feature_in),  // 映射后的二维数组输入 
        .done        (net_done),          // 
        .result_byte (net_result_byte)    // 
    );

endmodule