`timescale 1ns / 1ps
module vending_tb;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg confirm_pulse = 0;
    reg cancel_pulse = 0;
    reg continue_pulse = 0;
    reg coin_pulse = 0;
    reg change_pulse = 0;
    reg qty_valid = 1;
    reg payment_done = 0;
    reg dispense_done = 0;
    reg change_done = 0;
    wire [3:0] state;
    wire [3:0] price;
    reg [3:0] product_code;

    always #5 clk = ~clk;

    price_rom u_rom (.product_code(product_code), .price(price));
    vending_fsm u_fsm (
        .clk_state(clk), .rst_n(rst_n),
        .confirm_pulse(confirm_pulse), .cancel_pulse(cancel_pulse),
        .continue_pulse(continue_pulse), .coin_pulse(coin_pulse),
        .change_pulse(change_pulse), .qty_valid(qty_valid),
        .payment_done(payment_done), .dispense_done(dispense_done),
        .change_done(change_done), .state(state)
    );

    task press_key;
        input [2:0] key_sel;
        begin
            @(negedge clk);
            case (key_sel)
                3'd0: confirm_pulse  = 1;
                3'd1: cancel_pulse   = 1;
                3'd2: continue_pulse = 1;
                3'd3: coin_pulse     = 1;
                3'd4: change_pulse   = 1;
            endcase
            @(negedge clk);
            case (key_sel)
                3'd0: confirm_pulse  = 0;
                3'd1: cancel_pulse   = 0;
                3'd2: continue_pulse = 0;
                3'd3: coin_pulse     = 0;
                3'd4: change_pulse   = 0;
            endcase
        end
    endtask

    task select_product;
        input [3:0] code;
        begin
            @(negedge clk);
            product_code = code;
            @(negedge clk);
        end
    endtask

    initial begin
        product_code = 4'h0;
        #20;
        rst_n = 1'b1;

        select_product(4'h0); if (price !== 4'd3)  $fatal(1, "A11 price error");
        select_product(4'h1); if (price !== 4'd4)  $fatal(1, "A12 price error");
        select_product(4'h2); if (price !== 4'd6)  $fatal(1, "A13 price error");
        select_product(4'h3); if (price !== 4'd3)  $fatal(1, "A14 price error");
        select_product(4'h4); if (price !== 4'd10) $fatal(1, "A21 price error");
        select_product(4'h5); if (price !== 4'd8)  $fatal(1, "A22 price error");
        select_product(4'h6); if (price !== 4'd9)  $fatal(1, "A23 price error");
        select_product(4'h7); if (price !== 4'd7)  $fatal(1, "A24 price error");
        select_product(4'h8); if (price !== 4'd4)  $fatal(1, "A31 price error");
        select_product(4'h9); if (price !== 4'd6)  $fatal(1, "A32 price error");
        select_product(4'hA); if (price !== 4'd15) $fatal(1, "A33 price error");
        select_product(4'hB); if (price !== 4'd8)  $fatal(1, "A34 price error");
        select_product(4'hC); if (price !== 4'd9)  $fatal(1, "A41 price error");
        select_product(4'hD); if (price !== 4'd4)  $fatal(1, "A42 price error");
        select_product(4'hE); if (price !== 4'd5)  $fatal(1, "A43 price error");
        select_product(4'hF); if (price !== 4'd5)  $fatal(1, "A44 price error");

        $display("Price ROM ALL 16 PASS");

        select_product(4'h0);
        #20;

        press_key(3'd0);
        press_key(3'd0);
        press_key(3'd0);
        press_key(3'd0);
        if (state !== 4'b0101) $fatal(1, "Expected TOTAL, got %b", state);

        press_key(3'd0);
        if (state !== 4'b0110) $fatal(1, "Expected PAY, got %b", state);

        press_key(3'd3);
        press_key(3'd3);
        if (state !== 4'b0110) $fatal(1, "Should stay in PAY");

        @(negedge clk); payment_done = 1;
        @(negedge clk); payment_done = 0;
        if (state !== 4'b1000) $fatal(1, "Expected DISPENSE, got %b", state);

        @(negedge clk); dispense_done = 1;
        @(negedge clk); dispense_done = 0;
        if (state !== 4'b0111) $fatal(1, "Expected CHANGE, got %b", state);

        @(negedge clk); change_done = 1;
        @(negedge clk); change_done = 0;
        if (state !== 4'b0000) $fatal(1, "Expected IDLE, got %b", state);
        $display("Test 1 PASS");

        press_key(3'd0);
        press_key(3'd1);
        if (state !== 4'b0000) $fatal(1, "Cancel from SEL1 failed, got %b", state);

        press_key(3'd0);
        press_key(3'd0);
        press_key(3'd1);
        if (state !== 4'b0001) $fatal(1, "Cancel from QTY1 failed, got %b", state);
        $display("Test 2 PASS");

        press_key(3'd0);
        press_key(3'd0);
        press_key(3'd2);
        if (state !== 4'b0011) $fatal(1, "Continue failed, got %b", state);

        press_key(3'd0);
        press_key(3'd0);
        if (state !== 4'b0101) $fatal(1, "Two-item TOTAL failed, got %b", state);
        $display("Test 3 PASS");

        press_key(3'd0);
        press_key(3'd1);
        if (state !== 4'b0111) $fatal(1, "Cancel to CHANGE failed, got %b", state);

        press_key(3'd4);
        if (state !== 4'b0111) $fatal(1, "Change stay failed, got %b", state);

        @(negedge clk); change_done = 1;
        @(negedge clk); change_done = 0;
        if (state !== 4'b0000) $fatal(1, "Change done failed, got %b", state);
        $display("Test 4 PASS");

        $display("vending_tb ALL TESTS PASS");
        $finish;
    end
endmodule