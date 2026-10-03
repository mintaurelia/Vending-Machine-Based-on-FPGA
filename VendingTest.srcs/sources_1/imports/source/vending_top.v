`timescale 1ns / 1ps
// Nexys 4 DDR 售货机顶层模块。
// 接口说明：
//   SW[3:0]   商品选择，0~15 对应 A11~A44
//   SW[5:4]   商品数量选择，01~11 对应 1~3 件
//   SW[15:11] 投币选择：SW15=50，SW14=20，SW13=10，SW12=5，SW11=1 元
//   BTNC      开始/确认
//   BTNU      继续/下一步
//   BTNL      取消/退币
//   BTNR      投入当前选择的硬币
//   BTND      退 1 元/找零
module vending_top (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire [15:0] SW,
    input  wire        BTNC,
    input  wire        BTNU,
    input  wire        BTNL,
    input  wire        BTNR,
    input  wire        BTND,
    output wire [15:0] LED,
    output wire [6:0]  SEG,
    output wire        DP,
    output wire [7:0]  AN
);
    localparam S_IDLE     = 4'b0000;
    localparam S_SEL1     = 4'b0001;
    localparam S_QTY1     = 4'b0010;
    localparam S_SEL2     = 4'b0011;
    localparam S_QTY2     = 4'b0100;
    localparam S_TOTAL    = 4'b0101;
    localparam S_PAY      = 4'b0110;
    localparam S_CHANGE   = 4'b0111;
    localparam S_DISPENSE = 4'b1000;
    localparam S_BRANCH   = 4'b1111;

    wire confirm_pulse;
    wire continue_pulse;
    wire cancel_pulse;
    wire coin_pulse;
    wire change_pulse;
    wire qty_valid;
    wire [7:0] coin_value;
    wire coin_valid;

    // state 由 vending_fsm 模块输出
    wire [3:0] state;
    reg [3:0] code1, code2;
    reg [1:0] qty1, qty2;
    reg       item2_valid;
    reg [7:0] paid_money;
    reg [7:0] change_left;
    reg [7:0] total_price;
    reg [15:0] led_reg;
    reg error_reg;
    wire [3:0] price1;
    wire [3:0] price2;
    wire payment_done;
    wire dispense_done;
    wire change_done;

    key_pulse #(.DEBOUNCE_CYCLES(1_000_000)) u_confirm (
        .clk(CLK100MHZ), .rst_n(CPU_RESETN), .key_in(BTNC), .pulse(confirm_pulse));
    key_pulse #(.DEBOUNCE_CYCLES(1_000_000)) u_continue (
        .clk(CLK100MHZ), .rst_n(CPU_RESETN), .key_in(BTNU), .pulse(continue_pulse));
    key_pulse #(.DEBOUNCE_CYCLES(1_000_000)) u_cancel (
        .clk(CLK100MHZ), .rst_n(CPU_RESETN), .key_in(BTNL), .pulse(cancel_pulse));
    key_pulse #(.DEBOUNCE_CYCLES(1_000_000)) u_coin (
        .clk(CLK100MHZ), .rst_n(CPU_RESETN), .key_in(BTNR), .pulse(coin_pulse));
    key_pulse #(.DEBOUNCE_CYCLES(1_000_000)) u_change (
        .clk(CLK100MHZ), .rst_n(CPU_RESETN), .key_in(BTND), .pulse(change_pulse));

    assign qty_valid = (SW[5:4] >= 2'd1) && (SW[5:4] <= 2'd3);

    // 投币选择：SW15/SW14/SW13/SW12/SW11 分别对应 50/20/10/5/1 元
    // 同一时刻只允许一位为 1，其余为 0；全为 0 或全为 1 均无效
    assign coin_valid = (SW[15:11] == 5'b10000) ||
                        (SW[15:11] == 5'b01000) ||
                        (SW[15:11] == 5'b00100) ||
                        (SW[15:11] == 5'b00010) ||
                        (SW[15:11] == 5'b00001);
    assign coin_value = (SW[15:11] == 5'b10000) ? 8'd50 :
                        (SW[15:11] == 5'b01000) ? 8'd20 :
                        (SW[15:11] == 5'b00100) ? 8'd10 :
                        (SW[15:11] == 5'b00010) ? 8'd5  : 8'd1;
    assign payment_done = (paid_money >= total_price) && (total_price != 0);
    // 实验演示：用 LED 指示状态；出货完成和找零完成均由状态/剩余找零判断
    assign dispense_done = (state == S_DISPENSE);
    assign change_done = (change_left == 0);
    assign LED = led_reg;//内部寄存器连接到 LED 输出端口

    price_rom u_price1 (.product_code(code1), .price(price1));
    price_rom u_price2 (.product_code(code2), .price(price2));

    always @* begin
        total_price = ({3'b000, price1} * {5'b00000, qty1});
        if (item2_valid)
            total_price = total_price + ({3'b000, price2} * {5'b00000, qty2});
    end
//状态机模块实例化
    vending_fsm u_fsm (
        .clk_state(CLK100MHZ),
        .rst_n(CPU_RESETN),
        .confirm_pulse(confirm_pulse),
        .cancel_pulse(cancel_pulse),
        .continue_pulse(continue_pulse),
        .coin_pulse(coin_pulse),
        .change_pulse(change_pulse),
        .qty_valid(qty_valid),
        .payment_done(payment_done),
        .dispense_done(dispense_done),
        .change_done(change_done),
        .state(state)
    );
//复位逻辑，初始化所有寄存器
    always @(posedge CLK100MHZ or negedge CPU_RESETN) begin
        if (!CPU_RESETN) begin
            code1       <= 4'd0;
            code2       <= 4'd0;
            qty1        <= 2'd1;
            qty2        <= 2'd1;
            item2_valid <= 1'b0;
            paid_money  <= 8'd0;
            change_left <= 8'd0;
        end else begin         //空闲按确认，清除上次交易数据
            if (state == S_IDLE && confirm_pulse) begin
                item2_valid <= 1'b0;
                paid_money  <= 8'd0;
                change_left <= 8'd0;
            end
//商品和数量
            if (state == S_SEL1 && confirm_pulse)
                code1 <= SW[3:0];
            if (state == S_QTY1 && confirm_pulse && qty_valid)
                qty1 <= SW[5:4];

            if (state == S_SEL2 && confirm_pulse) begin
                code2 <= SW[3:0];
                item2_valid <= 1'b1;
            end
            if (state == S_QTY2 && confirm_pulse && qty_valid)
                qty2 <= SW[5:4];

            // BTNR 确认投入当前选择的硬币
            // 投币金额累加，若超过 255 则饱和到 255；8 位寄存器最大为 255
            if (state == S_PAY && coin_pulse && coin_valid) begin
                if (paid_money <= (8'd255 - coin_value))
                    paid_money <= paid_money + coin_value;
                else
                    paid_money <= 8'd255;
            end

            // 取消时退回已投币金额；付款完成时计算找零；在找零状态按 BTND 每次减 1 元
            if (state == S_PAY && cancel_pulse)
                change_left <= paid_money;
            else if (state == S_PAY && payment_done)
                change_left <= paid_money - total_price;
            else if (state == S_CHANGE && change_pulse && change_left != 0)
                change_left <= change_left - 1'b1;
        end
    end

    always @* begin
        // 状态指示：LED[0]~LED[9] 分别对应各状态
        // 数量选择无效时 LED[15] 亮起作为错误指示
        led_reg = 16'd0;
        case (state)
            S_IDLE:     led_reg[0] = 1'b1;
            S_SEL1:     led_reg[1] = 1'b1;
            S_QTY1:     led_reg[2] = 1'b1;
            S_SEL2:     led_reg[3] = 1'b1;
            S_QTY2:     led_reg[4] = 1'b1;
            S_TOTAL:    led_reg[5] = 1'b1;
            S_PAY:      led_reg[6] = 1'b1;
            S_CHANGE:   led_reg[7] = 1'b1;
            S_DISPENSE: led_reg[8] = 1'b1;
            S_BRANCH:   led_reg[9] = 1'b1;
            default:    led_reg = 16'd0;
        endcase
//数量错误指示
        error_reg = 1'b0;
        if ((state == S_QTY1 || state == S_QTY2) && !qty_valid)
            error_reg = 1'b1;
        led_reg[15] = error_reg;
    end
//显示控制器实例化
    display_controller #(.SCAN_DIV(100_000)) u_display (
        .clk(CLK100MHZ),
        .rst_n(CPU_RESETN),
        .state(state),
        .code1(code1), .qty1(qty1),
        .code2(code2), .qty2(qty2),
        .total_price(total_price),
        .paid_money(paid_money),
        .change_left(change_left),
        .seg(SEG), .an(AN), .dp(DP)
    );
endmodule