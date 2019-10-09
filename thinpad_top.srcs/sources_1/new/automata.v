`define ST_0 2'b00
`define ST_1 2'b01
`define ST_2 2'b10
`define ST_3 2'b11

`define O_ADD 4'h1
`define O_SUB 4'h2
`define O_AND 4'h3
`define O_OR 4'h4
`define O_XOR 4'h5
`define O_NOT 4'h6
`define O_SLL 4'h7
`define O_SRL 4'h8
`define O_SRA 4'h9
`define O_ROL 4'ha

module automata(
    input wire clk,
    input wire rst,
    input wire[15:0] inputSW,
    output reg[15:0] outputSW,
    output wire[1:0] st
);
    reg[1:0] state;
    reg[15:0] inputA, inputB;
    reg[3:0]  op;
    
    reg[15:0] res;
    reg flag;
    
    assign st = state;
    
    always @ (posedge clk or posedge rst) begin
        if (rst == 1'b1) begin
            state <= `ST_0;
            inputA <= 16'h0000;
            inputB <= 16'h0000;
        end else begin
            case (state)
                `ST_0 : begin
                    state <= `ST_1;
                    inputA <= inputSW;
                end
                `ST_1 : begin
                    state <= `ST_2;
                    inputB <= inputSW;
                end
                `ST_2 : begin
                    state <= `ST_3;
                 end
                `ST_3 : begin
                    state <= `ST_0;
                end
                default: begin
                	state <= `ST_0;
            		inputA <= 16'h0000;
            		inputB <= 16'h0000;
            	end
            endcase
        end
    end
    
    always @ (*) begin
    	op <= inputSW[3:0];
    	if (state == `ST_3) begin
    		outputSW <= {15'd0, flag};
    	end else begin
    		outputSW <= res;
    	end
    end
    
    always @ (*) begin
        if (rst == 1'b1) begin
            flag <= 1'b0;
            res <= 16'h0000;
        end else begin
        	flag <= 1'b0;
        	case (op)
        		`O_ADD: begin
        			res <= inputA + inputB;
        			if (((!inputA[15] && !inputB[15]) && res[15]) || ((inputA[15] && inputB[15]) && !res[15])) begin
        				flag <= 1'b1;
        			end
        		end
        		`O_SUB: begin
        		    res <= inputA - inputB;
        		    if (((!inputA[15] && inputB[15]) && res[15]) || ((inputA[15] && !inputB[15]) && !res[15])) begin
        				flag <= 1'b1;
        			end
        		end
        		`O_AND: begin
        		    res <= inputA & inputB;
        		end
        		`O_OR: begin
        		    res <= inputA | inputB;
        		end
        		`O_NOT: begin
        		    res <= ~inputA;
        		end
        		`O_XOR: begin
        		    res <= inputA ^ inputB;
        		end
        		`O_SLL: begin
        		    res <= inputA << inputB[3:0];
        		end
        		`O_SRL: begin
        		    res <= inputA >> inputB[3:0];
        		end
        		`O_SRA: begin
        		    res <= ({16{inputA[15]}} << (5'd16 - {1'b0, inputB[3:0]}))
        		    		| inputA >> inputB[3:0];
        		end
        		`O_ROL: begin
        			res <= inputA << inputB[3:0] 
        					| (inputA >> (5'd16 - {1'b0, inputB[3:0]}));
        		end
        		default: begin
            		res <= 16'h0000;
            	end
        	endcase
        end
    end
endmodule