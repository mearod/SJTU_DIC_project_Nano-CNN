module DWconv_BiasRom (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,       // 地址宽度 5bit (0~31)
    input  logic        en,         // 使能信号
    output logic [7:0] data_out // 输出 1 个 8-bit bias
);

endmodule