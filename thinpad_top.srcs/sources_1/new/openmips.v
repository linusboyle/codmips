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
// Module:  openmips
// File:    openmips.v
// Author:  Lei Silei
// E-mail:  leishangwen@163.com
// Description: OpenMIPS处理器的顶层文件
// Revision: 1.0
//////////////////////////////////////////////////////////////////////

`include "defines.v"

module openmips(

		input wire	clk,
		input wire	rst_ext,

		//BaseRAM信号
		inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
		output wire[19:0] base_ram_addr, //BaseRAM地址
		output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
		output wire base_ram_ce_n,       //BaseRAM片选，低有效
		output wire base_ram_oe_n,       //BaseRAM读使能，低有效
		output wire base_ram_we_n,       //BaseRAM写使能，低有效

		//ExtRAM信号
		inout wire[31:0] ext_ram_data,  //ExtRAM数据
		output wire[19:0] ext_ram_addr, //ExtRAM地址
		output wire[3:0] ext_ram_be_n,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
		output wire ext_ram_ce_n,       //ExtRAM片选，低有效
		output wire ext_ram_oe_n,       //ExtRAM读使能，低有效
		output wire ext_ram_we_n,       //ExtRAM写使能，低有效

		output wire uart_rdn,         //读串口信号，低有效
		output wire uart_wrn,         //写串口信号，低有效
		input wire uart_dataready,    //串口数据准备好
		input wire uart_tbre,         //发送数据标志
		input wire uart_tsre,         //数据发送完毕标志

		input wire flash_done,
		input wire[31:0] flash_data,
		input wire[31:0] flash_addr,
		input wire[3:0] flash_sel,

		output wire timer_int_o
);

    wire[`InstAddrBus] pc;
    wire[`InstAddrBus] id_pc_i;
    wire[`InstBus] id_inst_i;

    //连接译码阶段ID模块的输出与ID/EX模块的输入
    wire[`AluOpBus] id_aluop_o;
    wire[`AluSelBus] id_alusel_o;
    wire[`RegBus] id_reg1_o;
    wire[`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire[`RegAddrBus] id_wd_o;
    wire id_is_in_delayslot_o;
    wire[`RegBus] id_link_address_o;
    wire[`RegBus] id_inst_o;
    wire[31:0] id_excepttype_o;
    wire[`RegBus] id_current_inst_address_o;

    //连接ID/EX模块的输出与执行阶段EX模块的输入
    wire[`AluOpBus] ex_aluop_i;
    wire[`AluSelBus] ex_alusel_i;
    wire[`RegBus] ex_reg1_i;
    wire[`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire[`RegAddrBus] ex_wd_i;
    wire ex_is_in_delayslot_i;
    wire[`RegBus] ex_link_address_i;
    wire[`RegBus] ex_inst_i;
    wire[31:0] ex_excepttype_i;
    wire[`RegBus] ex_current_inst_address_i;

    //连接执行阶段EX模块的输出与EX/MEM模块的输入
    wire ex_wreg_o;
    wire[`RegAddrBus] ex_wd_o;
    wire[`RegBus] ex_wdata_o;
    wire[`AluOpBus] ex_aluop_o;
    wire[`RegBus] ex_mem_addr_o;
    wire[`RegBus] ex_reg2_o;
    wire ex_cp0_reg_we_o;
    wire[4:0] ex_cp0_reg_write_addr_o;
    wire[2:0] ex_cp0_reg_write_sel_o;
    wire[`RegBus] ex_cp0_reg_data_o;
    wire[31:0] ex_excepttype_o;
    wire[`RegBus] ex_current_inst_address_o;
    wire ex_is_in_delayslot_o;

    //连接EX/MEM模块的输出与访存阶段MEM模块的输入
    wire mem_wreg_i;
    wire[`RegAddrBus] mem_wd_i;
    wire[`RegBus] mem_wdata_i;
    wire[`AluOpBus] mem_aluop_i;
    wire[`RegBus] mem_mem_addr_i;
    wire[`RegBus] mem_reg2_i;
    wire mem_cp0_reg_we_i;
    wire[4:0] mem_cp0_reg_write_addr_i;
    wire[2:0] mem_cp0_reg_write_sel_i;
    wire[`RegBus] mem_cp0_reg_data_i;
    wire[31:0] mem_excepttype_i;
    wire mem_is_in_delayslot_i;
    wire[`RegBus] mem_current_inst_address_i;

    //连接访存阶段MEM模块的输出与MEM/WB模块的输入
    wire mem_wreg_o;
    wire[`RegAddrBus] mem_wd_o;
    wire[`RegBus] mem_wdata_o;
    wire mem_cp0_reg_we_o;
    wire[4:0] mem_cp0_reg_write_addr_o;
    wire[2:0] mem_cp0_reg_write_sel_o;
    wire[`RegBus] mem_cp0_reg_data_o;
    wire[31:0] mem_excepttype_o;
    wire mem_is_in_delayslot_o;
    wire[`RegBus] mem_current_inst_address_o;

    //连接MEM/WB模块的输出与回写阶段的输入
    wire wb_wreg_i;
    wire[`RegAddrBus] wb_wd_i;
    wire[`RegBus] wb_wdata_i;
    wire wb_cp0_reg_we_i;
    wire[4:0] wb_cp0_reg_write_addr_i;
    wire[2:0] wb_cp0_reg_write_sel_i;
    wire[`RegBus] wb_cp0_reg_data_i;
    wire[31:0] wb_excepttype_i;
    wire wb_is_in_delayslot_i;
    wire[`RegBus] wb_current_inst_address_i;

    //连接译码阶段ID模块与通用寄存器Regfile模块
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;

    wire is_in_delayslot_i;
    wire is_in_delayslot_o;
    wire next_inst_in_delayslot_o;
    wire id_branch_flag_o;
    wire[`RegBus] branch_target_address;

    wire[5:0] stall;
    wire stallreq_from_id;
    wire stallreq_from_ex;

    // CP0 data read
    wire[`RegBus] cp0_data_o;
    wire[4:0] cp0_raddr_i;
    wire[2:0] cp0_rsel_i;

    wire flush;
    wire[`RegBus] new_pc;
    wire stallreq_pc;
    wire pc_ce;
    wire[`InstBus] pc_data;

    wire[5:0] int_i;

    // CP0 output
    wire[`RegBus]   	cp0_count;
    wire[`RegBus]	cp0_compare;
    wire[`RegBus]	cp0_status;
    wire[`RegBus]	cp0_cause;
    wire[`RegBus]	cp0_epc;
    wire[`RegBus]	cp0_config;
    wire[`RegBus]	cp0_prid;
    wire[`RegBus]	cp0_ebase;

    // CP0 latest value; to CTRL
    wire[`RegBus] 	latest_epc;
    wire[`RegBus] 	latest_ebase;

    wire[`InstAddrBus] mem_addr_rc;
    wire mem_ce_rc;
    wire mem_we_rc;
    wire[`RegBus] mem_data_i;
    wire[3:0] mem_sel;
    wire[`InstBus] mem_data_o;

    wire rst;
    assign rst = rst_ext | ~flash_done;

    //pc_reg例化
    pc_reg pc_reg0(
		   .clk(clk),
		   .rst(rst),
		   .stall(stall),
		   .flush(flush),
		   .new_pc(new_pc),
		   .branch_flag_i(id_branch_flag_o),
		   .branch_target_address_i(branch_target_address),
		   .pc(pc),
		   .ce(pc_ce),
		   .mem_aluop(mem_aluop_i),
		   .mem_mem_addr(mem_mem_addr_i),
		   .stallreq(stallreq_pc)
    );

    ram_ctrl rc(
		.rst(rst_ext),
		.pc_addr(pc),
		.pc_ce(pc_ce),
		.pc_data(pc_data),
		.mem_addr(mem_addr_rc),
		.mem_ce(mem_ce_rc),
		.mem_we(mem_we_rc),
		.mem_data_i(mem_data_i),
		.mem_sel(mem_sel),
		.mem_data_o(mem_data_o),

		.base_ram_data(base_ram_data),
		.base_ram_addr(base_ram_addr),
		.base_ram_be_n(base_ram_be_n),
		.base_ram_ce_n(base_ram_ce_n),
		.base_ram_oe_n(base_ram_oe_n),
		.base_ram_we_n(base_ram_we_n),

		.ext_ram_data(ext_ram_data),
		.ext_ram_addr(ext_ram_addr),
		.ext_ram_be_n(ext_ram_be_n),
		.ext_ram_ce_n(ext_ram_ce_n),
		.ext_ram_oe_n(ext_ram_oe_n),
		.ext_ram_we_n(ext_ram_we_n),

		.uart_rdn(uart_rdn),
		.uart_wrn(uart_wrn),
		.uart_dataready(uart_dataready),
		.uart_tbre(uart_tbre),
		.uart_tsre(uart_tsre),

		.flash_done(flash_done),
		.flash_sel(flash_sel),
		.flash_addr(flash_addr),
		.flash_data(flash_data),

		.int_o(int_i)
    );

    //IF/ID模块例化
    if_id if_id0(
		 .clk(clk),
		 .rst(rst),
		 .stall(stall),
		 .flush(flush),
		 .if_pc(pc),
		 .if_inst(pc_data),
		 .id_pc(id_pc_i),
		 .id_inst(id_inst_i)
    );

    //译码阶段ID模块
    id id0(
	   .rst(rst),
	   .pc_i(id_pc_i),
	   .inst_i(id_inst_i),

	   .ex_aluop_i(ex_aluop_o),

	   .reg1_data_i(reg1_data),
	   .reg2_data_i(reg2_data),

	   //处于执行阶段的指令要写入的目的寄存器信息
	   .ex_wreg_i(ex_wreg_o),
	   .ex_wdata_i(ex_wdata_o),
	   .ex_wd_i(ex_wd_o),

	   //处于访存阶段的指令要写入的目的寄存器信息
	   .mem_wreg_i(mem_wreg_o),
	   .mem_wdata_i(mem_wdata_o),
	   .mem_wd_i(mem_wd_o),

	   .is_in_delayslot_i(is_in_delayslot_i),

	   //送到regfile的信息
	   .reg1_read_o(reg1_read),
	   .reg2_read_o(reg2_read),

	   .reg1_addr_o(reg1_addr),
	   .reg2_addr_o(reg2_addr),

	   //送到ID/EX模块的信息
	   .aluop_o(id_aluop_o),
	   .alusel_o(id_alusel_o),
	   .reg1_o(id_reg1_o),
	   .reg2_o(id_reg2_o),
	   .wd_o(id_wd_o),
	   .wreg_o(id_wreg_o),
	   .excepttype_o(id_excepttype_o),
	   .inst_o(id_inst_o),

	   .next_inst_in_delayslot_o(next_inst_in_delayslot_o),
	   .branch_flag_o(id_branch_flag_o),
	   .branch_target_address_o(branch_target_address),
	   .link_addr_o(id_link_address_o),

	   .is_in_delayslot_o(id_is_in_delayslot_o),
	   .current_inst_address_o(id_current_inst_address_o),

	   .stallreq(stallreq_from_id)
    );

    //通用寄存器Regfile例化
    regfile regfile1(
		     .clk(clk),
		     .rst(rst),
		     .we(wb_wreg_i),
		     .waddr(wb_wd_i),
		     .wdata(wb_wdata_i),
		     .re1(reg1_read),
		     .raddr1(reg1_addr),
		     .rdata1(reg1_data),
		     .re2(reg2_read),
		     .raddr2(reg2_addr),
		     .rdata2(reg2_data)
    );

    //ID/EX模块
    id_ex id_ex0(
		 .clk(clk),
		 .rst(rst),

		 .stall(stall),
		 .flush(flush),

		 //从译码阶段ID模块传递的信息
		 .id_aluop(id_aluop_o),
		 .id_alusel(id_alusel_o),
		 .id_reg1(id_reg1_o),
		 .id_reg2(id_reg2_o),
		 .id_wd(id_wd_o),
		 .id_wreg(id_wreg_o),
		 .id_link_address(id_link_address_o),
		 .id_is_in_delayslot(id_is_in_delayslot_o),
		 .next_inst_in_delayslot_i(next_inst_in_delayslot_o),
		 .id_inst(id_inst_o),
		 .id_excepttype(id_excepttype_o),
		 .id_current_inst_address(id_current_inst_address_o),

		 //传递到执行阶段EX模块的信息
		 .ex_aluop(ex_aluop_i),
		 .ex_alusel(ex_alusel_i),
		 .ex_reg1(ex_reg1_i),
		 .ex_reg2(ex_reg2_i),
		 .ex_wd(ex_wd_i),
		 .ex_wreg(ex_wreg_i),
		 .ex_link_address(ex_link_address_i),
		 .ex_is_in_delayslot(ex_is_in_delayslot_i),
		 .is_in_delayslot_o(is_in_delayslot_i),
		 .ex_inst(ex_inst_i),
		 .ex_excepttype(ex_excepttype_i),
		 .ex_current_inst_address(ex_current_inst_address_i)
    );

    //EX模块
    ex ex0(
	   .rst(rst),

	   //送到执行阶段EX模块的信息
	   .aluop_i(ex_aluop_i),
	   .alusel_i(ex_alusel_i),
	   .reg1_i(ex_reg1_i),
	   .reg2_i(ex_reg2_i),
	   .wd_i(ex_wd_i),
	   .wreg_i(ex_wreg_i),
	   .inst_i(ex_inst_i),

	   .link_address_i(ex_link_address_i),
	   .is_in_delayslot_i(ex_is_in_delayslot_i),

	   .excepttype_i(ex_excepttype_i),
	   .current_inst_address_i(ex_current_inst_address_i),

	   //访存阶段的指令是否要写CP0，用来检测数据相关
	   .mem_cp0_reg_we(mem_cp0_reg_we_o),
	   .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
	   .mem_cp0_reg_write_sel(mem_cp0_reg_write_sel_o),
	   .mem_cp0_reg_data(mem_cp0_reg_data_o),

	   //回写阶段的指令是否要写CP0，用来检测数据相关
	   .wb_cp0_reg_we(wb_cp0_reg_we_i),
	   .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
	   .wb_cp0_reg_write_sel(wb_cp0_reg_write_sel_i),
	   .wb_cp0_reg_data(wb_cp0_reg_data_i),

	   .cp0_reg_data_i(cp0_data_o),
	   .cp0_reg_read_addr_o(cp0_raddr_i),
	   .cp0_reg_read_sel_o(cp0_rsel_i),

	   //向下一流水级传递，用于写CP0中的寄存器
	   .cp0_reg_we_o(ex_cp0_reg_we_o),
	   .cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
	   .cp0_reg_write_sel_o(ex_cp0_reg_write_sel_o),
	   .cp0_reg_data_o(ex_cp0_reg_data_o),

	   //EX模块的输出到EX/MEM模块信息
	   .wd_o(ex_wd_o),
	   .wreg_o(ex_wreg_o),
	   .wdata_o(ex_wdata_o),

	   .aluop_o(ex_aluop_o),
	   .mem_addr_o(ex_mem_addr_o),
	   .reg2_o(ex_reg2_o),

	   .excepttype_o(ex_excepttype_o),
	   .is_in_delayslot_o(ex_is_in_delayslot_o),
	   .current_inst_address_o(ex_current_inst_address_o),

	   .stallreq(stallreq_from_ex)
    );

    //EX/MEM模块
    ex_mem ex_mem0(
		   .clk(clk),
		   .rst(rst),

		   .stall(stall),
		   .flush(flush),

		   //来自执行阶段EX模块的信息
		   .ex_wd(ex_wd_o),
		   .ex_wreg(ex_wreg_o),
		   .ex_wdata(ex_wdata_o),

		   .ex_aluop(ex_aluop_o),
		   .ex_mem_addr(ex_mem_addr_o),
		   .ex_reg2(ex_reg2_o),

		   .ex_cp0_reg_we(ex_cp0_reg_we_o),
		   .ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
		   .ex_cp0_reg_write_sel(ex_cp0_reg_write_sel_o),
		   .ex_cp0_reg_data(ex_cp0_reg_data_o),

		   .ex_excepttype(ex_excepttype_o),
		   .ex_is_in_delayslot(ex_is_in_delayslot_o),
		   .ex_current_inst_address(ex_current_inst_address_o),

		   //送到访存阶段MEM模块的信息
		   .mem_wd(mem_wd_i),
		   .mem_wreg(mem_wreg_i),
		   .mem_wdata(mem_wdata_i),

		   .mem_cp0_reg_we(mem_cp0_reg_we_i),
		   .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
		   .mem_cp0_reg_write_sel(mem_cp0_reg_write_sel_i),
		   .mem_cp0_reg_data(mem_cp0_reg_data_i),

		   .mem_aluop(mem_aluop_i),
		   .mem_mem_addr(mem_mem_addr_i),
		   .mem_reg2(mem_reg2_i),

		   .mem_excepttype(mem_excepttype_i),
		   .mem_is_in_delayslot(mem_is_in_delayslot_i),
		   .mem_current_inst_address(mem_current_inst_address_i)
    );

    //MEM模块例化
    mem mem0(
	     .rst(rst),

	     //来自EX/MEM模块的信息
	     .wd_i(mem_wd_i),
	     .wreg_i(mem_wreg_i),
	     .wdata_i(mem_wdata_i),

	     .aluop_i(mem_aluop_i),
	     .mem_addr_i(mem_mem_addr_i),
	     .reg2_i(mem_reg2_i),

	     //来自memory的信息
	     .mem_data_i(mem_data_o),

	     .cp0_reg_we_i(mem_cp0_reg_we_i),
	     .cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
	     .cp0_reg_write_sel_i(mem_cp0_reg_write_sel_i),
	     .cp0_reg_data_i(mem_cp0_reg_data_i),

	     .excepttype_i(mem_excepttype_i),
	     .is_in_delayslot_i(mem_is_in_delayslot_i),
	     .current_inst_address_i(mem_current_inst_address_i),

	     .cp0_status_i(cp0_status),
	     .cp0_cause_i(cp0_cause),
	     .cp0_epc_i(cp0_epc),
	     .cp0_ebase_i(cp0_ebase),
	     
	     //回写阶段的指令是否要写CP0，用来检测数据相关
	     .wb_cp0_reg_we(wb_cp0_reg_we_i),
	     .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
	     .wb_cp0_reg_write_sel(wb_cp0_reg_write_sel_i),
	     .wb_cp0_reg_data(wb_cp0_reg_data_i),

	     .cp0_reg_we_o(mem_cp0_reg_we_o),
	     .cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
	     .cp0_reg_write_sel_o(mem_cp0_reg_write_sel_o),
	     .cp0_reg_data_o(mem_cp0_reg_data_o),

	     //送到MEM/WB模块的信息
	     .wd_o(mem_wd_o),
	     .wreg_o(mem_wreg_o),
	     .wdata_o(mem_wdata_o),

	     //送到memory的信息
	     .mem_addr_o(mem_addr_rc),
	     .mem_we_o(mem_we_rc),
	     .mem_sel_o(mem_sel),
	     .mem_data_o(mem_data_i),
	     .mem_ce_o(mem_ce_rc),

	     .excepttype_o(mem_excepttype_o),
	     .cp0_epc_o(latest_epc),
	     .cp0_ebase_o(latest_ebase),
	     .is_in_delayslot_o(mem_is_in_delayslot_o),
	     .current_inst_address_o(mem_current_inst_address_o)
    );

    //MEM/WB模块
    mem_wb mem_wb0(
		   .clk(clk),
		   .rst(rst),

		   .stall(stall),
		   .flush(flush),

		   //来自访存阶段MEM模块的信息
		   .mem_wd(mem_wd_o),
		   .mem_wreg(mem_wreg_o),
		   .mem_wdata(mem_wdata_o),

		   .mem_cp0_reg_we(mem_cp0_reg_we_o),
		   .mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		   .mem_cp0_reg_write_sel(mem_cp0_reg_write_sel_o),
		   .mem_cp0_reg_data(mem_cp0_reg_data_o),

		   //送到回写阶段的信息
		   .wb_wd(wb_wd_i),
		   .wb_wreg(wb_wreg_i),
		   .wb_wdata(wb_wdata_i),

		   .wb_cp0_reg_we(wb_cp0_reg_we_i),
		   .wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		   .wb_cp0_reg_write_sel(wb_cp0_reg_write_sel_i),
		   .wb_cp0_reg_data(wb_cp0_reg_data_i)
    );

    ctrl ctrl0(
	       .rst(rst),

	       .excepttype_i(mem_excepttype_o),
	       .cp0_epc_i(latest_epc),
	       .cp0_ebase_i(latest_ebase),

	       //来自各阶段的暂停请求
	       .stallreq_from_id(stallreq_from_id),
	       .stallreq_from_pc(stallreq_pc),
	       .stallreq_from_ex(stallreq_from_ex),

	       .new_pc(new_pc),
	       .flush(flush),
	       .stall(stall)
    );


    cp0_reg cp0_reg0(
		     .clk(clk),
		     .rst(rst),

		     .we_i(wb_cp0_reg_we_i),
		     .waddr_i(wb_cp0_reg_write_addr_i),
		     .wsel_i(wb_cp0_reg_write_sel_i),

		     .raddr_i(cp0_raddr_i),
		     .rsel_i(cp0_rsel_i),
		     .data_i(wb_cp0_reg_data_i),

		     .excepttype_i(mem_excepttype_o),
		     .int_i(int_i),
		     .current_inst_addr_i(mem_current_inst_address_o),
		     .is_in_delayslot_i(mem_is_in_delayslot_o),

		     .data_o(cp0_data_o),
		     .count_o(cp0_count),
		     .compare_o(cp0_compare),
		     .status_o(cp0_status),
		     .cause_o(cp0_cause),
		     .epc_o(cp0_epc),
		     .config_o(cp0_config),
		     .prid_o(cp0_prid),
		     .ebase_o(cp0_ebase),

		     .timer_int_o(timer_int_o)
    );

endmodule
