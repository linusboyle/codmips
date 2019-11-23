`include "defines.v"
module id_tb;

reg                    rst;
reg[`InstAddrBus]		 	pc_i;
reg[`InstBus]          inst_i;

reg[`AluOpBus]					ex_aluop_i;

//处于执行阶段的指令要写入的目的寄存器信息
reg										ex_wreg_i;
reg[`RegBus]						ex_wdata_i;
reg[`RegAddrBus]       ex_wd_i;

//处于访存阶段的指令要写入的目的寄存器信息
reg										mem_wreg_i;
reg[`RegBus]						mem_wdata_i;
reg[`RegAddrBus]       mem_wd_i;

reg[`RegBus]           reg1_data_i;
reg[`RegBus]           reg2_data_i;

//如果上一条指令是转移指令，那么下一条指令在译码的时候is_in_delayslot为true
reg                    is_in_delayslot_i;

wire                    reg1_read_o;
	wire                    reg2_read_o;     
	wire[`RegAddrBus]       reg1_addr_o;
	wire[`RegAddrBus]       reg2_addr_o; 	      
	
	//送到执行阶段的信息
	wire[`AluOpBus]         aluop_o;
	wire[`AluSelBus]        alusel_o;
	wire[`RegBus]           reg1_o;
	wire[`RegBus]           reg2_o;
	wire[`RegAddrBus]       wd_o;
	wire                    wreg_o;
	wire[`RegBus]          inst_o;

	wire                    next_inst_in_delayslot_o;
	
	wire                    branch_flag_o;
	wire[`RegBus]           branch_target_address_o;       
	wire[`RegBus]           link_addr_o;
	wire                    is_in_delayslot_o;

  wire[31:0]             excepttype_o;
  wire[`RegBus]          current_inst_address_o;
	
	wire                   stallreq;

  initial begin
    rst = 1'b1;
    #200 rst=1'b0;
    pc_i=32'h00000000;
    inst_i=32'b00100100010001011111111100000000;
    ex_aluop_i=`EXE_LB_OP;
  end	