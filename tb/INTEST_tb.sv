`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.12.2019 4:21:10
// Design Name: 
// Module Name: INTEST_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module INTEST_tb(

    );
    reg TCK, TMS, TDI;
    wire TDO;

    reg [15:0] SW;
    wire [15:0] LED;

    // Устанавливаем на переключателях SW значение "10011" - A = 10, B = 01, op = 1 (+); На соответствующих выводах LED должно получиться значение "0011"
    // После этого, с использованием команды SAMPLE/PRELOAD загружаем в BSR 9 бит "101101001". BSR "на вход" будет содержать "01110" - A = 10, B = 11, Op = 0 (*)
    // Выполняем INTEST и проверяем значение на выходных контактах Core_Logic и на контактах, ведущих из BSR в Core_Logic
    initial begin
        TCK = 0;
        TMS = 0;
        TDI = 0;
        SW = 16'b1001100000000000;

        #10 TMS = 0; // IDLE

        if (LED[15:12] != 4'b0011)
            $display("Initial value setiing FAILED!");
        else
            $display("Initial value setiing PASSED!");

        #10 TMS = 1; // SELECT_DR
        #10 TMS = 1; // SELECT_IR
        #10 TMS = 0; // CAPTURE_IR
        #10 TMS = 0; // SHIFT_IR
        #10 TMS = 0;
            TDI = 1; // SHIFT 1
        #10 TMS = 0;
            TDI = 0; // SHIFT 2
        #10 TMS = 0;
            TDI = 0; // SHIFT 3
        #10 TMS = 1; // EXIT1_IR
            TDI = 0; // SHIFT 4
        #10 TMS = 1; // UPDATE_IR
        #10 TMS = 1; // SELECT_DR
        #10 TMS = 0; // CAPTURE_DR
        #10 TMS = 0; // SHIFT_DR
        #10 TMS = 0;
            TDI = 1; // SHIFT 1
        #10 TMS = 0;
            TDI = 0; // SHIFT 2
        #10 TMS = 0;
            TDI = 0; // SHIFT 3
        #10 TMS = 0;
            TDI = 1; // SHIFT 4
        #10 TMS = 0;
            TDI = 0; // SHIFT 5
        #10 TMS = 0;
            TDI = 1; // SHIFT 6
        #10 TMS = 0;
            TDI = 1; // SHIFT 7
        #10 TMS = 0;
            TDI = 0; // SHIFT 8
        #10 TMS = 1; // EXIT1_DR
            TDI = 1; // SHIFT 9
        #10 TMS = 1; // UPDATE_DR

        #10 TMS = 1; // Select_DR
        #10 TMS = 1; // Select_R
        #10 TMS = 0; // Caprture_IR
        #10 TMS = 0; // Shift_IR
        #10 TMS = 0;
            TDI = 1; // SHIFT 1
        #10 TMS = 0;
            TDI = 1; // SHIFT 2
        #10 TMS = 0;
            TDI = 0; // SHIFT 3
        #10 TMS = 1; // EXIT_IR
            TDI = 0; // SHIFT 4
        #10 TMS = 1; // Update_IR
        #30
        if (top1.from_BSR_to_CL != 5'b10110 || top1.from_CL_to_BSR != 4'b0110)
            $display("FAILED!");
        else
            $display("PASSED!");
    end

    always #5 TCK = ~TCK;

    OnboardTop top1(
        .SW(SW),
        .LED(LED),

        .JB_TCK(TCK),
        .JB_TMS(TMS),
        .JB_TDI(TDI),
        .JB_TDO(TDO)
        );
endmodule
