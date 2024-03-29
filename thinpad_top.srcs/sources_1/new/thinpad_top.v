`default_nettype none

module thinpad_top(
    input wire clk_50M,           //50MHz 时钟输入
    input wire clk_11M0592,       //11.0592MHz 时钟输入

    input wire clock_btn,         //BTN5手动时钟按钮开关，带消抖电路，按下时为1
    input wire reset_btn,         //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  wire[3:0]  touch_btn,  //BTN1~BTN4，按钮开关，按下时为1
    input  wire[31:0] dip_sw,     //32位拨码开关，拨到“ON”时为1
    output wire[15:0] leds,       //16位LED，输出时1点亮
    output wire[7:0]  dpy0,       //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0]  dpy1,       //数码管高位信号，包括小数点，输出1点亮

    //CPLD串口控制器信号
    output wire uart_rdn,         //读串口信号，低有效
    output wire uart_wrn,         //写串口信号，低有效
    input wire uart_dataready,    //串口数据准备好
    input wire uart_tbre,         //发送数据标志
    input wire uart_tsre,         //数据发送完毕标志

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

    //直连串口信号
    output wire txd,  //直连串口发送端
    input  wire rxd,  //直连串口接收端

    //Flash存储器信号，参考 JS28F640 芯片手册
    output wire [22:0]flash_a,      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
    inout  wire [15:0]flash_d,      //Flash数据
    output wire flash_rp_n,         //Flash复位信号，低有效
    output wire flash_vpen,         //Flash写保护信号，低电平时不能擦除、烧写
    output wire flash_ce_n,         //Flash片选信号，低有效
    output wire flash_oe_n,         //Flash读使能信号，低有效
    output wire flash_we_n,         //Flash写使能信号，低有效
    output wire flash_byte_n,       //Flash 8bit模式选择，低有效。在使用flash的16位模式时请设为1

    //USB 控制器信号，参考 SL811 芯片手册
    output wire sl811_a0,
    //inout  wire[7:0] sl811_d,     //USB数据线与网络控制器的dm9k_sd[7:0]共享
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input  wire sl811_intrq,
    input  wire sl811_drq_n,

    //网络控制器信号，参考 DM9000A 芯片手册
    output wire dm9k_cmd,
    inout  wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input  wire dm9k_int,

    //图像输出信号
    output wire[2:0] video_red,    //红色像素，3位
    output wire[2:0] video_green,  //绿色像素，3位
    output wire[1:0] video_blue,   //蓝色像素，2位
    output wire video_hsync,       //行同步（水平同步）信号
    output wire video_vsync,       //场同步（垂直同步）信号
    output wire video_clk,         //像素时钟输出
    output wire video_de           //行数据有效信号，用于区分消隐区
);

    // PLL分频示例
    wire locked, clk_main, clk_ext;
    pll_example clock_gen 
     (
      // Clock out ports
      .clk_out1(clk_main), // 时钟输出1，频率在IP配置界面中设置
      .clk_out2(clk_ext), // 时钟输出2，频率在IP配置界面中设置
      // Status and control signals
      .reset(reset_btn), // PLL复位输入
      .locked(locked), // 锁定输出，"1"表示时钟稳定，可作为后级电路复位
     // Clock in ports
      .clk_in1(clk_50M) // 外部时钟输入
     );

    reg reset_of_clkmain;
    // 异步复位，同步释放
    always@(posedge clk_main or negedge locked) begin
	if(~locked) reset_of_clkmain <= 1'b1;
	else        reset_of_clkmain <= 1'b0;
    end

    reg reset_of_clkext;
    // 异步复位，同步释放
    always@(posedge clk_ext or negedge locked) begin
	if(~locked) reset_of_clkext <= 1'b1;
	else        reset_of_clkext <= 1'b0;
    end

    wire [31:0] flash_addr, flash_data;
    wire [3:0] flash_sel;
    wire flash_done;

    bios flash_ctrl (
	.rst(reset_of_clkext),
	.clk(clk_ext),

	.flash_a(flash_a),      //Flash地址，a0仅在8bit模式有效，16bit模式无意义
	.flash_d(flash_d),      //Flash数据
	.flash_rp_n(flash_rp_n),         //Flash复位信号，低有效
	.flash_vpen(flash_vpen),         //Flash写保护信号，低电平时不能擦除、烧写
	.flash_ce_n(flash_ce_n),         //Flash片选信号，低有效
	.flash_oe_n(flash_oe_n),         //Flash读使能信号，低有效
	.flash_we_n(flash_we_n),         //Flash写使能信号，低有效
	.flash_byte_n(flash_byte_n),       //Flash 8bit模式选择，低有效.在使用flash的16位模式时请设为1

	.data(flash_data),
	.addr(flash_addr),
	.sel(flash_sel),

	.done(flash_done)
	);

    wire timer_int_o;

    openmips mycpu (
	.clk(clk_main),
	.rst_ext(reset_of_clkmain),

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

	.flash_data(flash_data),
	.flash_addr(flash_addr),
	.flash_sel(flash_sel),

	.flash_done(flash_done),

	.timer_int_o(timer_int_o)
    );

	assign leds = 16'h0000;
	assign dpy0 = 8'h00;
	assign dpy1 = 8'h00;
    //assign uart_rdn = 1'b1;
    //assign uart_wrn = 1'b1;

    // 数码管连接关系示意图，dpy1同理
    // p=dpy0[0] // ---a---
    // c=dpy0[1] // |     |
    // d=dpy0[2] // f     b
    // e=dpy0[3] // |     |
    // b=dpy0[4] // ---g---
    // a=dpy0[5] // |     |
    // f=dpy0[6] // e     c
    // g=dpy0[7] // |     |
    //           // ---d---  p

    // 7段数码管译码器演示，将number用16进制显示在数码管上面
    // wire[1:0] number;
    // SEG7_LUT segL(.oSEG1(dpy0), .iDIG({2'd0, number})); //dpy0是低位数码管

    //reg[15:0] led_bits;
    //assign leds = led_bits;

    //always@(posedge clock_btn or posedge reset_btn) begin
    //if(reset_btn)begin //复位按下，设置LED和数码管为初始值
    //	number<=0;
    //	led_bits <= 16'h1;
    //end
    //else begin //每次按下时钟按钮，数码管显示值加1，LED循环左移
    //	number <= number+1;
    //	led_bits <= {led_bits[14:0],led_bits[15]};
    //end
    //end
    //automata ALU(.clk(clock_btn), .rst(reset_btn), .inputSW(dip_sw[15:0]), .outputSW(leds), .st(number));

    /*
	=========直连串口==========
    */
    //直连串口接收发送演示，从直连串口收到的数据再发送出去
    wire [7:0] ext_uart_rx;
    reg  [7:0] ext_uart_buffer, ext_uart_tx;
    wire ext_uart_ready, ext_uart_busy;
    reg ext_uart_start, ext_uart_avai;

    async_receiver #(.ClkFrequency(50000000),.Baud(9600)) //接收模块，9600无检验位
	ext_uart_r(
	    .clk(clk_50M),                       //外部时钟信号
	    .RxD(rxd),                           //外部串行信号输入
	    .RxD_data_ready(ext_uart_ready),  //数据接收到标志
	    .RxD_clear(ext_uart_ready),       //清除接收标志
	    .RxD_data(ext_uart_rx)             //接收到的一字节数据
	);
			    
    always @(posedge clk_50M) begin //接收到缓冲区ext_uart_buffer
	if(ext_uart_ready)begin
	    ext_uart_buffer <= ext_uart_rx;
	    ext_uart_avai <= 1;
	end else if(!ext_uart_busy && ext_uart_avai)begin 
	    ext_uart_avai <= 0;
	end
    end
    always @(posedge clk_50M) begin //将缓冲区ext_uart_buffer发送出去
	if(!ext_uart_busy && ext_uart_avai)begin 
	    ext_uart_tx <= ext_uart_buffer;
	    ext_uart_start <= 1;
	end else begin 
	    ext_uart_start <= 0;
	end
    end

    async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) //发送模块，9600无检验位
	ext_uart_t(
	    .clk(clk_50M),                  //外部时钟信号
	    .TxD(txd),                      //串行信号输出
	    .TxD_busy(ext_uart_busy),       //发送器忙状态指示
	    .TxD_start(ext_uart_start),    //开始发送信号
	    .TxD_data(ext_uart_tx)        //待发送的数据
	);

    /*
	   ==========VGA==========
    */
    //图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
    // wire [11:0] hdata;
    // assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
    // assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
    // assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
    // assign video_clk = clk_50M;
    // vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
	// .clk(clk_50M), 
	// .hdata(hdata), //横坐标
	// .vdata(),      //纵坐标
	// .hsync(video_hsync),
	// .vsync(video_vsync),
	// .data_enable(video_de)
    // );

    wire[18:0] vga_pos;
    wire vga_start;
    wire vga_stop;
    wire[7:0] video_pixel;
    
    assign vga_stop = touch_btn[0];

    assign vga_start = touch_btn[1];
    assign video_red = video_pixel[7:5];
    assign video_green = video_pixel[4:2];
    assign video_blue = video_pixel[1:0];

    vga_ctrl vga_ctrl_inst(
        .rst(reset_btn),
        .clk_vga(clk_50M),
        .clk_bram(clk_50M),
        .start(vga_start),
        .stop(vga_stop),
        .pos(vga_pos),
        .video_clk(video_clk),
        .video_pixel(video_pixel)
    );

    vga #(12, 600, 656, 752, 800, 450, 490, 492, 525, 1, 1) vga600x450at60 (
        .clk(clk_50M), 
        .pos(vga_pos),
        .hsync(video_hsync),
        .vsync(video_vsync),
        .data_enable(video_de)
    );

endmodule
