`timescale 1ns / 1ps

module CNN_tb;

    // =========================================================================
    // Clock and Reset
    // =========================================================================
    reg clk;
    reg rst_b;
    reg en;
    reg start;

    initial clk = 0;
    always #5 clk = ~clk;  // 100 MHz

    // =========================================================================
    // DUT
    // =========================================================================
    reg signed[7:0] feature_map [0:29][0:9];
    wire done;
    wire [7:0] result_byte;

    logic signed [7:0] feature_in[3:0];

    CNN_Top dut (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .start(start),
        .feature_in(feature_in),
        .done(done),
        .result_byte(result_byte)
    );

    // =========================================================================
    // Feed Features Task (Serial Input stream)
    // =========================================================================
    task feed_features;
        int w, i, r, c;
        logic signed[7:0] flat_win[0:119];
        
        for (w = 0; w < 10; w++) begin
            for (r = 0; r < 12; r++) begin
                for (c = 0; c < 10; c++) begin
                    flat_win[r * 10 + c] = feature_map[2 * w + r][c];
                end
            end
            
            for (i = 0; i < 30; i++) begin
                feature_in[0] <= flat_win[i * 4 + 0];
                feature_in[1] <= flat_win[i * 4 + 1];
                feature_in[2] <= flat_win[i * 4 + 2];
                feature_in[3] <= flat_win[i * 4 + 3];
                @(posedge clk);
            end
            
            feature_in[0] <= 0;
            feature_in[1] <= 0;
            feature_in[2] <= 0;
            feature_in[3] <= 0;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Expected intermediate results
    // =========================================================================
    reg signed [7:0] exp_conv [0:31][0:19][0:3];
    reg signed [7:0] exp_dwconv [0:31][0:17][0:1];
    reg signed [7:0] exp_pwconv [0:31][0:17][0:1];
    reg signed [7:0] exp_flatten[0:287];
    reg signed [7:0] exp_linear [0:1];
    real exp_sigmoid [0:1];

    integer conv_errors, conv_checks;
    integer dwconv_errors, dwconv_checks;
    integer pwconv_errors, pwconv_checks;
    integer flatten_errors, flatten_checks;
    integer linear_pass;
    integer sigmoid_pass;

    integer fd, status, i, j, k;
    integer val;
    localparam string DATA_DIR = "D:\\subject\\IC_project\\NanoCNN\\CNN_test_data\\";

    // =========================================================================
    // ROM loadings
    // =========================================================================
    task load_all_parameters;
    begin
        load_conv_weights;
        load_conv_bias;
        load_dwconv_weights;
        load_dwconv_bias;
        load_pwconv_weights;
        load_pwconv_bias;
        load_linear_weights;
        load_sigmoid_lut;
        $display("[LOAD] All network parameters loaded.");
    end
    endtask

    task load_conv_weights;
        reg[127:0] sw0, sw1, sw2, sw3, sw4;
        integer w_idx, bit_off;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_Conv_Weight.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_Conv_Weight.txt"); $finish; end
        for (i = 0; i < 32; i++) begin
            sw0 = 128'd0; sw1 = 128'd0; sw2 = 128'd0; sw3 = 128'd0; sw4 = 128'd0;
            for (j = 0; j < 11; j++)
                for (k = 0; k < 7; k++) begin
                    status = $fscanf(fd, "%d", val);
                    w_idx = j*7+k;
                    bit_off = (w_idx % 16) * 8;
                    case (w_idx / 16)
                        0: sw0[bit_off +: 8] = val[7:0];
                        1: sw1[bit_off +: 8] = val[7:0];
                        2: sw2[bit_off +: 8] = val[7:0];
                        3: sw3[bit_off +: 8] = val[7:0];
                        4: sw4[bit_off +: 8] = val[7:0];
                    endcase
                end
            dut.u_cnn.u_conv.weight_rom.sram_inst[0].u_sram.mem_array[i] = sw0;
            dut.u_cnn.u_conv.weight_rom.sram_inst[1].u_sram.mem_array[i] = sw1;
            dut.u_cnn.u_conv.weight_rom.sram_inst[2].u_sram.mem_array[i] = sw2;
            dut.u_cnn.u_conv.weight_rom.sram_inst[3].u_sram.mem_array[i] = sw3;
            dut.u_cnn.u_conv.weight_rom.sram_inst[4].u_sram.mem_array[i] = sw4;
        end
        $fclose(fd);
    end
    endtask

    task load_conv_bias;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_Conv_Bias.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_Conv_Bias.txt"); $finish; end
        for (i = 0; i < 32; i++) begin
            status = $fscanf(fd, "%d", val);
            dut.u_cnn.u_conv.bias_rom.sram_inst.mem_array[i] = {val[15:0]};
        end
        $fclose(fd);
    end
    endtask

    task load_dwconv_weights;
        reg [71:0] sram_word;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_DWConv_Weight.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_DWConv_Weight.txt"); $finish; end
        for (i = 0; i < 32; i++) begin
            sram_word = 72'd0;
            for (j = 0; j < 3; j++)
                for (k = 0; k < 3; k++) begin
                    status = $fscanf(fd, "%d", val);
                    sram_word[(j*3+k)*8 +: 8] = val[7:0];
                end
            dut.u_cnn.u_dwconv.weight_rom.sram_inst.mem_array[i] = sram_word;
        end
        $fclose(fd);
    end
    endtask

    task load_dwconv_bias;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_DWConv_Bias.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_DWConv_Bias.txt"); $finish; end
        for (i = 0; i < 32; i++) begin
            status = $fscanf(fd, "%d", val);
            dut.u_cnn.u_dwconv.bias_rom.sram_inst.mem_array[i] = {val[15:0]};
        end
        $fclose(fd);
    end
    endtask

    task load_pwconv_weights;
        reg [127:0] sw0, sw1;
        integer bit_off;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_PWConv_Weight.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_PWConv_Weight.txt"); $finish; end
        for (i = 0; i < 32; i++) begin
            sw0 = 128'd0; sw1 = 128'd0;
            for (j = 0; j < 32; j++) begin
                status = $fscanf(fd, "%d", val);
                bit_off = (j % 16) * 8;
                if (j < 16)
                    sw0[bit_off +: 8] = val[7:0];
                else
                    sw1[bit_off +: 8] = val[7:0];
            end
            dut.u_cnn.u_pwconv.weight_rom.sram_inst[0].u_sram.mem_array[i] = sw0;
            dut.u_cnn.u_pwconv.weight_rom.sram_inst[1].u_sram.mem_array[i] = sw1;
        end
        $fclose(fd);
    end
    endtask

    task load_pwconv_bias;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_PWConv_Bias.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_PWConv_Bias.txt"); $finish; end
        for (i = 0; i < 32; i++) begin
            status = $fscanf(fd, "%d", val);
            dut.u_cnn.u_pwconv.bias_rom.sram_inst.mem_array[i] = {val[15:0]};
        end
        $fclose(fd);
    end
    endtask

    task load_linear_weights;
    begin
        fd = $fopen({DATA_DIR, "Param\\Linear_Weight_arranged.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Linear_Weight_arranged.txt"); $finish; end
        for (i = 0; i < 288; i++) begin
            status = $fscanf(fd, "%h", val);
            if (i < 256)
                dut.u_cnn.u_postprocess.u_linear_weightROM.sram_lo.mem_array[i] = {val[7:0], val[15:8]};
            else
                dut.u_cnn.u_postprocess.u_linear_weightROM.sram_hi.mem_array[i-256] = {val[7:0], val[15:8]};
        end
        $fclose(fd);
    end
    endtask

    task load_sigmoid_lut;
        reg [31:0] hex_val;
    begin
        fd = $fopen({DATA_DIR, "Test\\sigmoid_lookup_table.txt"}, "r");
        if (fd == 0) begin $display("ERROR: sigmoid_lookup_table.txt"); $finish; end
        for (i = 0; i < 256; i++) begin
            status = $fscanf(fd, "%h", hex_val);
            dut.u_cnn.u_postprocess.u_postprocess_sigmoid.sram_inst0.mem_array[i] = hex_val;
            dut.u_cnn.u_postprocess.u_postprocess_sigmoid.sram_inst1.mem_array[i] = hex_val;
        end
        $fclose(fd);
    end
    endtask

    // =========================================================================
    // Expected outputs loading
    // =========================================================================
    task load_expected_outputs;
    begin
        load_exp_conv;
        load_exp_dwconv;
        load_exp_pwconv;
        load_exp_flatten;
        load_exp_linear;
        load_exp_sigmoid;
        $display("[LOAD] All expected intermediate outputs loaded.");
    end
    endtask

    task load_exp_conv;
    begin
        fd = $fopen({DATA_DIR, "Test\\Out_Conv.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Out_Conv.txt"); $finish; end
        for (i = 0; i < 32; i++)
            for (j = 0; j < 20; j++)
                for (k = 0; k < 4; k++) begin
                    status = $fscanf(fd, "%d", val);
                    exp_conv[i][j][k] = val[7:0];
                end
        $fclose(fd);
    end
    endtask

    task load_exp_dwconv;
    begin
        fd = $fopen({DATA_DIR, "Test\\Out_DWConv.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Out_DWConv.txt"); $finish; end
        for (i = 0; i < 32; i++)
            for (j = 0; j < 18; j++)
                for (k = 0; k < 2; k++) begin
                    status = $fscanf(fd, "%d", val);
                    exp_dwconv[i][j][k] = val[7:0];
                end
        $fclose(fd);
    end
    endtask

    task load_exp_pwconv;
    begin
        fd = $fopen({DATA_DIR, "Test\\Out_PWConv.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Out_PWConv.txt"); $finish; end
        for (i = 0; i < 32; i++)
            for (j = 0; j < 18; j++)
                for (k = 0; k < 2; k++) begin
                    status = $fscanf(fd, "%d", val);
                    exp_pwconv[i][j][k] = val[7:0];
                end
        $fclose(fd);
    end
    endtask

    task load_exp_flatten;
    begin
        fd = $fopen({DATA_DIR, "Test\\Out_Flatten.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Out_Flatten.txt"); $finish; end
        for (i = 0; i < 288; i++) begin
            status = $fscanf(fd, "%d", val);
            exp_flatten[i] = val[7:0];
        end
        $fclose(fd);
    end
    endtask

    task load_exp_linear;
    begin
        fd = $fopen({DATA_DIR, "Test\\Out_Linear.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Out_Linear.txt"); $finish; end
        for (i = 0; i < 2; i++) begin
            status = $fscanf(fd, "%d", val);
            exp_linear[i] = val[7:0];
        end
        $fclose(fd);
    end
    endtask

    task load_exp_sigmoid;
        real rval;
    begin
        fd = $fopen({DATA_DIR, "Test\\Out.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Out.txt"); $finish; end
        for (i = 0; i < 2; i++) begin
            status = $fscanf(fd, "%f", rval);
            exp_sigmoid[i] = rval;
        end
        $fclose(fd);
    end
    endtask

    task load_input_from_file;
        input string filename;
    begin
        fd = $fopen(filename, "r");
        if (fd == 0) begin $display("ERROR: Cannot open %s", filename); $finish; end
        for (i = 0; i < 30; i++)
            for (j = 0; j < 10; j++) begin
                status = $fscanf(fd, "%d", val);
                feature_map[i][j] = val[7:0];
            end
        $fclose(fd);
    end
    endtask

    // =========================================================================
    // === VERIFICATION LOGIC (Probes logic for whitebox verification) ===
    // =========================================================================

    reg [3:0] conv_verify_pos;
    reg [4:0] conv_verify_cnt;

    always @(posedge clk) begin
        if (dut.u_cnn.u_conv.valid_out) begin
            conv_verify_pos = dut.u_cnn.u_conv.pos_out;
            conv_verify_cnt = dut.u_cnn.u_conv.cnt_out;
            for (int r = 0; r < 4; r++) begin
                for (int c = 0; c < 4; c++) begin
                    automatic int exp_row = 2 * (conv_verify_pos - 1) + r;
                    automatic reg signed [7:0] got = dut.u_cnn.u_conv.output_data[r][c];
                    automatic reg signed [7:0] exp = exp_conv[conv_verify_cnt][exp_row][c] < 0? 0 : exp_conv[conv_verify_cnt][exp_row][c];
                    conv_checks = conv_checks + 1;
                    if (got !== exp) begin
                        conv_errors = conv_errors + 1;
                        if (conv_errors <= 20)
                            $display("[CONV MISMATCH] ch=%0d row=%0d col=%0d got=%0d exp=%0d",
                                     conv_verify_cnt, exp_row, c, got, exp);
                    end
                end
            end
        end
    end

    reg [4:0] pw_verify_cnt;
    reg [3:0] pw_verify_pos;

    always @(posedge clk) begin
        if (dut.u_cnn.u_pwconv.valid_out) begin
            pw_verify_cnt = dut.u_cnn.u_pwconv.cnt_out;
            pw_verify_pos = dut.u_cnn.u_pwconv.pos_out;
            begin
                automatic reg signed [7:0] g0 = dut.u_cnn.u_pwconv.output_data[0];
                automatic reg signed [7:0] g1 = dut.u_cnn.u_pwconv.output_data[1];
                automatic reg signed [7:0] g2 = dut.u_cnn.u_pwconv.output_data[2];
                automatic reg signed [7:0] g3 = dut.u_cnn.u_pwconv.output_data[3];
                automatic reg signed [7:0] e0 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos][0] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos][0];
                automatic reg signed [7:0] e1 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos][1] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos][1];
                automatic reg signed [7:0] e2 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][0] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][0];
                automatic reg signed[7:0] e3 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][1] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][1];
                pwconv_checks = pwconv_checks + 4;
                if (g0 !== e0) begin pwconv_errors = pwconv_errors + 1;
                    if (pwconv_errors <= 20) $display("[PW MISMATCH] ch=%0d pos=%0d [0] got=%0d exp=%0d", pw_verify_cnt, pw_verify_pos, g0, e0); end
                if (g1 !== e1) begin pwconv_errors = pwconv_errors + 1;
                    if (pwconv_errors <= 20) $display("[PW MISMATCH] ch=%0d pos=%0d [1] got=%0d exp=%0d", pw_verify_cnt, pw_verify_pos, g1, e1); end
                if (g2 !== e2) begin pwconv_errors = pwconv_errors + 1;
                    if (pwconv_errors <= 20) $display("[PW MISMATCH] ch=%0d pos=%0d [2] got=%0d exp=%0d", pw_verify_cnt, pw_verify_pos, g2, e2); end
                if (g3 !== e3) begin pwconv_errors = pwconv_errors + 1;
                    if (pwconv_errors <= 20) $display("[PW MISMATCH] ch=%0d pos=%0d [3] got=%0d exp=%0d", pw_verify_cnt, pw_verify_pos, g3, e3); end
            end
        end
    end

    reg [8:0] flatten_verify_iter;

    always @(posedge clk) begin
        if (dut.u_cnn.u_postprocess.u_postprocess_maxpool.iter_out !== 9'bx &&
            dut.u_cnn.u_postprocess.u_postprocess_maxpool.valid_out) begin
            flatten_verify_iter = dut.u_cnn.u_postprocess.u_postprocess_maxpool.iter_out;
            if (flatten_verify_iter < 288) begin
                automatic reg signed[7:0] got = dut.u_cnn.u_postprocess.u_postprocess_maxpool.data_out;
                automatic reg signed [7:0] exp = exp_flatten[flatten_verify_iter[8:5] + flatten_verify_iter[4:0]*9];
                flatten_checks = flatten_checks + 1;
                if (got !== exp) begin
                    flatten_errors = flatten_errors + 1;
                    if (flatten_errors <= 288)
                        $display("[FLATTEN MISMATCH] iter=%0d got=%0d exp=%0d",
                                 flatten_verify_iter, got, exp);
                end
            end
        end
    end

    reg linear_checked;
    always @(posedge clk) begin
        if (!rst_b) linear_checked <= 0;
        if (dut.u_cnn.u_postprocess.u_postprocess_sigmoid.valid && !linear_checked) begin
            linear_checked <= 1;
            begin
                automatic reg signed [7:0] got0 = dut.u_cnn.u_postprocess.u_postprocess_rescale.data_out0;
                automatic reg signed [7:0] got1 = dut.u_cnn.u_postprocess.u_postprocess_rescale.data_out1;
                $display("[LINEAR] Rescaled output: [%0d, %0d]  Expected: [%0d, %0d]",
                         got0, got1, exp_linear[0], exp_linear[1]);
                if (got0 == exp_linear[0] && got1 == exp_linear[1])
                    linear_pass = 1;
                else begin
                    linear_pass = 0;
                    $display("[LINEAR MISMATCH] got=[%0d,%0d] exp=[%0d,%0d]",
                             got0, got1, exp_linear[0], exp_linear[1]);
                end
            end
        end
    end

    // =========================================================================
    // Main test sequence
    // =========================================================================
    shortreal Sigmoid_decimal_val0;
    shortreal Sigmoid_decimal_val1;
    logic [31:0] tb_result0;
    logic[31:0] tb_result1;

    initial begin
        $display("================================================================");
        $display("  NanoCNN Layer-by-Layer Verification Testbench (Fully Serial IO)");
        $display("================================================================");

        // Init
        conv_errors = 0;    conv_checks = 0;
        dwconv_errors = 0;  dwconv_checks = 0;
        pwconv_errors = 0;  pwconv_checks = 0;
        flatten_errors = 0; flatten_checks = 0;
        linear_pass = 0;
        sigmoid_pass = 0;

        rst_b = 0; en = 0; start = 0;
        feature_in[0] = 0; feature_in[1] = 0; feature_in[2] = 0; feature_in[3] = 0;
        tb_result0 = 0; tb_result1 = 0;

        repeat(4) @(posedge clk);

        load_all_parameters;
        load_expected_outputs;

        rst_b = 1; en = 1;
        repeat(2) @(posedge clk);

        load_input_from_file({DATA_DIR, "Test\\Input.txt"});
        repeat(2) @(posedge clk);

        // Trigger start pulse
        @(posedge clk);
        start <= 1;
        @(posedge clk);
        start <= 0;
        
        $display("\n[TB] Processing started... Serial input data feeding active...\n");
        // Stream data features into the new TOP wrapper
        feed_features();

        // Wait for completion (Collect alternating 8 bytes driven by output logic)
        fork : wait_block
            begin 
                int b = 0;
                while (b < 8) begin
                    @(posedge clk);
                    if (done) begin
                        if (b == 0) tb_result0[7:0]   = result_byte;
                        if (b == 1) tb_result1[7:0]   = result_byte;
                        if (b == 2) tb_result0[15:8]  = result_byte;
                        if (b == 3) tb_result1[15:8]  = result_byte;
                        if (b == 4) tb_result0[23:16] = result_byte;
                        if (b == 5) tb_result1[23:16] = result_byte;
                        if (b == 6) tb_result0[31:24] = result_byte;
                        if (b == 7) tb_result1[31:24] = result_byte;
                        b++;
                    end
                end
            end
            begin #500000; $display("[TB] TIMEOUT!"); $finish; end
        join_any
        disable wait_block;

        repeat(4) @(posedge clk);

        Sigmoid_decimal_val0 = $bitstoshortreal(tb_result0);
        Sigmoid_decimal_val1 = $bitstoshortreal(tb_result1);
        $display("  Sigmoid: result0=0x%08h(%f)  result1=0x%08h(%f)", tb_result0, Sigmoid_decimal_val0, tb_result1, Sigmoid_decimal_val1);
        $display("[SIGMOID] Expected: %.6f and %.6f", exp_sigmoid[0], exp_sigmoid[1]);

        $display("\n================================================================");
        $display("  VERIFICATION SUMMARY");
        $display("================================================================");

        $display("  Conv   : %0d / %0d checks passed  (%0d errors)",
                 conv_checks - conv_errors, conv_checks, conv_errors);
        if (conv_errors == 0) $display("           >>> CONV PASS <<<");
        else                  $display("           >>> CONV FAIL <<<");

        $display("  PWConv : %0d / %0d checks passed  (%0d errors)",
                 pwconv_checks - pwconv_errors, pwconv_checks, pwconv_errors);
        if (pwconv_errors == 0) $display("           >>> PWCONV PASS <<<");
        else                    $display("           >>> PWCONV FAIL <<<");

        $display("  Flatten: %0d / %0d checks passed  (%0d errors)",
                 flatten_checks - flatten_errors, flatten_checks, flatten_errors);
        if (flatten_errors == 0) $display("           >>> FLATTEN PASS <<<");
        else                     $display("           >>> FLATTEN FAIL <<<");

        if (linear_pass) $display("  Linear : >>> PASS <<<");
        else             $display("  Linear : >>> FAIL <<<");

        $display("  Sigmoid: result0=0x%08h(%f)(expected: %.6f)  result1=0x%08h(%f)(expected: %.6f)", tb_result0, Sigmoid_decimal_val0, exp_sigmoid[0], tb_result1, Sigmoid_decimal_val1, exp_sigmoid[1]);

        $display("================================================================\n");
        $finish;
    end

    initial begin
        #2000000;
        $display("[TB] FATAL: Absolute timeout (2ms)!");
        $finish;
    end

    initial begin
        $dumpfile("cnn_tb.vcd");
        $dumpvars(0, CNN_tb);
    end

endmodule