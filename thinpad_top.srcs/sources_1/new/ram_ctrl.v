`timescale 1ns / 1ps
`include "defines.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/22 16:05:26
// Design Name: 
// Module Name: ram_ctrl
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


module ram_ctrl(
	input wire rst,

        input wire[`InstAddrBus] pc_addr,
        input wire pc_ce,
        output wire[`InstBus] pc_data,

        input wire[`InstAddrBus] mem_addr,
        input wire mem_ce,
        input wire mem_we,
        input wire[`RegBus] mem_data_i,
        input wire[3:0] mem_sel,
        output wire[`InstBus] mem_data_o,

        //BaseRAM信号
        inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
        output reg[19:0] base_ram_addr, //BaseRAM地址
        output reg[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
        output reg base_ram_ce_n,       //BaseRAM片选，低有效
        output reg base_ram_oe_n,       //BaseRAM读使能，低有效
        output reg base_ram_we_n,       //BaseRAM写使能，低有效

        //ExtRAM信号
        inout wire[31:0] ext_ram_data,  //ExtRAM数据
        output reg[19:0] ext_ram_addr, //ExtRAM地址
        output reg[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
        output reg ext_ram_ce_n,       //ExtRAM片选，低有效
        output reg ext_ram_oe_n,       //ExtRAM读使能，低有效
        output reg ext_ram_we_n       //ExtRAM写使能，低有效
    );

    wire mem_oe, sel;
    wire [`InstBus] pc_bus, mem_bus;
    reg [`InstBus] base_bus, ext_bus;
    reg base_wr, ext_wr;
	
    assign base_ram_data = base_wr ? base_bus : 32'bz;
    assign ext_ram_data = ext_wr ? ext_bus : 32'bz;

    assign mem_oe = mem_ce & ~mem_we;
    assign sel = mem_we & mem_ce ? ~mem_sel : 4'b0;

    assign pc_bus = pc_addr[22] ? ext_ram_data : base_ram_data; 
    assign mem_bus = mem_addr[22] ? ext_ram_data : base_ram_data; 

    assign pc_data = pc_ce ? pc_bus : `ZeroWord;
    assign mem_data_o = mem_oe ? mem_bus : `ZeroWord;

    always @ (*) begin
	base_ram_ce_n <= 1'b1;
	base_ram_we_n <= 1'b1;
	base_ram_oe_n <= 1'b1;
	base_ram_be_n <= 4'b0;

	ext_ram_ce_n <= 1'b1;
	ext_ram_we_n <= 1'b1;
	ext_ram_oe_n <= 1'b1;
	ext_ram_be_n <= 4'b0;

	base_wr <= 1'b0;
	ext_wr <= 1'b0;
	if (rst != `RstEnable) begin
	    // from mem period
	    if (mem_ce == `ChipEnable) begin
		if (mem_addr[22] == 1'b1) begin
		    // extra ram
		    ext_ram_ce_n <= 1'b0;
		    if (mem_we == `WriteEnable) begin
			ext_ram_we_n <= 1'b0;
			ext_wr <= 1'b1;
			ext_ram_be_n <= sel;
			ext_ram_oe_n <= 1'b1;
			ext_bus <= mem_data_i;
		    end else begin
			ext_ram_we_n <= 1'b1;
			ext_wr <= 1'b0;
			ext_ram_oe_n <= 1'b0;
		    end
		    ext_ram_addr <= mem_addr[21:2];
		end else begin
		    // base ram
		    base_ram_ce_n <= 1'b0;
		    if (mem_we == `WriteEnable) begin
			base_ram_we_n <= 1'b0;
			base_wr <= 1'b1;
			base_ram_be_n <= sel;
			base_ram_oe_n <= 1'b1;
			base_bus <= mem_data_i;
		    end else begin
			base_ram_we_n <= 1'b1;
			base_wr <= 1'b0;
			base_ram_oe_n <= 1'b0;
		    end
		    base_ram_addr <= mem_addr[21:2];
		end
	    end

	    if (pc_ce == `ChipEnable) begin
		if (pc_addr[22] == 1'b1) begin
		    ext_ram_ce_n <= 1'b0;
		    ext_ram_oe_n <= 1'b0;
		    ext_ram_addr <= pc_addr[21:2];
		end else begin
		    base_ram_ce_n <= 1'b0;
		    base_ram_oe_n <= 1'b0;
		    base_ram_addr <= pc_addr[21:2];
		end
	    end
	end
    end
endmodule
