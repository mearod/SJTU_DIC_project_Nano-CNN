// ==========================================
// 核心计算单元：32维 8bit 逐点卷积(1x1)计算核心
// ==========================================
module PWconv_MultAdd_cell (
    input  logic        clk,
    input  logic signed  conv_weights [0:32*8-1], // 32个权重 * 8bit
    input  logic signed [7:0]  input_data [31:0], // 32个通道输入数据
    input  logic signed [7:0]  bias,
    output logic signed [31:0] output_data
);

    // ==========================================
    // 0. 权重解析 (Bit展平到8-bit数组)
    // ==========================================
    logic signed [7:0] flat_wt [0:31];
    always_comb begin
        for (int i = 0; i < 32; i++) begin
            for (int j = 0; j < 8; j++) begin
                flat_wt[i][j] = conv_weights[i*8 + j];
            end
        end
    end

    // ==========================================
    // 流水级 1 (S1)：32路并行乘法 + Bias对齐延迟
    // 延迟: T_mul
    // ==========================================
    logic signed [15:0] s1_prod [0:31];
    logic signed [7:0]  s1_bias;

    always_ff @(posedge clk) begin
        // 32个通道并行乘法
        for (int i = 0; i < 32; i++) begin
            s1_prod[i] <= flat_wt[i] * input_data[i];
        end
        // 锁存 bias，作为旁路送入下一级
        s1_bias <= bias;
    end

    // ==========================================
    // 流水级 2 (S2)：完美加法树前 4 级 (核心时序平衡级)
    // 延迟: 4 x T_add (完美匹配 T_mul)
    // ==========================================
    logic signed [16:0] s2_l1 [0:15]; // L1: 32 -> 16
    logic signed [17:0] s2_l2 [0:7];  // L2: 16 -> 8
    logic signed [18:0] s2_l3 [0:3];  // L3:  8 -> 4
    logic signed [19:0] s2_l4 [0:1];  // L4:  4 -> 2

    always_comb begin
        // --- 纯粹的完美二叉加法树 ---
        for (int i = 0; i < 16; i++) s2_l1[i] = s1_prod[2*i] + s1_prod[2*i+1];
        for (int i = 0; i < 8;  i++) s2_l2[i] = s2_l1[2*i] + s2_l1[2*i+1];
        for (int i = 0; i < 4;  i++) s2_l3[i] = s2_l2[2*i] + s2_l2[2*i+1];
        for (int i = 0; i < 2;  i++) s2_l4[i] = s2_l3[2*i] + s2_l3[2*i+1];
    end

    // S2 寄存器锁存 (截断加法树以平衡时序)
    logic signed [19:0] s2_out [0:1];
    logic signed [7:0]  s2_bias;
    always_ff @(posedge clk) begin
        s2_out[0] <= s2_l4[0];
        s2_out[1] <= s2_l4[1];
        s2_bias   <= s1_bias; // Bias 继续打拍前进
    end

    // ==========================================
    // 流水级 3 (S3)：加法树最后 1 级 + 融入Bias
    // 延迟: 2 x T_add (非关键路径)
    // ==========================================
    logic signed [20:0] s3_l5; // 最终的点乘和
    logic signed [21:0] s3_l6; // 加上 Bias

    always_comb begin
        s3_l5 = s2_out[0] + s2_out[1];
        s3_l6 = s3_l5 + s2_bias; 
    end

    // 锁存输出并执行自动符号位扩展(至32bit)
    always_ff @(posedge clk) begin
        output_data <= s3_l6;
    end

endmodule