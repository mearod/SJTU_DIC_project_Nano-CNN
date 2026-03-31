module Conv_WeightROM (
    input  logic        clk,
    input  logic        rst_b,
    input  logic [4:0]  addr,       // 地址宽度 5bit (0~31)
    input  logic        en,         // 使能信号
    output logic [0:77*8-1] data_out // 输出 77 个 8-bit 权重的扁平化数组
);

endmodule