`timescale 1ns / 1ps
// 同步器、去抖动滤波器和单时钟高电平有效脉冲发生器。
module key_pulse #(
    parameter integer DEBOUNCE_CYCLES = 1_000_000
) (
    input  wire clk,
    input  wire rst_n,
    input  wire key_in,
    output reg  pulse
);
    // 20 位计数器可以覆盖默认的 DEBOUNCE_CYCLES=1000000。
    localparam integer CW = 20;
    reg sync_a, sync_b, stable;
    reg [CW-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_a <= 1'b0;
            sync_b <= 1'b0;
            stable <= 1'b0;
            count <= {CW{1'b0}};
            pulse <= 1'b0;
        end else begin
            sync_a <= key_in;
            sync_b <= sync_a;
            pulse <= 1'b0;

            if (sync_b == stable) begin
                count <= {CW{1'b0}};
            end else if (count == DEBOUNCE_CYCLES - 1) begin
                stable <= sync_b;
                count <= {CW{1'b0}};
                if (sync_b)
                    pulse <= 1'b1;
            end else begin
                count <= count + 1'b1;
            end
        end
    end
endmodule