module vga_ctrl(
    input wire rst,
    input wire clk_vga,
    input wire clk_bram,
    input wire start,
    input wire stop,
    input wire[18:0] pos,
    output wire video_clk,
    output reg[7:0] video_pixel
);
    wire[31:0] pixel_data;
    reg[18:0] addr;
    reg is_running=1'b0;
    reg[24:0] clk_cnt;

    assign video_clk = (is_running == 1'b1) ? clk_vga : 1'b0;

    blk_mem_gen_0 block_ram(
        .rsta(rst),
        .clka(clk_bram),
        .addra({addr+pos[18:2], 2'b00}),
        .ena(1'b1),
        .douta(pixel_data)
    );

    always @ (posedge clk_bram) begin
        if(start==1'b1)begin
            is_running <= 1'b1;
        end else if(stop==1'b1) begin
            is_running <= 1'b0;
        end 
    end

    always @ (posedge clk_vga) begin
        clk_cnt<=clk_cnt+1'b1;
        if(clk_cnt==25'h1c9c380) begin // 30,000,000
            if(addr==18'b0) begin
                addr<=18'h107ac; // second image
                clk_cnt<=25'b0;
            end else begin
                addr<=18'b0; // first image
                clk_cnt<=25'b0;
            end
        end
    end

    always @ (*) begin
        case(pos[1:0])
            2'b00: begin
                video_pixel <= pixel_data[7:0];
            end
            2'b01: begin
                video_pixel <= pixel_data[15:8];
            end
            2'b10: begin
                video_pixel <= pixel_data[23:16];
            end
            2'b11: begin
                video_pixel <= pixel_data[31:24];
            end
        endcase
    end

endmodule
