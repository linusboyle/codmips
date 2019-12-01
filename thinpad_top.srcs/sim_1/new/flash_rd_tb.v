`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/12/01 11:03:48
// Design Name: 
// Module Name: flash_rd_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module flash_rd_tb;

wire [22:0]flash_a;      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
wire [15:0]flash_d;      //Flash数据
wire flash_rp_n;         //Flash复位信号，低有效
wire flash_vpen;         //Flash写保护信号，低电平时不能擦除、烧写
wire flash_ce_n;         //Flash片选信号，低有效
wire flash_oe_n;         //Flash读使能信号，低有效
wire flash_we_n;         //Flash写使能信号，低有效
wire flash_byte_n;       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

parameter FLASH_INIT_FILE = "/tmp/flash.bin";    //Flash初始化文件，请修改为实际的绝对路径

// Flash 仿真模型
x28fxxxp30 #(.FILENAME_MEM(FLASH_INIT_FILE)) flash(
    .A(flash_a[1+:22]), 
    .DQ(flash_d), 
    .W_N(flash_we_n),    // Write Enable 
    .G_N(flash_oe_n),    // Output Enable
    .E_N(flash_ce_n),    // Chip Enable
    .L_N(1'b0),    // Latch Enable
    .K(1'b0),      // Clock
    .WP_N(flash_vpen),   // Write Protect
    .RP_N(flash_rp_n),   // Reset/Power-Down
    .VDD('d3300), 
    .VDDQ('d3300), 
    .VPP('d1800), 
    .Info(1'b1));
    
wire clk_50M, clk_11M0592;
// 时钟源
clock osc(
    .clk_11M0592(clk_11M0592),
    .clk_50M    (clk_50M)
);

wire [31:0] data, addr;
wire [3:0] sel;
wire done;

reg rst;
bios test (
	.rst(rst),
	.clk(clk_11M0592),
	.flash_a(flash_a),    //Flash地址，a0仅在8bit模式有效，16bit模式无意义
	.flash_d(flash_d),    //Flash数据
	.flash_rp_n(flash_rp_n),        //Flash复位信号，低有效
	.flash_vpen(flash_vpen),        //Flash写保护信号，低电平时不能擦除、烧写
	.flash_ce_n(flash_ce_n),         //Flash片选信号，低有效
	.flash_oe_n(flash_oe_n),        //Flash读使能信号，低有效
	.flash_we_n(flash_we_n),         //Flash写使能信号，低有效
	.flash_byte_n(flash_byte_n),       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1
	.data(data),
	.addr(addr),
	.sel(sel),
	.done(done)
);

initial begin
	rst = 1'b1;
	
	#400
	rst = 1'b0;
end
endmodule
