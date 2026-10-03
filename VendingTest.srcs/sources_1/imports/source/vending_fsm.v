`timescale 1ns / 1ps
// Nexys 4 DDR 自动售货机控制有限状态机。
module vending_fsm (
    input  wire       clk_state,
    input  wire       rst_n,
    input  wire       confirm_pulse,
    input  wire       cancel_pulse,
    input  wire       continue_pulse,
    input  wire       coin_pulse,
    input  wire       change_pulse,
    input  wire       qty_valid,
    input  wire       payment_done,
    input  wire       dispense_done,
    input  wire       change_done,
    output reg [3:0]  state
);

    localparam S_IDLE     = 4'b0000;
    localparam S_SEL1     = 4'b0001;
    localparam S_QTY1     = 4'b0010;
    localparam S_SEL2     = 4'b0011;
    localparam S_QTY2     = 4'b0100;
    localparam S_TOTAL    = 4'b0101;
    localparam S_PAY      = 4'b0110;
    localparam S_CHANGE   = 4'b0111;
    localparam S_BRANCH   = 4'b1111;
    localparam S_DISPENSE = 4'b1000;

    reg [3:0] next_state;

    always @* begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (confirm_pulse)
                    next_state = S_SEL1;
            end

            S_SEL1: begin
                if (cancel_pulse)
                    next_state = S_IDLE;
                else if (confirm_pulse)
                    next_state = S_QTY1;
            end

            S_QTY1: begin
                if (cancel_pulse)
                    next_state = S_SEL1;
                else if (confirm_pulse && qty_valid)
                    next_state = S_BRANCH;
            end

            S_BRANCH: begin
                if (cancel_pulse)
                    next_state = S_QTY1;
                else if (continue_pulse)
                    next_state = S_SEL2;
                else if (confirm_pulse)
                    next_state = S_TOTAL;
            end

            S_SEL2: begin
                if (cancel_pulse)
                    next_state = S_BRANCH;
                else if (confirm_pulse)
                    next_state = S_QTY2;
            end

            S_QTY2: begin
                if (cancel_pulse)
                    next_state = S_SEL2;
                else if (confirm_pulse && qty_valid)
                    next_state = S_TOTAL;
            end

            S_TOTAL: begin
                if (cancel_pulse)
                    next_state = S_BRANCH;
                else if (confirm_pulse)
                    next_state = S_PAY;
            end

            S_PAY: begin
                // 取消操作通过找零状态退回全部已投入金额。
                if (cancel_pulse)
                    next_state = S_CHANGE;
                else if (payment_done)
                    next_state = S_DISPENSE;
                else if (coin_pulse)
                    next_state = S_PAY;
            end

            S_DISPENSE: begin
                if (dispense_done)
                    next_state = S_CHANGE;
            end

            S_CHANGE: begin
                if (change_done)
                    next_state = S_IDLE;
                else if (change_pulse)
                    next_state = S_CHANGE;
            end

            default: next_state = S_IDLE;
        endcase
    end
//复位
    always @(posedge clk_state or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

endmodule