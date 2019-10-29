module uart_ram (
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input wire[31:0] dip_sw,     //32位拨码开关，拨到"ON"时为1

    //CPLD串口控制器信号
    output reg uart_rdn,         //读串口信号，低有效
    output reg uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg base_ram_ce_n,       //BaseRAM片选，低有效
    output reg base_ram_oe_n,       //BaseRAM读使能，低有效
    output reg base_ram_we_n       //BaseRAM写使能，低有效
);
parameter
  st_receive = 3'b000,
  st_writeram = 3'b001,
  st_readram = 3'b010,
  st_wrn = 3'b011,
  st_tbre = 3'b100,
  st_tsre = 3'b101,
  st_end = 3'b110;

reg bus_wr;
reg[31:0] bus;
assign base_ram_data = bus_wr ? bus : 32'bz;
assign base_ram_be_n = 4'b0;

wire[7:0] uart_data;
assign uart_data = base_ram_data[7:0];

reg [19:0] addr;
reg [19:0] addr_orig;
reg [19:0] addr_end;
assign base_ram_addr = addr;

reg [2:0] st;

always @ (posedge clk_11M0592 or posedge reset_btn) begin
  if (reset_btn == 1'b1) begin
    // enable receiver
    st <= st_receive;
    uart_rdn <= 1'b0;
    uart_wrn <= 1'b1;
    bus_wr <= 1'b0;
    
    // read the base address
    addr <= dip_sw[19:0];
    addr_orig <= dip_sw[19:0];
    addr_end <= dip_sw[19:0] + 9;

    // disable ram
    base_ram_ce_n <= 1'b1;
    base_ram_we_n <= 1'b1;
    base_ram_oe_n <= 1'b1;
  end else begin
    // automata
    case (st)
      st_receive : begin
        if (uart_dataready == 1'b1) begin
          // disable receiver
          uart_rdn <= 1'b1;
          // setup the data to write
          bus <= {24'b0, uart_data};
          // enable writing:
          bus_wr <= 1'b1;
          base_ram_ce_n <= 1'b0;
          base_ram_we_n <= 1'b0;

          st <= st_writeram;
        end
      end

      st_writeram : begin
        // disable ram writing
        bus_wr <= 1'b0;
        base_ram_we_n <= 1'b1;
        if (addr == addr_end) begin
          // reset the addr
          addr <= addr_orig;
          // start to read ram
          base_ram_oe_n <= 1'b0;
          st <= st_readram;
        end else begin
          // incr the address
          addr <= addr + 1;
          // disable ram
          base_ram_we_n <= 1'b1;
          base_ram_ce_n <= 1'b1;
          base_ram_oe_n <= 1'b1;
          // start another receive
          st <= st_receive;
          uart_rdn <= 1'b0;
        end
      end

      st_readram : begin
        // diable ram
        base_ram_oe_n <= 1'b1;
        base_ram_ce_n <= 1'b1;
        base_ram_we_n <= 1'b1;
        // write to uart
        bus <= {24'b0, uart_data};
        bus_wr <= 1'b1;
        uart_wrn <= 1'b0;
        st <= st_wrn;
      end

      st_wrn : begin
        // disable writer
        uart_wrn <= 1'b1;
        bus_wr <= 1'b0;
        // wait for tbre
        st <= st_tbre;
      end

      st_tbre : begin
        if (uart_tbre == 1'b1) begin
          st <= st_tsre;
        end
      end

      st_tsre : begin
        if (uart_tsre == 1'b1) begin
          if (addr == addr_end) begin
            st <= st_end;
          end else begin
            // incr address
            addr <= addr + 1;
            // start another read of ram
            base_ram_ce_n <= 1'b0;
            base_ram_oe_n <= 1'b0;
            base_ram_we_n <= 1'b1;
            st <= st_readram;
          end
        end
      end
    endcase
  end
end

endmodule