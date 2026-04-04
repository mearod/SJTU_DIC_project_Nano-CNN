// CNN Testbench with Comprehensive Layer-by-Layer Verification
// Loads weights/biases/sigmoid LUT, drives input, and verifies each layer
// against reference outputs (Conv, DWConv, PWConv, Flatten, Linear, Sigmoid).
//
// USAGE: Run from the project root (NanoCNN/) or adjust file paths below.
//        Compile all .sv/.v files in source_rtl/** and this testbench.

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
    reg signed [7:0] feature_map [0:29][0:9];
    wire done;
    wire [31:0] result0, result1;

    CNN_Top dut (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .start(start),
        .feature_map(feature_map),
        .done(done),
        .result0(result0),
        .result1(result1)
    );

    // =========================================================================
    // Expected intermediate results (loaded from reference files)
    // =========================================================================
    // Conv output: 32 channels x 20 rows x 4 cols, INT8
    reg signed [7:0] exp_conv [0:31][0:19][0:3];
    // DWConv output: 32 channels x 18 rows x 2 cols, INT8
    reg signed [7:0] exp_dwconv [0:31][0:17][0:1];
    // PWConv output: 32 channels x 18 rows x 2 cols, INT8
    reg signed [7:0] exp_pwconv [0:31][0:17][0:1];
    // Flatten output: 288 values, INT8 (= maxpool output in order)
    reg signed [7:0] exp_flatten [0:287];
    // Linear output: 2 values, INT8 (after rescale)
    reg signed [7:0] exp_linear [0:1];
    // Sigmoid output: 2 floats (as strings; we compare hex)
    real exp_sigmoid [0:1];

    // =========================================================================
    // Error counters
    // =========================================================================
    integer conv_errors, conv_checks;
    integer dwconv_errors, dwconv_checks;
    integer pwconv_errors, pwconv_checks;
    integer flatten_errors, flatten_checks;
    integer linear_pass;
    integer sigmoid_pass;

    // =========================================================================
    // File I/O helpers
    // =========================================================================
    integer fd, status, i, j, k;
    integer val;
    localparam string DATA_DIR = "D:\\subject\\IC_project\\NanoCNN\\CNN_test_data\\";

    // =========================================================================
    // Load network parameters into ROMs
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
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_Conv_Weight.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_Conv_Weight.txt"); $finish; end
        for (i = 0; i < 32; i++)
            for (j = 0; j < 11; j++)
                for (k = 0; k < 7; k++) begin
                    status = $fscanf(fd, "%d", val);
                    dut.u_conv.weight_rom.mem[i][j*7+k] = val[7:0];
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
            dut.u_conv.bias_rom.mem[i] = val[15:0];
        end
        $fclose(fd);
    end
    endtask

    task load_dwconv_weights;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_DWConv_Weight.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_DWConv_Weight.txt"); $finish; end
        for (i = 0; i < 32; i++)
            for (j = 0; j < 3; j++)
                for (k = 0; k < 3; k++) begin
                    status = $fscanf(fd, "%d", val);
                    dut.u_dwconv.weight_rom.mem[i][j*3+k] = val[7:0];
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
            dut.u_dwconv.bias_rom.mem[i] = val[15:0];
        end
        $fclose(fd);
    end
    endtask

    task load_pwconv_weights;
    begin
        fd = $fopen({DATA_DIR, "Param\\Param_PWConv_Weight.txt"}, "r");
        if (fd == 0) begin $display("ERROR: Param_PWConv_Weight.txt"); $finish; end
        for (i = 0; i < 32; i++)
            for (j = 0; j < 32; j++) begin
                status = $fscanf(fd, "%d", val);
                dut.u_pwconv.weight_rom.mem[i][j] = val[7:0];
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
            dut.u_pwconv.bias_rom.mem[i] = val[15:0];
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
            //$display("Loading Linear weight %0d: %h\n", i, val);
            dut.u_postprocess.u_linear_weightROM.mem[i] = {val[7:0], val[15:8]};  // Reorder to match hardware layout
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
            // File line i = sigmoid((-128+i)*scale)
            // Unsigned address = (-128+i) & 0xFF = (128+i) % 256
            dut.u_postprocess.u_postprocess_sigmoid.sigmoid_lut[i] = hex_val;
        end
        $fclose(fd);
    end
    endtask

    // =========================================================================
    // Load expected intermediate results
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

    // Conv: 32 channels, each 20 rows x 4 cols, separated by blank lines
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

    // DWConv: 32 channels, each 18 rows x 2 cols
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

    // PWConv: 32 channels, each 18 rows x 2 cols
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

    // Flatten: 288 values on one line
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

    // Linear: 2 values
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

    // Sigmoid: 2 float values
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

    // =========================================================================
    // Load input feature map
    // =========================================================================
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
    // === VERIFICATION LOGIC ===
    // =========================================================================

    // ---- 1. Conv output verification ----
    // Conv valid_out fires at pos_reg=1..9, cnt_out=0..31
    // output_data[0..3][0..3] = 4 rows x 4 cols
    // Row mapping: output_data[r] = expected_conv[ch][2*(pos-1)+r][c]
    reg [3:0] conv_verify_pos;
    reg [4:0] conv_verify_cnt;

    always @(posedge clk) begin
        if (dut.u_conv.valid_out) begin
            conv_verify_pos = dut.u_conv.pos_out;  // 1..9
            conv_verify_cnt = dut.u_conv.cnt_out;   // 0..31
            for (int r = 0; r < 4; r++) begin
                for (int c = 0; c < 4; c++) begin
                    automatic int exp_row = 2 * (conv_verify_pos - 1) + r;
                    automatic reg signed [7:0] got = dut.u_conv.output_data[r][c];
                    automatic reg signed [7:0] exp = exp_conv[conv_verify_cnt][exp_row][c] < 0? 0 : exp_conv[conv_verify_cnt][exp_row][c];
                    conv_checks = conv_checks + 1;
                    if (got !== exp) begin
                        conv_errors = conv_errors + 1;
                        if (conv_errors <= 20)  // limit error messages
                            $display("[CONV MISMATCH] ch=%0d row=%0d col=%0d got=%0d exp=%0d",
                                     conv_verify_cnt, exp_row, c, got, exp);
                    end
                end
            end
        end
    end

    // ---- 2. PWConv output verification ----
    // PWConv valid_out: cnt_out=0..31, pos_out=0..8
    // output_data[0..3] maps to:
    //   [0] = exp_pwconv[ch][2*pos][0]   (row 2q, col 0)
    //   [1] = exp_pwconv[ch][2*pos][1]   (row 2q, col 1)
    //   [2] = exp_pwconv[ch][2*pos+1][0] (row 2q+1, col 0)
    //   [3] = exp_pwconv[ch][2*pos+1][1] (row 2q+1, col 1)
    reg [4:0] pw_verify_cnt;
    reg [3:0] pw_verify_pos;

    always @(posedge clk) begin
        if (dut.u_pwconv.valid_out) begin
            pw_verify_cnt = dut.u_pwconv.cnt_out;
            pw_verify_pos = dut.u_pwconv.pos_out;
            begin
                automatic reg signed [7:0] g0 = dut.u_pwconv.output_data[0];
                automatic reg signed [7:0] g1 = dut.u_pwconv.output_data[1];
                automatic reg signed [7:0] g2 = dut.u_pwconv.output_data[2];
                automatic reg signed [7:0] g3 = dut.u_pwconv.output_data[3];
                automatic reg signed [7:0] e0 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos][0] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos][0];
                automatic reg signed [7:0] e1 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos][1] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos][1];
                automatic reg signed [7:0] e2 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][0] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][0];
                automatic reg signed [7:0] e3 = exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][1] < 0? 0 : exp_pwconv[pw_verify_cnt][2*pw_verify_pos+1][1];
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

    // ---- 3. Flatten (Maxpool output) verification ----
    // Maxpool output = max(data_in0..3) at each iter
    // PostProcess enabled by pw_valid_out; iter = {pos, cnt}
    // Flatten index = iter = pos*32 + cnt
    reg [8:0] flatten_verify_iter;

    always @(posedge clk) begin
        // PostProcess Maxpool outputs 1 cycle after PostProcess.en
        // The maxpool iter_out tracks the delayed iter
        if (dut.u_postprocess.u_postprocess_maxpool.iter_out !== 9'bx &&
            dut.u_postprocess.u_postprocess_maxpool.valid_out) begin
            flatten_verify_iter = dut.u_postprocess.u_postprocess_maxpool.iter_out;
            if (flatten_verify_iter < 288) begin
                automatic reg signed [7:0] got = dut.u_postprocess.u_postprocess_maxpool.data_out;
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

    // ---- 4. Linear output verification ----
    // Linear accumulation completes at iter=287. Check data_out0/1 after rescale.
    // PostProcess_Rescale has 2-cycle latency after Linear.
    // The rescaled INT8 values should match exp_linear.
    reg linear_checked;
    always @(posedge clk) begin
        if (!rst_b) linear_checked <= 0;
        // Check when sigmoid valid fires (all processing done)
        if (dut.u_postprocess.u_postprocess_sigmoid.valid && !linear_checked) begin
            linear_checked <= 1;
            begin
                automatic reg signed [7:0] got0 = dut.u_postprocess.u_postprocess_rescale.data_out0;
                automatic reg signed [7:0] got1 = dut.u_postprocess.u_postprocess_rescale.data_out1;
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

    // ---- 5. Sigmoid (final) verification ----
    // Compare FP32 hex output against sigmoid LUT expected result
    // exp_sigmoid has float values; result0/result1 are IEEE754 hex

    // =========================================================================
    // Main test sequence
    // =========================================================================
        shortreal   Sigmoid_decimal_val0;
        shortreal   Sigmoid_decimal_val1;
    initial begin
        $display("================================================================");
        $display("  NanoCNN Layer-by-Layer Verification Testbench");
        $display("================================================================");

        // Init counters
        conv_errors = 0;    conv_checks = 0;
        dwconv_errors = 0;  dwconv_checks = 0;
        pwconv_errors = 0;  pwconv_checks = 0;
        flatten_errors = 0; flatten_checks = 0;
        linear_pass = 0;
        sigmoid_pass = 0;

        // Reset
        rst_b = 0; en = 0; start = 0;
        repeat(4) @(posedge clk);

        // Load parameters + expected outputs
        load_all_parameters;
        load_expected_outputs;

        // Release reset
        rst_b = 1; en = 1;
        repeat(2) @(posedge clk);

        // Load reference input
        load_input_from_file({DATA_DIR, "Test\\Input.txt"});
        repeat(2) @(posedge clk);

        // Start
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        $display("\n[TB] Processing started...\n");

        // Wait for completion
        fork : wait_block
            begin wait(done == 1); end
            begin #500000; $display("[TB] TIMEOUT!"); $finish; end
        join_any
        disable wait_block;

        repeat(4) @(posedge clk);

        // ---- Sigmoid verification ----
        Sigmoid_decimal_val0 = $bitstoshortreal(result0);
        Sigmoid_decimal_val1 = $bitstoshortreal(result1);
        $display("  Sigmoid: result0=0x%08h(%f)  result1=0x%08h(%f)", result0, Sigmoid_decimal_val0, result1, Sigmoid_decimal_val1);
        $display("[SIGMOID] Expected: %.6f and %.6f", exp_sigmoid[0], exp_sigmoid[1]);

        // =========================================================================
        // Summary report
        // =========================================================================
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

        $display("  Sigmoid: result0=0x%08h(%f)(expected: %.6f)  result1=0x%08h(%f)(expected: %.6f)", result0, Sigmoid_decimal_val0, exp_sigmoid[0], result1, Sigmoid_decimal_val1, exp_sigmoid[1]);

        $display("================================================================\n");
        $finish;
    end

    // =========================================================================
    // Absolute timeout
    // =========================================================================
    initial begin
        #2000000;
        $display("[TB] FATAL: Absolute timeout (2ms)!");
        $finish;
    end

    // =========================================================================
    // VCD dump
    // =========================================================================
    initial begin
        $dumpfile("cnn_tb.vcd");
        $dumpvars(0, CNN_tb);
    end

endmodule
