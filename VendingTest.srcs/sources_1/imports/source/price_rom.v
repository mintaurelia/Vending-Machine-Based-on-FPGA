`timescale 1ns / 1ps
// 产品编码：{row[1:0], column[1:0]} = A11 ... A44。
module price_rom (
    input  wire [3:0] product_code,
    output reg  [3:0] price
);
    always @* begin
        case (product_code)
            4'h0: price = 4'd3;   // 商品 A11
            4'h1: price = 4'd4;   // 商品 A12
            4'h2: price = 4'd6;   // 商品 A13
            4'h3: price = 4'd3;   // 商品 A14
            4'h4: price = 4'd10;  // 商品 A21
            4'h5: price = 4'd8;   // 商品 A22
            4'h6: price = 4'd9;   // 商品 A23
            4'h7: price = 4'd7;   // 商品 A24
            4'h8: price = 4'd4;   // 商品 A31
            4'h9: price = 4'd6;   // 商品 A32
            4'hA: price = 4'd15;  // 商品 A33
            4'hB: price = 4'd8;   // 商品 A34
            4'hC: price = 4'd9;   // 商品 A41
            4'hD: price = 4'd4;   // 商品 A42
            4'hE: price = 4'd5;   // 商品 A43
            4'hF: price = 4'd5;   // 商品 A44
            default: price = 4'd0;
        endcase
    end
endmodule