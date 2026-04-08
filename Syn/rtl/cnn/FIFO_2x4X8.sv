//simple fifo, which can be replaced by ip later

module FIFO_2x4X8 #(
    parameter DEPTH = 32
)(
    input  logic        clk,
    input  logic        rst_n,      // 异步复位
    input  logic        wr_en,      // 写使能
    input  logic        rd_en,      // 读使能
    input  logic [7:0]  wr_data[1:0][3:0],
    output logic [7:0]  rd_data[1:0][3:0]
);

localparam PTR_WIDTH = $clog2(DEPTH); // 指针宽度 5bit (0~31)

// 存储器数组
logic [7:0] fifo_mem[DEPTH][1:0][3:0];

// 读写指针
logic [PTR_WIDTH-1:0] wr_ptr;
logic [PTR_WIDTH-1:0] rd_ptr;

// -------------------------------------------------------------------------
// 核心操作逻辑
// -------------------------------------------------------------------------
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        wr_ptr <= '0;
        rd_ptr <= '0;
        // 可选：复位时清空输出数据
        foreach(rd_data[i,j]) rd_data[i][j] <= '0;
    end else begin
        
        // 写操作
        if (wr_en) begin
            fifo_mem[wr_ptr] <= wr_data;
            wr_ptr <= wr_ptr + 1'b1; // 指针自动循环 (0->1->...->31->0)
        end

        // 读操作
        if (rd_en) begin
            rd_data <= fifo_mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1; // 指针自动循环
        end
    end
end

endmodule