// 时间刻度定义：时间单位1ns，时间精度1ps
`timescale 1ns / 1ps

// 自动售货机顶层模块测试平台
module vending_top_tb;
    //  输入信号定义（reg类型） 
    reg CLK100MHZ = 1'b0;     
    reg CPU_RESETN = 1'b0;     
    reg [15:0] SW = 16'd0;     
    reg BTNC = 1'b0;           
    reg BTNU = 1'b0;           
    reg BTNL = 1'b0;           
    reg BTNR = 1'b0;           
    reg BTND = 1'b0;           

    // ========== 输出信号定义（wire类型） ==========
    wire [15:0] LED;                                            

    // ========== 内部信号监测（用于测试验证） ==========
    wire [3:0] state;         
    wire [3:0] code1;         
    wire [3:0] code2;          
    wire [1:0] qty1;          
    wire [1:0] qty2;         
    wire [3:0] price1;        
    wire [3:0] price2;        
    wire [7:0] total_price;   
    wire [7:0] paid_money;    
    wire [7:0] change_left;  
    wire [7:0] coin_value;   
    wire coin_valid;           
    wire [31:0] display_digits;

    // ========== 去抖动测试相关信号 ==========
    reg debounce_key = 1'b0;   
    wire debounce_pulse;       
    integer debounce_pulse_count = 0; 

    // ========== 实例化被测模块 ==========
    vending_top dut (
        .CLK100MHZ(CLK100MHZ),
        .CPU_RESETN(CPU_RESETN),
        .SW(SW),
        .BTNC(BTNC),
        .BTNU(BTNU),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTND(BTND),
        .LED(LED)
    );

    // ========== 实例化按键去抖动测试模块 ==========
    // 去抖动周期设为2个时钟周期（用于快速测试）
    key_pulse #(.DEBOUNCE_CYCLES(2)) u_debounce_test (
        .clk(CLK100MHZ),
        .rst_n(CPU_RESETN),
        .key_in(debounce_key),
        .pulse(debounce_pulse)
    );

    // ========== 连接内部信号以便监测 ==========
    assign state = dut.state;
    assign code1 = dut.code1;
    assign code2 = dut.code2;
    assign qty1 = dut.qty1;
    assign qty2 = dut.qty2;
    assign price1 = dut.price1;
    assign price2 = dut.price2;
    assign total_price = dut.total_price;
    assign paid_money = dut.paid_money;
    assign change_left = dut.change_left;
    assign coin_value = dut.coin_value;
    assign coin_valid = dut.coin_valid;

    // 拼接8个数码管的显示内容（每个4位BCD码）
    // 32位 = d7[31:28] d6[27:24] d5[23:20] d4[19:16] d3[15:12] d2[11:8] d1[7:4] d0[3:0]
    assign display_digits = {
        dut.u_display.d7, dut.u_display.d6,
        dut.u_display.d5, dut.u_display.d4,
        dut.u_display.d3, dut.u_display.d2,
        dut.u_display.d1, dut.u_display.d0
    };

    // ========== 时钟生成 ==========
    // 每5ns翻转一次，生成周期为10ns的100MHz时钟
    always #5 CLK100MHZ = ~CLK100MHZ;

    // ========== 去抖动脉冲计数 ==========
    always @(posedge CLK100MHZ) begin
        if (debounce_pulse)
            debounce_pulse_count = debounce_pulse_count + 1;
    end

    // ========== 任务：模拟按键按下 ==========
    // 输入：key_sel - 按键选择（0=BTNC, 1=BTNL, 2=BTNU, 3=BTNR, 4=BTND）
    task press_button;
        input [2:0] key_sel;
        begin
            @(negedge CLK100MHZ);  
            case (key_sel)
                3'd0: begin BTNC = 1'b1; force dut.confirm_pulse = 1'b1; end   // 确认
                3'd1: begin BTNL = 1'b1; force dut.cancel_pulse = 1'b1; end    // 取消
                3'd2: begin BTNU = 1'b1; force dut.continue_pulse = 1'b1; end  // 继续
                3'd3: begin BTNR = 1'b1; force dut.coin_pulse = 1'b1; end      // 投币
                3'd4: begin BTND = 1'b1; force dut.change_pulse = 1'b1; end    // 找零
            endcase
            @(negedge CLK100MHZ);  
            case (key_sel)
                3'd0: begin BTNC = 1'b0; release dut.confirm_pulse; end
                3'd1: begin BTNL = 1'b0; release dut.cancel_pulse; end
                3'd2: begin BTNU = 1'b0; release dut.continue_pulse; end
                3'd3: begin BTNR = 1'b0; release dut.coin_pulse; end
                3'd4: begin BTND = 1'b0; release dut.change_pulse; end
            endcase
            #1;  // 短暂延迟
        end
    endtask

    // ========== 任务：检查状态是否正确 ==========
    task check_state;
        input [3:0] expected;
        begin
            if (state !== expected)
                $fatal(1, "State expected %h, got %h", expected, state);
        end
    endtask

    // ========== 任务：检查状态LED是否正确 ==========
    task check_state_led;
        input integer led_index;
        begin
            if (LED !== (16'b1 << led_index))
                $fatal(1, "State LED expected LD%0d, got %h", led_index, LED);
        end
    endtask

    // ========== 任务：检查硬币解码器 ==========
    task check_coin_decode;
        input [4:0] selector;          // 硬币选择器（开关SW[15:11]）
        input [7:0] expected_value;    // 期望的硬币面值
        begin
            SW[15:11] = selector;
            #1;
            if (!coin_valid || coin_value !== expected_value)
                $fatal(1, "Coin selector %b decode error", selector);
        end
    endtask

    // ========== 主测试序列 ==========
    initial begin
        // ===== 初始化 =====
        SW = 16'd16;               // 二进制00010000
        #30;                      
        CPU_RESETN = 1'b1;        
        repeat (6) @(posedge CLK100MHZ);  

        // 检查初始状态：待机状态（state=0，LED[0]点亮，显示00000000）
        check_state(4'h0);
        check_state_led(0);
        if (display_digits !== 32'h00000000)
            $fatal(1, "Standby display is not 00000000");

        // ===== 测试1：按键去抖动功能 =====
        debounce_key = 1'b1;      
        repeat (12) @(posedge CLK100MHZ);
        debounce_key = 1'b0;     
        repeat (12) @(posedge CLK100MHZ);
        // 检查是否只产生1个脉冲
        if (debounce_pulse_count !== 1)
            $fatal(1, "Key debounce pulse count expected 1, got %0d", debounce_pulse_count);
        $display("TEST 1 key_pulse PASS");

        // ===== 测试2：硬币解码器功能 =====
        // 测试5种硬币面值
        check_coin_decode(5'b10000, 8'd50);  
        check_coin_decode(5'b01000, 8'd20); 
        check_coin_decode(5'b00100, 8'd10);  
        check_coin_decode(5'b00010, 8'd5);  
        check_coin_decode(5'b00001, 8'd1);   

        // 测试无效情况
        SW[15:11] = 5'b00000;      // 没有选择任何硬币
        #1;
        if (coin_valid)
            $fatal(1, "Zero coin selection must be invalid");
        SW[15:11] = 5'b11000;      // 选择多个硬币
        #1;
        if (coin_valid)
            $fatal(1, "Multiple coin selection must be invalid");
        $display("TEST 2 coin decoder PASS");

        // ===== 测试3：确认和取消按钮 =====
        SW = 16'd16;
        press_button(3'd0);        
        check_state(4'h1);        
        check_state_led(1);
        press_button(3'd1);        
        check_state(4'h0);        
        check_state_led(0);
        $display("TEST 3 BTNC and BTNL PASS");

        // ===== 测试4：商品选择和数量锁存 =====
        SW = 16'd16;             
        press_button(3'd0);      
        check_state(4'h1);
        press_button(3'd0);       
        check_state(4'h2);
        // 检查商品1：编码0，价格3元
        if (code1 !== 4'h0 || price1 !== 4'd3)
            $fatal(1, "Product 1 code or price error");
        press_button(3'd0);        
        check_state(4'hf);        
        check_state_led(9);
        // 检查商品1数量为1
        if (qty1 !== 2'd1)
            $fatal(1, "Product 1 quantity error");

        SW = 16'd17;               // 选择商品2
        press_button(3'd2);        
        check_state(4'h3);
        check_state_led(3);
        press_button(3'd0);       
        check_state(4'h4);
        // 检查商品2：编码1，价格4元
        if (code2 !== 4'h1 || price2 !== 4'd4)
            $fatal(1, "Product 2 code or price error");
        press_button(3'd0);        // 确认商品2数量
        check_state(4'h5);
        check_state_led(5);
        // 检查商品2数量为1，总价为7元
        if (qty2 !== 2'd1 || total_price !== 8'd7)
            $fatal(1, "Product 2 quantity or total error");
        $display("TEST 4 product and quantity latch PASS");

        // ===== 测试5：支付和找零金额 =====
        press_button(3'd0);        // 进入支付状态
        check_state(4'h6);
        check_state_led(6);
        // 检查支付界面显示：商品1编码01 商品2编码11 总价07 已付00
        if (display_digits !== 32'h01110700)
            $fatal(1, "Payment display expected 01110700, got %h", display_digits);

        // 投入第一个5元硬币
        SW[15:11] = 5'b00010;      // 选择5元硬币
        press_button(3'd3);        
        if (paid_money !== 8'd5 || state !== 4'h6)
            $fatal(1, "First 5-yuan coin error");
        // 检查显示的已付金额为05
        if (display_digits[7:0] !== 8'h05)
            $fatal(1, "Paid display expected 05");

        // 投入第二个5元硬币
        press_button(3'd3);
        if (paid_money !== 8'd10)
            $fatal(1, "Second 5-yuan coin error");
        // 检查显示的已付金额为10
        if (display_digits[7:0] !== 8'h10)
            $fatal(1, "Paid display expected 10");

        // 等待自动进入找零状态
        repeat (3) @(posedge CLK100MHZ);
        #1;
        check_state(4'h7);         // 应自动进入找零状态
        check_state_led(7);
        // 检查找零金额：10-7=3元
        if (change_left !== 8'd3)
            $fatal(1, "Change expected 3, got %0d", change_left);
        if (display_digits[7:0] !== 8'h03)
            $fatal(1, "Change display expected 03");
        $display("TEST 5 payment and change amount PASS");

        // ===== 测试6：找零按钮和返回待机 =====
        // 按第一次BTND，找零1元
        press_button(3'd4);
        if (change_left !== 8'd2 || state !== 4'h7)
            $fatal(1, "First BTND change error");
        // 按第二次BTND，找零1元
        press_button(3'd4);
        if (change_left !== 8'd1 || state !== 4'h7)
            $fatal(1, "Second BTND change error");
        // 按第三次BTND，找零1元
        press_button(3'd4);
        if (change_left !== 8'd0 || state !== 4'h7)
            $fatal(1, "Third BTND change error");
        // 找零完成后自动返回待机状态
        @(posedge CLK100MHZ);
        #1;
        check_state(4'h0);
        check_state_led(0);
        if (display_digits !== 32'h00000000)
            $fatal(1, "Final standby display error");
        $display("TEST 6 BTND and standby return PASS");

        // ===== 测试7：无效数量测试 =====
        SW = 16'd0;                // 开关设为0（数量为0，无效）
        press_button(3'd0);        // 进入状态1
        press_button(3'd0);        // 进入状态2
        check_state(4'h2);
        press_button(3'd0);        // 尝试确认数量0
        check_state(4'h2);         // 应保持在状态2
        // 检查LED[15]点亮（表示错误）
        if (!LED[15])
            $fatal(1, "Invalid quantity LED15 error");
        $display("TEST 7 invalid quantity PASS");

        // ===== 所有测试通过 =====
        $display("vending_top_tb ALL TESTS PASS");
        $finish;
    end
endmodule
