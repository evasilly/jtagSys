`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.12.2019 2:13:55
// Design Name: 
// Module Name: SAMPLE_PRELOAD_tb
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


module SAMPLE_PRELOAD_tb(

    );
    reg TCK, TMS, TDI;
    wire TDO;

    reg [15:0] SW;
    wire [15:0] LED;

    // В ходе теста загрузим в BSR 9 бит "011101001". После загрузки BSR "на вход" будет содержать "01110" - A = 01, B = 11,
    // Op = 0. BSR "на выход" - 1001
    initial begin
        TCK = 0;
        TMS = 0;
        TDI = 0;
        SW = 0;

        #10 TMS = 0; // IDLE
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
            TDI = 1; // SHIFT 8
        #10 TMS = 1; // EXIT1_DR
            TDI = 0; // SHIFT 9
        #10 TMS = 1; // UPDATE_DR
        #30
        if(top1.debugsys1.main_BSR != 9'b011101001)
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
