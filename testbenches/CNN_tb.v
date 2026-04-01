`timescale 1ns / 1ps

module CNN_tb;

    parameter COUNT_MAX = 120;  // 12*10=120，每次写入一个12*10窗口
    parameter ITER_MAX = 288;
    parameter POS_MAX = 9;      // pos 0~9，每次偏移2行，9代表空的

    reg clk;
    reg rst_b;
    reg [7:0] count;  // 0 to 119
    reg en;
    wire next_window_req;
    wire valid;
    wire [31:0] float_out0;
    wire [31:0] float_out1;

    // Instantiate modules
    // 直接在 TB 里定义一根14*10*8bit的总线
    reg [0:12*10*8-1] mem_tb_bus;

    CNN cnn (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .mem(mem_tb_bus),
        .next_window_req(next_window_req),
        .valid(valid),
        .float_out0(float_out0),
        .float_out1(float_out1)
    );



    // 30*10*8bit 原始输入数据（从文件读取）
    reg [0:7] full_data[0:30*10-1];

    integer i;

    initial begin
        // Initialize the clock and reset signal
        clk = 0;
        rst_b = 1;
        en = 0;
        #10 rst_b = 0;

        // -------------Initialize SRAM------------- //
        // conv
        #10;
        $readmemb(
            "./samples/Conv_Weight_arranged_0.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight0.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_1.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight1.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_2.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight2.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_3.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight3.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_4.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight4.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_5.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight5.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_6.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight6.uut.mem_core_array);
        $readmemb(
            "./samples/Conv_Weight_arranged_7.txt",
            cnn.u_cnn_conv.u_conv_weightselector.conv_weight7.uut.mem_core_array);
        $readmemh(
            "./samples/Conv_Bias_arranged.txt",
            cnn.u_cnn_conv.u_conv_biasselector.conv_bias.uut.mem_core_array);

        // dwconv
        #10;
        $readmemh(
            "./samples/DWConv_Weight_arranged.txt",
            cnn.u_cnn_conv.u_conv_activation.u_dwconv_weightselector.dwconv_weight.uut.mem_core_array);
        $readmemh(
            "./samples/DWConv_Bias_arranged.txt",
            cnn.u_cnn_dwconv.u_dwconv_biasselector.dwconv_bias.uut.mem_core_array);

        // pwconv
        #10;
        $readmemh(
            "./samples/PWConv_Weight_arranged_0.txt",
            cnn.u_cnn_dwconv.u_dwconv_outputcontrol.u_pwconv_weightselector.pwconv_weight_0.uut.mem_core_array);
        $readmemh(
            "./samples/PWConv_Weight_arranged_1.txt",
            cnn.u_cnn_dwconv.u_dwconv_outputcontrol.u_pwconv_weightselector.pwconv_weight_1.uut.mem_core_array);
        $readmemh(
            "./samples/PWConv_Bias_arranged.txt",
            cnn.u_cnn_pwconv.u_pwconv_conv.u_pwconv_biasselector.pwconv_bias.uut.mem_core_array);

        // linear
        #10;
        $readmemh(
            "./samples/Linear_Weight_arranged.txt",
            cnn.u_cnn_postprocess.u_linear_weightselector.linear_weight.uut.mem_core_array);

        // sigmoid
        #10;
        $readmemh(
            "./samples/sigmoid_lookup_table.txt",
            cnn.u_cnn_postprocess.u_postprocess_sigmoid.sigmoid0.uut.mem_core_array);
        $readmemh(
            "./samples/sigmoid_lookup_table.txt",
            cnn.u_cnn_postprocess.u_postprocess_sigmoid.sigmoid1.uut.mem_core_array);



        // -------------Input data------------- //
        #10 rst_b = 1;
        en = 1;

        for (i = 0; i < 496; i = i + 1) begin
            // 读取完整的 30*10 原始数据 (8-bit hex)
            $readmemh($sformatf("./samples/In/%0d_hex.txt", i), full_data);

            // 按 pos 循环，每次提取一个 14*10 窗口
            for (integer pos = 0; pos < POS_MAX; pos = pos + 1) begin
                
                // 0时间消耗，瞬间拼装14*10*8bit的数据
                @(negedge clk);
                for (count = 0; count < COUNT_MAX; count = count + 1) begin
                    // 把 8-bit 塞进大总线的对应槽位
                    mem_tb_bus[count*8 +: 8] = full_data[(pos * 2 * 10) + count];
                end
                // 等待换图信号
                @(posedge next_window_req);
            end
        end

        // more figures to do...


        #4000;
        $stop;
    end

    // Generate a clock with 50% duty cycle and period of 2 time units
    always #1 clk = ~clk;

    // Display the output of the CNN
    real out0;
    real out1;
    integer j;
    initial begin
        j = -1;
    end
    always @(posedge clk) begin
        if (valid) begin
            out0 = $bitstoshortreal(float_out0);
            out1 = $bitstoshortreal(float_out1);
            $display("%0d: Output0: %g(%h), Output1: %g(%h)", j, out0,
                     float_out0, out1, float_out1);
            j = j + 1;
        end
    end

endmodule
