`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.12.2019 2:13:55
// Design Name: 
// Module Name: IDCODE_tb
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


module IDCODE_tb(

    );
    reg TCK, TMS, TDI;
    wire TDO;

    reg [15:0] SW;
    wire [15:0] LED;

    initial begin
        TCK = 0;
        TMS = 0;
        TDI = 0;
        SW = 0;

        #15 TMS = 0; // IDLE
        #10 TMS = 1; // SELECT_DR
        #10 TMS = 1; // SELECT_IR
        #10 TMS = 0; // CAPTURE_IR
        #10 TMS = 0; // SHIFT_IR
        #10 TMS = 0;
            TDI = 0; // SHIFT 1
        #10 TMS = 0;
            TDI = 0; // SHIFT 2
        #10 TMS = 0;
            TDI = 1; // SHIFT 3
        #10 TMS = 1; // EXIT1_IR
            TDI = 0; // SHIFT 4
        #10 TMS = 1; // UPDATE_IR
        #10 TMS = 1; // SELECT_DR
        #10 TMS = 0; // CAPTURE_DR
        #10 TMS = 0; // shift_DR
        #310 TMS = 0; // Находимся в состоянии SHIFT_DR на протяжении 31 фронта TCK
        #10 TMS = 1; // EXIT1_DR
        #10 TMS = 1; // UPDATE_UPDATE

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
