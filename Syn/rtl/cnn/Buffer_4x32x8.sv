module Buffer_4x32x8 #(
    parameter CHANNELS = 32,
    parameter DATA_W   = 8
)(
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     wr_en,
    
    // 输入：上一层输出的 1个通道 的 2x2 数据
    input  logic [DATA_W-1:0]        wr_data[1:0][1:0],
    
    // 输出：给逐点卷积的 4个位置 x 32个通道 的数据
    // 4个位置对应原来的 2x2 (展开为 [0:3])
    output logic [DATA_W-1:0]        rd_data[3:0][CHANNELS-1:0]
);

localparam PTR_W = $clog2(CHANNELS);

// -------------------------------------------------------------------------
// 存储体定义 (2个Bank, 寄存器堆结构)
// mem[bank][channel][y][x]
// -------------------------------------------------------------------------
logic [DATA_W-1:0] mem[2][CHANNELS][1:0][1:0];

// -------------------------------------------------------------------------
// 控制信号
// -------------------------------------------------------------------------
logic [PTR_W-1:0]    wr_addr;    // 写地址 (当前写入的通道号)
logic                 bank_sel;   // Bank选择: 0=写, 1=读 (反之亦然)

// -------------------------------------------------------------------------
// 1. 写地址与Bank切换控制
// -------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_addr  <= '0;
        bank_sel <= '0;
    end else if (wr_en) begin
        if (wr_addr == CHANNELS - 1) begin
            wr_addr  <= '0;
            bank_sel <= ~bank_sel; // 写满32通道，切换读写角色
        end else begin
            wr_addr <= wr_addr + 1'b1;
        end
    end
end

// -------------------------------------------------------------------------
// 2. 写操作 (串行写入)
// -------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (wr_en) begin
        // 将当前通道的 2x2 数据写入指定 Bank
        mem[bank_sel][wr_addr] <= wr_data;
    end
end

// -------------------------------------------------------------------------
// 3. 读操作 (全并行输出，组合逻辑)
// -------------------------------------------------------------------------
// 核心改动：一次性读出另一个Bank中所有32个通道的数据
// 并将 2x2 的空间维度展开为 4，映射到输出的 [3:0]
always_comb begin
    // 遍历 32 个通道
    for (int c = 0; c < CHANNELS; c++) begin
        // 位置映射:
        // rd_data[0] = (y=0, x=0)
        // rd_data[1] = (y=0, x=1)
        // rd_data[2] = (y=1, x=0)
        // rd_data[3] = (y=1, x=1)
        rd_data[0][c] = mem[~bank_sel][c][0][0];
        rd_data[1][c] = mem[~bank_sel][c][0][1];
        rd_data[2][c] = mem[~bank_sel][c][1][0];
        rd_data[3][c] = mem[~bank_sel][c][1][1];
    end
end

endmodule