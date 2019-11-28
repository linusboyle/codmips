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
// Module:  ctrl
// File:    ctrl.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: 控制模块，控制流水线的刷新、暂停等
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module ctrl(
	    input wire                                        rst,

	    input wire[31:0]             excepttype_i,
	    input wire[`RegBus]          cp0_epc_i,
	    input wire[`RegBus]          cp0_ebase_i,

	    input wire                   stallreq_from_id,
	    input wire                   stallreq_from_ex,
	    input wire                   stallreq_from_pc,

	    output reg[`RegBus]          new_pc,
	    output reg                   flush,
	    output reg[5:0]              stall
);

    always @ (*) begin
	if (rst == `RstEnable) begin
	    stall <= 6'b000000;
	    flush <= 1'b0;
	    new_pc <= `ZeroWord;
	end else if (excepttype_i != `ZeroWord) begin
	    flush <= 1'b1;
	    stall <= 6'b000000;
	    case (excepttype_i)
		32'h00000001:        begin   //interrupt
			// NOTE: assume Cause.iv equals 0
			new_pc <= {cp0_ebase_i[31:12], 12'h000} + 32'h00000180;
		    end
		32'h00000008, 32'h0000000a, 32'h0000000d, 32'h0000000c:        begin
			//syscall, inst_invalid, trap, ov.
			new_pc <= {cp0_ebase_i[31:12], 12'h000} + 32'h00000180;
		    end
		32'h0000000e:        begin   //eret
			new_pc <= cp0_epc_i;
		    end
		default: begin end
	    endcase
	end else if (stallreq_from_ex == `Stop) begin
	    stall <= 6'b001111;
	    flush <= 1'b0;
	end else if (stallreq_from_id == `Stop || stallreq_from_pc == `Stop) begin
	    stall <= 6'b000111;
	    flush <= 1'b0;
	end else begin
	    stall <= 6'b000000;
	    flush <= 1'b0;
	    new_pc <= `ZeroWord;
	end    //if
    end      //always


endmodule
