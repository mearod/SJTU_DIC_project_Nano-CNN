module Conv_MultAdd_cell (
    input  logic        clk,
    input  logic signed [0:77*8-1] conv_weights ,
    input  logic signed [7:0]  input_data [10:0][6:0], 
    input  logic signed [15:0]  bias,
    output logic signed [31:0] output_data
);

    // ==========================================
    // 0. 输入展平处理与数据重组
    // ==========================================
    logic signed [7:0] flat_wt [0:76];
    logic signed [7:0] flat_in [0:76];

    always_comb begin
        // 1. 处理 conv_weights: 将 616 个 1-bit 数按每 8 bit 组合成 77 个 8-bit有符号数
        for (int i = 0; i < 77; i++) begin
            for (int j = 0; j < 8; j++) begin
                flat_wt[i][j] = conv_weights[i*8 + j];
            end
        end
        
        // 2. 处理 input_data: 将二维数组映射为一维数组，方便对齐
        for (int i = 0; i < 11; i++) begin
            for (int j = 0; j < 7; j++) begin
                flat_in[i*7 + j] = input_data[i][j];
            end
        end
    end

    // ==========================================
    // 流水级 1 (S1)：77路并行乘法 + Bias对齐延迟
    // 延迟: ~ 4 x T_add (乘法器延迟)
    // ==========================================
    logic signed [15:0] s1_prod [0:76];
    logic signed [15:0]  s1_bias; // Bias 延迟一拍，与乘法器输出在时间上对齐

    always_ff @(posedge clk) begin
        // 77个 8bit x 8bit 有符号乘法 -> 16bit输出
        for (int i = 0; i < 77; i++) begin
            s1_prod[i] <= flat_wt[i] * flat_in[i];
        end
        // 锁存 bias 送入下一级
        s1_bias <= bias;
    end

    // ==========================================
    // 流水级 2 (S2)：加法树前 4 级 (核心时序平衡级) + 引入Bias
    // 延迟: 4 x T_add (完美匹配 S1 的乘法延迟)
    // ==========================================
    // 组合逻辑节点声明 (严格控制每级位宽增加 1bit 避免浪费)
    logic signed [16:0] s2_l1 [0:38]; // 39个 (78输入压缩)
    logic signed [17:0] s2_l2 [0:19]; // 20个 (39输入压缩)
    logic signed [18:0] s2_l3 [0:9];  // 10个 (20输入压缩)
    logic signed [19:0] s2_l4 [0:4];  // 5个  (10输入压缩)

    always_comb begin
        // --- 第 1 级加法 (L1) ---
        // 前 76 个乘积两两相加 (38 对)
        for (int i = 0; i < 38; i++) begin
            s2_l1[i] = s1_prod[2*i] + s1_prod[2*i+1];
        end
        // 第 39 对：巧妙利用第77个乘积(原加法树旁路) + s1_bias(正好作为另一个输入)
        s2_l1[38] = s1_prod[76] + s1_bias;

        // --- 第 2 级加法 (L2) ---
        // 39 个输入 -> 19对相加 + 1个旁路
        for (int i = 0; i < 19; i++) begin
            s2_l2[i] = s2_l1[2*i] + s2_l1[2*i+1];
        end
        s2_l2[19] = s2_l1[38]; // 旁路数，纯线连无加法开销

        // --- 第 3 级加法 (L3) ---
        // 20 个输入 -> 10对相加
        for (int i = 0; i < 10; i++) begin
            s2_l3[i] = s2_l2[2*i] + s2_l2[2*i+1];
        end

        // --- 第 4 级加法 (L4) ---
        // 10 个输入 -> 5对相加
        for (int i = 0; i < 5; i++) begin
            s2_l4[i] = s2_l3[2*i] + s2_l3[2*i+1];
        end
    end

    // S2 寄存器锁存 (5 个 20bit)
    logic signed [19:0] s2_out [0:4];
    always_ff @(posedge clk) begin
        for (int i = 0; i < 5; i++) begin
            s2_out[i] <= s2_l4[i];
        end
    end

    // ==========================================
    // 流水级 3 (S3)：加法树后 3 级 + 结果输出
    // 延迟: 3 x T_add (小于 S1/S2 延迟，非关键路径)
    // ==========================================
    // 组合逻辑节点声明
    logic signed [20:0] s3_l5 [0:2]; // 3个
    logic signed [21:0] s3_l6 [0:1]; // 2个
    logic signed [22:0] s3_l7;       // 1个 (满累加最大需23bit)

    always_comb begin
        // --- 第 5 级加法 (L5) ---
        // 5 个输入 -> 2对相加 + 1个旁路
        s3_l5[0] = s2_out[0] + s2_out[1];
        s3_l5[1] = s2_out[2] + s2_out[3];
        s3_l5[2] = s2_out[4]; // 旁路数

        // --- 第 6 级加法 (L6) ---
        // 3 个输入 -> 1对相加 + 1个旁路
        s3_l6[0] = s3_l5[0] + s3_l5[1];
        s3_l6[1] = s3_l5[2]; // 旁路数

        // --- 第 7 级加法 (L7) ---
        // 2 个输入 -> 1对相加
        s3_l7 = s3_l6[0] + s3_l6[1];
    end

    // S3 寄存器锁存与符号扩展 (自动扩展至 32bit 输出端口)
    always_ff @(posedge clk) begin
        // SV对有符号变量会自动进行符号位扩展(Sign Extension)
        output_data <= s3_l7; 
    end

endmodule