`include "defines.v"

module ex(

	  input wire        rst,

	  //送到执行阶段的信息
	  input wire[`AluOpBus]         aluop_i,
	  input wire[`AluSelBus]        alusel_i,
	  input wire[`RegBus]           reg1_i,
	  input wire[`RegBus]           reg2_i,
	  input wire[`RegAddrBus]       wd_i,
	  input wire                    wreg_i,
	  input wire[`RegBus]           inst_i,
	  input wire[31:0]              excepttype_i,
	  input wire[`RegBus]           current_inst_address_i,

	  //是否转移以及link address
	  input wire[`RegBus]           link_address_i,
	  input wire                    is_in_delayslot_i,

	  //访存阶段的指令是否要写CP0，用来检测数据相关
	  input wire                    mem_cp0_reg_we,
	  input wire[4:0]               mem_cp0_reg_write_addr,
	  input wire[2:0]               mem_cp0_reg_write_sel,
	  input wire[`RegBus]           mem_cp0_reg_data,

	  //回写阶段的指令是否要写CP0，用来检测数据相关
	  input wire                    wb_cp0_reg_we,
	  input wire[4:0]               wb_cp0_reg_write_addr,
	  input wire[2:0]               wb_cp0_reg_write_sel,
	  input wire[`RegBus]           wb_cp0_reg_data,

	  //与CP0相连，读取其中CP0寄存器的值
	  input wire[`RegBus]           cp0_reg_data_i,
	  output reg[4:0]               cp0_reg_read_addr_o,
	  output reg[2:0]               cp0_reg_read_sel_o,

	  //向下一流水级传递，用于写CP0中的寄存器
	  output reg                    cp0_reg_we_o,
	  output reg[4:0]               cp0_reg_write_addr_o,
	  output reg[2:0]		cp0_reg_write_sel_o,
	  output reg[`RegBus]           cp0_reg_data_o,

	  output reg[`RegAddrBus]       wd_o,
	  output reg                    wreg_o,
	  output reg[`RegBus]           wdata_o,

	  //下面新增的几个输出是为加载、存储指令准备的
	  output wire[`AluOpBus]        aluop_o,
	  output wire[`RegBus]          mem_addr_o,
	  output wire[`RegBus]          reg2_o,

	  output wire[31:0]             excepttype_o,
	  output wire                   is_in_delayslot_o,
	  output wire[`RegBus]          current_inst_address_o,

	  output reg                    stallreq

);

    reg[`RegBus] logicout;
    reg[`RegBus] shiftres;
    reg[`RegBus] moveres;
    reg[`RegBus] arithmeticres;
    reg[`DoubleRegBus] mulres;
    wire[`RegBus] result_sum;
    wire trapassert;
    reg ovassert;

    wire ov_sum;

    assign ov_sum = ((!reg1_i[31] && !reg2_i[31]) && result_sum[31]) ||
	((reg1_i[31] && reg2_i[31]) && (!result_sum[31]));

    //aluop_o传递到访存阶段，用于加载、存储指令
    assign aluop_o = aluop_i;

    //mem_addr传递到访存阶段，是加载、存储指令对应的存储器地址
    assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};

    //将两个操作数也传递到访存阶段，也是为记载、存储指令准备的
    assign reg2_o = reg2_i;

    assign trapassert = `TrapNotAssert;
    assign excepttype_o = {excepttype_i[31:12], ovassert, trapassert, excepttype_i[9:8], 8'h00};

    assign is_in_delayslot_o = is_in_delayslot_i;
    assign current_inst_address_o = current_inst_address_i;

    always @ (*) begin
	if (rst == `RstEnable) begin
	    logicout <= `ZeroWord;
	end else begin
	    case (aluop_i)
		`EXE_OR_OP:            begin
			logicout <= reg1_i | reg2_i;
		    end
		`EXE_AND_OP:        begin
			logicout <= reg1_i & reg2_i;
		    end
		`EXE_XOR_OP:        begin
			logicout <= reg1_i ^ reg2_i;
		    end
		default:                begin
			logicout <= `ZeroWord;
		    end
	    endcase
	end    //if
    end      //always

    always @ (*) begin
	if (rst == `RstEnable) begin
	    shiftres <= `ZeroWord;
	end else begin
	    case (aluop_i)
		`EXE_SLL_OP:            begin
			shiftres <= reg2_i << reg1_i[4:0];
		    end
		`EXE_SRL_OP:        begin
			shiftres <= reg2_i >> reg1_i[4:0];
		    end
		default:                begin
			shiftres <= `ZeroWord;
		    end
	    endcase
	end    //if
    end      //always


    assign result_sum = reg1_i + reg2_i;

    always @ (*) begin
	if (rst == `RstEnable) begin
	    arithmeticres <= `ZeroWord;
	end else begin
	    case (aluop_i)
		`EXE_ADDU_OP, `EXE_ADDIU_OP:        begin
			arithmeticres <= result_sum;
		    end
		`EXE_CLZ_OP:        begin
			arithmeticres <= reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 :
			    reg1_i[28] ? 3 : reg1_i[27] ? 4 : reg1_i[26] ? 5 :
			    reg1_i[25] ? 6 : reg1_i[24] ? 7 : reg1_i[23] ? 8 :
			    reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
			    reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 :
			    reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 :
			    reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
			    reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 :
			    reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 :
			    reg1_i[4] ? 27 : reg1_i[3] ? 28 : reg1_i[2] ? 29 :
			    reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
		    end
		default:                begin
			arithmeticres <= `ZeroWord;
		    end
	    endcase
	end
    end


    always @ (*) begin
	stallreq <= 1'b0;
    end

    //MFHI、MFLO、MOVN、MOVZ指令
    always @ (*) begin
	if (rst == `RstEnable) begin
	    moveres <= `ZeroWord;
	end else begin
	    moveres <= `ZeroWord;
	    case (aluop_i)
		`EXE_MOVZ_OP:        begin
			moveres <= reg1_i;
		    end
		`EXE_MFC0_OP:        begin
			cp0_reg_read_addr_o <= inst_i[15:11];
			cp0_reg_read_sel_o <= inst_i[2:0];
			moveres <= cp0_reg_data_i;
			if (mem_cp0_reg_we == `WriteEnable &&
			    mem_cp0_reg_write_addr == inst_i[15:11] &&
			    mem_cp0_reg_write_sel == inst_i[2:0]) begin
			    moveres <= mem_cp0_reg_data;
			end else if (wb_cp0_reg_we == `WriteEnable &&
				     wb_cp0_reg_write_addr == inst_i[15:11] &&
				     wb_cp0_reg_write_sel == inst_i[2:0]) begin
			    moveres <= wb_cp0_reg_data;
			end
		    end
		default : begin end
	    endcase
	end
    end

    always @ (*) begin
	wd_o <= wd_i;

	if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
	     (aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1)) begin
	    wreg_o <= `WriteDisable;
	    ovassert <= 1'b1;
	end else begin
	    wreg_o <= wreg_i;
	    ovassert <= 1'b0;
	end

	case (alusel_i)
	    `EXE_RES_LOGIC:        begin
		    wdata_o <= logicout;
		end
	    `EXE_RES_SHIFT:        begin
		    wdata_o <= shiftres;
		end
	    `EXE_RES_MOVE:        begin
		    wdata_o <= moveres;
		end
	    `EXE_RES_ARITHMETIC:    begin
		    wdata_o <= arithmeticres;
		end
	    `EXE_RES_JUMP_BRANCH:    begin
		    wdata_o <= link_address_i;
		end
	    default:                    begin
		    wdata_o <= `ZeroWord;
		end
	endcase
    end

    always @ (*) begin
	if (rst == `RstEnable) begin
	    cp0_reg_write_addr_o <= 5'b00000;
	    cp0_reg_write_sel_o <= 3'b000;
	    cp0_reg_we_o <= `WriteDisable;
	    cp0_reg_data_o <= `ZeroWord;
	end else if (aluop_i == `EXE_MTC0_OP) begin
	    cp0_reg_write_addr_o <= inst_i[15:11];
	    cp0_reg_write_sel_o <= inst_i[2:0];
	    cp0_reg_we_o <= `WriteEnable;
	    cp0_reg_data_o <= reg1_i;
	end else begin
	    cp0_reg_write_addr_o <= 5'b00000;
	    cp0_reg_write_sel_o <= 3'b000;
	    cp0_reg_we_o <= `WriteDisable;
	    cp0_reg_data_o <= `ZeroWord;
	end
    end

endmodule
