//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2014 leishangwen@163.com                       ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
// Module:  pc_reg
// File:    pc_reg.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: 指令指针寄存器PC
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module pc_reg(

    input wire clk,
    input wire rst,

	// 来自控制模块的信息（组合输出）
    input wire[5:0] stall,
    input wire flush,
    input wire[`RegBus] new_pc,

    // 来自译码阶段的信息（组合输出）
    input wire branch_flag_i,
    input wire[`RegBus] branch_target_address_i,

    // 来自访存阶段的信息（寄存器输出）
    input wire[`AluOpBus] mem_aluop,
    input wire[`DataAddrBus] mem_mem_addr,

    // 输出
    output wire stallreq,
    output reg[`InstAddrBus] pc,
    output wire ce
	
);
    reg reg_ce;

    assign ce = reg_ce && (mem_aluop[7:5] != `EXE_RES_LOAD_STORE || mem_mem_addr[22] != pc[22]);
    assign stallreq = !ce;

	always @ (posedge clk) begin
		if (reg_ce == `ChipDisable) begin
			pc <= `ZeroWord;
		end else begin
			if(flush == `True_v) begin
				pc <= new_pc;
			end else if(stall[0] == `NoStop) begin
				if(branch_flag_i == `Branch) begin
					pc <= branch_target_address_i;
				end else begin
                    pc <= pc + 4'h4;
                end
			end
		end
	end

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			reg_ce <= `ChipDisable;
        end else begin
			reg_ce <= `ChipEnable;
		end
	end

endmodule
