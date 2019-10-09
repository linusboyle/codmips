`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/09 12:18:07
// Design Name: 
// Module Name: testbench
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


module testbench;
     reg clk;
     reg rst;
     reg[15:0] inputSW;
     wire[15:0] outputSW;
     wire[1:0] st;
     
     automata alu(.clk(clk), .rst(rst), .inputSW(inputSW), .outputSW(outputSW), .st(st));
     
     initial begin
     	clk = 0;
     	forever #50 clk = ~clk;
     end
     
     initial begin
     	rst = 1;
     	inputSW = 16'he404;
     	
     	#200
     	rst = 0;
     	
     	#100
     	inputSW = 16'h000f;
     	
     	#100
     	inputSW = 16'h000a;
     end

endmodule
