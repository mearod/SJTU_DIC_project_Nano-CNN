module CNN_Top (
    input clk,
    input rst_b,
    input en,
    input start,                              // pulse to begin processing
    input signed [7:0] feature_in [3:0],      // 4 bytes per cycle (reduced IO)

    output logic done,                        // high for 8 cycles when outputting result
    output logic [7:0] result_byte            // 1 byte per cycle, alternating result0 and result1
);

    // =========================================================================
    // Master controller for Input Phase
    // =========================================================================
    logic [8:0] master_cnt;
    logic active;

    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            active <= 0;
            master_cnt <= 0;
        end else if (start) begin
            active <= 1;
            master_cnt <= 0;
        end else if (active && en) begin
            if (master_cnt == 500)    // Wait until entire input shifting phase is gracefully done
                active <= 0;
            else
                master_cnt <= master_cnt + 1;
        end
    end

    // =========================================================================
    // Shift Register and Holding Register for 120-Byte Input Window
    // =========================================================================
    logic signed [7:0] flat_shift_reg[0:119];
    logic signed [7:0] flat_holding_reg [0:119];

    logic [4:0] word_idx;
    assign word_idx = master_cnt % 32;

    // Shift in 4 bytes per cycle. We shift during the first 30 cycles of each 32-cycle block
    always_ff @(posedge clk) begin
        if (active && word_idx < 30 && master_cnt < 320 && en) begin
            flat_shift_reg[word_idx*4 + 0] <= feature_in[0];
            flat_shift_reg[word_idx*4 + 1] <= feature_in[1];
            flat_shift_reg[word_idx*4 + 2] <= feature_in[2];
            flat_shift_reg[word_idx*4 + 3] <= feature_in[3];
        end
    end

    // Transfer Shift-Reg -> Holding-Reg exactly at the boundary before 'cnn' needs the next window
    always_ff @(posedge clk) begin
        if (active && word_idx == 31 && master_cnt < 320 && en) begin
            for (int i = 0; i < 120; i++) begin
                flat_holding_reg[i] <= flat_shift_reg[i];
            end
        end
    end

    // Generate internal start for cnn module exactly when the first 120-bytes block is ready
    logic cnn_start;
    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) 
            cnn_start <= 0;
        else if (active && master_cnt == 30 && en) 
            cnn_start <= 1;
        else 
            cnn_start <= 0;
    end

    // =========================================================================
    // Remap flat 120 bytes into 12x10 interface for cnn perspective matching
    // =========================================================================
    wire signed [7:0] cnn_feature_window [11:0][9:0];
    genvar r, c;
    generate
        for (r = 0; r < 12; r++) begin : gen_r
            for (c = 0; c < 10; c++) begin : gen_c
                assign cnn_feature_window[r][c] = flat_holding_reg[r * 10 + c];
            end
        end
    endgenerate

    // =========================================================================
    // Instantiate original cnn layer
    // =========================================================================
    wire cnn_done;
    wire [31:0] cnn_result0;
    wire [31:0] cnn_result1;

    cnn u_cnn (
        .clk(clk),
        .rst_b(rst_b),
        .en(en),
        .start(cnn_start),
        .feature_window(cnn_feature_window),
        .done(cnn_done),
        .result0(cnn_result0),
        .result1(cnn_result1)
    );

    // =========================================================================
    // Output State Machine (Serialize 64-bit to 8-bit over 8 cycles)
    // =========================================================================
    logic out_active;
    logic [3:0] out_cnt;
    logic [31:0] reg_result0;
    logic [31:0] reg_result1;

    always_ff @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            out_active  <= 0;
            out_cnt     <= 0;
            reg_result0 <= 0;
            reg_result1 <= 0;
            done        <= 0;
            result_byte <= 0;
        end else if (cnn_done && en) begin
            // 捕获脉冲信号和浮点结果
            reg_result0 <= cnn_result0;
            reg_result1 <= cnn_result1;
            out_active  <= 1;
            out_cnt     <= 0;
            done        <= 1;
            // 立即输出第一个字节 (result0 的低8位)
            result_byte <= cnn_result0[7:0]; 
        end else if (out_active && en) begin
            if (out_cnt == 4'd7) begin
                out_active  <= 0;
                done        <= 0;
                result_byte <= 0;
            end else begin
                out_cnt <= out_cnt + 1;
                done    <= 1;
                // 轮流逐字节输出
                case (out_cnt + 1)
                    4'd1: result_byte <= reg_result1[7:0];
                    4'd2: result_byte <= reg_result0[15:8];
                    4'd3: result_byte <= reg_result1[15:8];
                    4'd4: result_byte <= reg_result0[23:16];
                    4'd5: result_byte <= reg_result1[23:16];
                    4'd6: result_byte <= reg_result0[31:24];
                    4'd7: result_byte <= reg_result1[31:24];
                    default: result_byte <= 8'd0;
                endcase
            end
        end else if (!out_active) begin
            done        <= 0;
            result_byte <= 0;
        end
    end

endmodule