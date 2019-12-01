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
		output reg ext_ram_we_n,       //ExtRAM写使能，低有效

		output reg uart_rdn,         //读串口信号，低有效
		output reg uart_wrn,         //写串口信号，低有效
		input wire uart_dataready,   //串口数据准备好
		input wire uart_tbre,        //发送数据标志
		input wire uart_tsre,        //数据发送完毕标志

		output wire[5:0] int_o,

		input wire flash_done,
		input wire[31:0] flash_data,
		input wire[31:0] flash_addr,
		input wire[3:0] flash_sel
);

    wire mem_oe,
	sel;

    reg[`InstBus] pc_bus,
	mem_bus;
    reg[`InstBus] base_bus,
	ext_bus;
    reg base_wr,
	ext_wr;

    wire[7:0] uart_data;
    wire[31:0] uart_status;

    assign base_ram_data = base_wr ? base_bus : 32'bz;
    assign ext_ram_data = ext_wr ? ext_bus : 32'bz;
    assign uart_data = base_ram_data[7:0];
    assign uart_status = {30'h0, uart_dataready, uart_tsre & uart_tbre};

    assign mem_oe = mem_ce & ~mem_we;
    assign sel = mem_we & mem_ce ? ~mem_sel : 4'b0;

    assign pc_data = pc_ce ? pc_bus : `ZeroWord;
    assign mem_data_o = mem_oe ? mem_bus : `ZeroWord;

    // No.2 hardware interrupt
    assign int_o = {3'b000, uart_dataready, 2'b00};

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

	uart_rdn <= 1'b1;
	uart_wrn <= 1'b1;
	if (rst != `RstEnable) begin
	    if (flash_done == 1'b0) begin
		// bootstrap
		base_ram_ce_n <= 1'b0;
		base_ram_we_n <= 1'b0;
		base_wr <= 1'b1;
		base_bus <= flash_data;
		base_ram_addr <= flash_addr[21:2];
		base_ram_be_n <= ~flash_sel;
	    end else begin
		// from mem period
		if (mem_ce == `ChipEnable) begin
		    if (mem_addr == 32'hBFD003FC) begin
			// uart status
			if (mem_we == `WriteDisable) begin
			    // read
			    mem_bus <= uart_status;
			end
		    end else if (mem_addr == 32'hBFD003F8) begin
			// uart data
			if (mem_we == `WriteEnable) begin
			    // write uart
			    base_bus <= {24'b0, mem_data_i[7:0]};
			    base_wr <= 1'b1;
			    base_ram_ce_n <= 1'b1;
			    uart_wrn <= 1'b0;
			    uart_rdn <= 1'b1;
			end else begin
			    // read uart
			    base_wr <= 1'b0;
			    base_ram_ce_n <= 1'b1;
			    uart_wrn <= 1'b1;
			    uart_rdn <= 1'b0;
			    mem_bus <= uart_data;
			end
		    end else if (mem_addr[22] == 1'b1) begin
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
			mem_bus <= ext_ram_data;
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
			mem_bus <= base_ram_data;
		    end
		end

		if (pc_ce == `ChipEnable) begin
		    if (pc_addr[22] == 1'b1) begin
			ext_wr <= 1'b0;
			ext_ram_ce_n <= 1'b0;
			ext_ram_oe_n <= 1'b0;
			ext_ram_we_n <= 1'b1;
			ext_ram_addr <= pc_addr[21:2];
			pc_bus <= ext_ram_data;
		    end else begin
			base_wr <= 1'b0;
			base_ram_ce_n <= 1'b0;
			base_ram_oe_n <= 1'b0;
			base_ram_we_n <= 1'b1;
			base_ram_addr <= pc_addr[21:2];
			pc_bus <= base_ram_data;
		    end
		end
	    end
	end
    end
endmodule
