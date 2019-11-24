`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/11/23 10:51:31
// Design Name: 
// Module Name: ram_ctrl_tb
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


module ram_ctrl_tb;

	reg rst;
	reg [31:0] pc_addr;
	reg pc_ce;
	wire[31:0] pc_data;

	reg[31:0] mem_addr;
	reg mem_ce;
	reg mem_we;
	reg[31:0] mem_data_i;
	reg[3:0] mem_sel;
	wire[31:0] mem_data_o;

	wire[31:0] base_ram_data;
	wire[19:0] base_ram_addr;
	wire[3:0] base_ram_be_n;
	wire base_ram_ce_n;
	wire base_ram_oe_n;
	wire base_ram_we_n;

	wire[31:0] ext_ram_data;
	wire[19:0] ext_ram_addr;
	wire[3:0] ext_ram_be_n;
	wire ext_ram_ce_n;
	wire ext_ram_oe_n;
	wire ext_ram_we_n;

	ram_ctrl rc(rst, pc_addr, pc_ce, pc_data, mem_addr, mem_ce, mem_we,
		 mem_data_i, mem_sel, mem_data_o,
		 base_ram_data, base_ram_addr, base_ram_be_n, base_ram_ce_n,
		 base_ram_oe_n, base_ram_we_n,
		 ext_ram_data, ext_ram_addr, ext_ram_be_n, ext_ram_ce_n,
		 ext_ram_oe_n, ext_ram_we_n);

		// BaseRAM 仿真模型
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
		 // ExtRAM 仿真模型
		 sram_model ext1(/*autoinst*/
		             .DataIO(ext_ram_data[15:0]),
		             .Address(ext_ram_addr[19:0]),
		             .OE_n(ext_ram_oe_n),
		             .CE_n(ext_ram_ce_n),
		             .WE_n(ext_ram_we_n),
		             .LB_n(ext_ram_be_n[0]),
		             .UB_n(ext_ram_be_n[1]));
		 sram_model ext2(/*autoinst*/
		             .DataIO(ext_ram_data[31:16]),
		             .Address(ext_ram_addr[19:0]),
		             .OE_n(ext_ram_oe_n),
		             .CE_n(ext_ram_ce_n),
		             .WE_n(ext_ram_we_n),
		             .LB_n(ext_ram_be_n[2]),
		             .UB_n(ext_ram_be_n[3]));
		             
	initial begin
	    rst = 1;

	    #200
	    rst = 0;
	end

	initial begin
	    pc_ce = 1'b0;

	    forever #100 begin
		pc_ce = ~pc_ce;
	    end
	end
	
	initial begin
		pc_addr = 32'h80000000;

		forever #200 begin
			pc_addr = pc_addr + 4;
		end
	end
	
	parameter BASE_RAM_INIT_FILE = "/tmp/kernel.bin"; //BaseRAM初始化文件，请修改为实际的绝对路径
	parameter EXT_RAM_INIT_FILE = "/tmp/kernel.elf"; //BaseRAM初始化文件，请修改为实际的绝对路径
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
	
	// 从文件加载 ExtRAM
	initial begin 
	    reg [31:0] tmp_array[0:1048575];
	    integer n_File_ID, n_Init_Size;
	    n_File_ID = $fopen(EXT_RAM_INIT_FILE, "rb");
	    if(!n_File_ID)begin 
	        n_Init_Size = 0;
	        $display("Failed to open ExtRAM init file");
	    end else begin
	        n_Init_Size = $fread(tmp_array, n_File_ID);
	        n_Init_Size /= 4;
	        $fclose(n_File_ID);
	    end
	    $display("ExtRAM Init Size(words): %d",n_Init_Size);
	    for (integer i = 0; i < n_Init_Size; i++) begin
	        ext1.mem_array0[i] = tmp_array[i][24+:8];
	        ext1.mem_array1[i] = tmp_array[i][16+:8];
	        ext2.mem_array0[i] = tmp_array[i][8+:8];
	        ext2.mem_array1[i] = tmp_array[i][0+:8];
	    end
	end
	
	initial begin
	    mem_addr = 32'h80400000;
	    mem_ce = 1'b0;
	    mem_we = 1'b0;
	    mem_data_i = 32'h10203040;
	    mem_sel = 4'b1;

	    forever #100 begin
			mem_ce = ~mem_ce;
	    end
	end
	
	initial begin
	    repeat (3) begin
	    	#200
	    	mem_addr = mem_addr + 4;
		end
		
		#200
		mem_addr = 32'h80400000;
		mem_we = 1'b1;
		
		repeat (3) begin
			#200
			mem_addr = mem_addr + 4;
			mem_data_i = mem_data_i + 32'h00000010;
		end

		#200
		mem_we = 1'b0;
		mem_addr = 32'h80400000;
		
		forever #200 begin
			mem_addr = mem_addr + 4;
		end
	end
	
endmodule
