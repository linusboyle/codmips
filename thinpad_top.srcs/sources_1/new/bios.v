`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/30 15:39:35
// Design Name: 
// Module Name: bios
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

`include "defines.v"

module bios(
	input wire rst,
	input wire clk,

	output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
	inout  wire [15:0]flash_d,      //Flash数据
	output wire flash_rp_n,         //Flash复位信号，低有效
	output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
	output reg flash_ce_n,         //Flash片选信号，低有效
	output reg flash_oe_n,         //Flash读使能信号，低有效
	output reg flash_we_n,         //Flash写使能信号，低有效
	output wire flash_byte_n,       //Flash 8bit模式选择，低有效.在使用flash的16位模式时请设为1

	output wire[31:0] data,
	output wire[31:0] addr,
	output reg[3:0] sel,

	output reg done
    );

    assign flash_vpen = 1'b0; // read only
    assign flash_rp_n = 1'b1;
    assign flash_byte_n = 1'b1; // 16bit mode

    reg [20:0] flash_addr;  // the addr to read
    assign flash_a = {1'b0, flash_addr, 1'b0};

    reg flash_rd;
    assign flash_d = flash_rd ? 16'hz : 16'h0000; // data read out from flash

    reg [15:0] bus; // data sent to baseram

    assign data = sel == 4'b0011 ? {16'b0, bus} : {bus, 16'b0};
    reg [20:0] addr_buf; // the addr written to
    assign addr = {10'b0, addr_buf, 1'b0};

    always @ (posedge clk) begin
	if (rst == `RstEnable) begin
	    flash_ce_n <= 1'b0;
	    flash_oe_n <= 1'b0;
	    flash_we_n <= 1'b1;
	    flash_addr <= 21'b000000000000000000000;
	    flash_rd <= 1'b1;
	    done <= 1'b0;
	    bus <= 16'h0000;
	    sel <= 4'b1100;
	    addr_buf <= 21'b0;
	end else begin
	    if (addr_buf == 21'b000000000111111111111) begin // only copy 4k * 16bit data
		done <= 1'b1;
		flash_ce_n <= 1'b1;
		flash_rd <= 1'b0;
		flash_oe_n <= 1'b1;
	    end else begin
		// give the read bits to baseram
		sel <= ~sel;
		bus <= flash_d;
		addr_buf <= flash_addr;

		// read the next 16 bit
		flash_addr <= flash_addr + 1;
		flash_rd <= 1'b1;
		flash_ce_n <= 1'b0;
		flash_oe_n <= 1'b0;
	    end
	end
    end
endmodule
