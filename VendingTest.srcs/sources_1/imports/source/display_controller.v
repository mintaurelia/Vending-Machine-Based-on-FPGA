`timescale 1ns / 1ps
// 八位共阳极七段数码管显示驱动模块。
// 数码管从左到右依次显示：
// 商品一编号、商品一数量、商品二编号、商品二数量、总价十位、总价个位、
// 金额十位、金额个位。最后两位显示已投金额或找零金额。
module display_controller #(
    parameter integer SCAN_DIV = 100_000
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [3:0] state,
    input  wire [3:0] code1,
    input  wire [1:0] qty1,
    input  wire [3:0] code2,
    input  wire [1:0] qty2,
    input  wire [7:0] total_price,
    input  wire [7:0] paid_money,
    input  wire [7:0] change_left,
    output reg  [6:0] seg,//段选abc
    output reg  [7:0] an,//位选，低电平有效
    output wire       dp
);
    // 17 位计数器可以覆盖默认的 SCAN_DIV=100000（0~99999）。
    localparam integer DW = 17;
    reg [DW-1:0] div_count;
    reg [2:0] scan_index;
    reg [3:0] digit;
    reg [3:0] d7, d6, d5, d4, d3, d2, d1, d0;
    reg [7:0] total_tens, total_ones, paid_tens, paid_ones;
    reg [7:0] change_tens, change_ones, money_tens, money_ones;

    assign dp = 1'b1;

    always @* begin
        total_tens = total_price / 10;
        total_ones = total_price % 10;
        paid_tens = paid_money / 10;
        paid_ones = paid_money % 10;
        change_tens = change_left / 10;
        change_ones = change_left % 10;
        if (state == 4'b0111) begin          //找零
            money_tens = change_tens;
            money_ones = change_ones;
        end else begin                     //其余显示已投币
            money_tens = paid_tens;
            money_ones = paid_ones;
        end

        // 待机状态下清零所有显示位，使数码管显示 00000000。
        if (state == 4'b0000) begin
            d7 = 4'd0;
            d6 = 4'd0;
            d5 = 4'd0;
            d4 = 4'd0;
            d3 = 4'd0;
            d2 = 4'd0;
            d1 = 4'd0;
            d0 = 4'd0;
        end else begin
            // AN7~AN0：商品一编号、商品一数量、商品二编号、商品二数量、
            // 总价十位、总价个位、金额十位、金额个位。
            d7 = code1;
            d6 = {2'b00, qty1};
            d5 = code2;
            d4 = {2'b00, qty2};
            d3 = total_tens[3:0];
            d2 = total_ones[3:0];
            d1 = money_tens[3:0];
            d0 = money_ones[3:0];
        end
    end

    always @* begin
        case (scan_index)//根据当前扫描索引选择要点亮的数码管
            3'd0: begin an = 8'b1111_1110; digit = d0; end//只有 bit0 为 0（低电平有效），点亮 AN0（最右边），显示内容为 d0
            3'd1: begin an = 8'b1111_1101; digit = d1; end
            3'd2: begin an = 8'b1111_1011; digit = d2; end
            3'd3: begin an = 8'b1111_0111; digit = d3; end
            3'd4: begin an = 8'b1110_1111; digit = d4; end
            3'd5: begin an = 8'b1101_1111; digit = d5; end
            3'd6: begin an = 8'b1011_1111; digit = d6; end
            default: begin an = 8'b0111_1111; digit = d7; end
        endcase

        // 共阳极数码管段选顺序为 {a,b,c,d,e,f,g}，低电平有效。
        case (digit)           //七段译码器
            4'h0: seg = 7'b1000000;// 0~9 A~F的编码
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            default: seg = 7'b0001110;
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin             //复位逻辑
            div_count <= {DW{1'b0}};
            scan_index <= 3'd0;
        end else if (div_count == SCAN_DIV - 1) begin     //扫描切换
            div_count <= {DW{1'b0}};
            scan_index <= scan_index + 1'b1;
        end else begin           //计数递增
            div_count <= div_count + 1'b1;
        end
    end
endmodule