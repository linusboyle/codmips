`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/23 16:22:26
// Design Name: 
// Module Name: mem_model_tb
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


module mem_model_tb;

	reg[31:0] base_ram_data;
	reg[19:0] base_ram_addr;
	reg[3:0] base_ram_be_n;
	reg base_ram_ce_n;
	reg base_ram_oe_n;
	reg base_ram_we_n;

 	sram_model base1(/*autoinst*/
		             .DataIO(base_ram_data[15:0]),
		             .Address(base_ram_addr[19:0]),
		             .OE_n(base_ram_oe_n),
		             .CE_n(base_ram_ce_n),
		             .WE_n(base_ram_we_n),
		             .LB_n(base_ram_be_n[0]),
		             .UB_n(base_ram_be_n[1]));
	sram_model base2(/*autoinst*/
		             .DataIO(base_ram_data[31:16]),
		             .Address(base_ram_addr[19:0]),
		             .OE_n(base_ram_oe_n),
		             .CE_n(base_ram_ce_n),
		             .WE_n(base_ram_we_n),
		             .LB_n(base_ram_be_n[2]),
		             .UB_n(base_ram_be_n[3]));

				parameter BASE_RAM_INIT_FILE = "/tmp/kernel.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
		             	// 从文件加载 BaseRAM
		             	initial begin 
		             	    reg [31:0] tmp_array[0:1048575];
		             	    integer n_File_ID, n_Init_Size;
		             	    n_File_ID = $fopen(BASE_RAM_INIT_FILE, "rb");
		             	    if(!n_File_ID)begin 
		             	        n_Init_Size = 0;
		             	        $display("Failed to open BaseRAM init file");
		             	    end else begin
		             	        n_Init_Size = $fread(tmp_array, n_File_ID);
		             	        n_Init_Size /= 4;
		             	        $fclose(n_File_ID);
		             	    end
		             	    $display("BaseRAM Init Size(words): %d",n_Init_Size);
		             	    for (integer i = 0; i < n_Init_Size; i++) begin
		             	        base1.mem_array0[i] = tmp_array[i][24+:8];
		             	        base1.mem_array1[i] = tmp_array[i][16+:8];
		             	        base2.mem_array0[i] = tmp_array[i][8+:8];
		             	        base2.mem_array1[i] = tmp_array[i][0+:8];
		             	    end
		             	end
		             	
	initial begin
		base_ram_ce_n = 1'b1;
		base_ram_we_n = 1'b1;
		base_ram_be_n = 4'b0;
		base_ram_oe_n = 1'b1;
		
		base_ram_addr = 20'h00000;
		base_ram_data = 32'h01234567;
		
		#200
		base_ram_ce_n = 1'b0;
		base_ram_we_n = 1'b0;

		#200
		base_ram_we_n = 1'b1;
		base_ram_data = 32'bz;
		base_ram_oe_n = 1'b0;
	end
endmodule
