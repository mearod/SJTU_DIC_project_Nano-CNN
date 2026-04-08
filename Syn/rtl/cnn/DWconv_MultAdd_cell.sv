module DWconv_MultAdd_cell (
    input  logic        clk,
    input  logic signed [0:9*8-1] conv_weights ,  // 9个权重 * 8bit
    input  logic signed [7:0]  input_data [2:0][2:0], // 3x3 输入窗口
    input  logic signed [15:0]  bias,
    output logic signed [31:0] output_data
);

    // ==========================================
    // 0. 输入展平处理与数据重组 (3x3 = 9 维)
    // ==========================================
    logic signed [7:0] flat_wt [0:8];
    logic signed [7:0] flat_in [0:8];

    always_comb begin
        // 1. 将 72 个 1-bit 权重重组成 9 个 8-bit 有符号数
        for (int i = 0; i < 9; i++) begin
            for (int j = 0; j < 8; j++) begin
                flat_wt[i][j] = conv_weights[i*8 + j];
            end
        end
        
        // 2. 将 3x3 二维输入映射为一维数组
        for (int i = 0; i < 3; i++) begin
            for (int j = 0; j < 3; j++) begin
                flat_in[i*3 + j] = input_data[i][j];
            end
        end
    end

    // ==========================================
    // 流水级 1 (S1)：9路并行乘法 + Bias对齐延迟
    // 组合延迟: T_mul
    // ==========================================
    logic signed [15:0] s1_prod [0:8];
    logic signed [15:0]  s1_bias;

    always_ff @(posedge clk) begin
        // 9个 8bit x 8bit 乘法 -> 16bit输出
        for (int i = 0; i < 9; i++) begin
            s1_prod[i] <= flat_wt[i] * flat_in[i];
        end
        // 锁存 bias 送入下一级加法树
        s1_bias <= bias;
    end

    // ==========================================
    // 流水级 2 (S2)：完整的 4 级加法树 + 结果输出
    // 组合延迟: 4 x T_add (完美等效于 T_mul)
    // ==========================================
    // 组合逻辑节点声明 (严格控制位宽扩展)
    logic signed [16:0] s2_l1 [0:4]; // L1: 10输入 -> 5个和
    logic signed [17:0] s2_l2 [0:2]; // L2: 5输入  -> 3个和
    logic signed [18:0] s2_l3 [0:1]; // L3: 3输入  -> 2个和
    logic signed [19:0] s2_l4;       // L4: 2输入  -> 1个最终和

    always_comb begin
        // --- 第 1 级加法 (L1) ---
        // 前 8 个乘积两两相加 (4 对)
        for (int i = 0; i < 4; i++) begin
            s2_l1[i] = s1_prod[2*i] + s1_prod[2*i+1];
        end
        // 第 5 对：第 9 个乘积 (s1_prod[8]) + s1_bias
        // 【极佳的巧合】：原本9个数会多出1个旁路，加入bias后刚好凑成双数，0浪费！
        s2_l1[4] = s1_prod[8] + s1_bias;

        // --- 第 2 级加法 (L2) ---
        // 5 个输入 -> 2对相加 + 1个旁路
        s2_l2[0] = s2_l1[0] + s2_l1[1];
        s2_l2[1] = s2_l1[2] + s2_l1[3];
        s2_l2[2] = s2_l1[4]; // 旁路数

        // --- 第 3 级加法 (L3) ---
        // 3 个输入 -> 1对相加 + 1个旁路
        s2_l3[0] = s2_l2[0] + s2_l2[1];
        s2_l3[1] = s2_l2[2]; // 旁路数

        // --- 第 4 级加法 (L4) ---
        // 2 个输入 -> 1对相加
        s2_l4 = s2_l3[0] + s2_l3[1];
    end

    // S2 寄存器锁存与符号扩展 (自动扩展至 32bit 输出端口)
    always_ff @(posedge clk) begin
        // 完成计算，直接锁存到输出寄存器
        output_data <= s2_l4; 
    end

endmodule