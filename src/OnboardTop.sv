`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.10.2019 17:08:01
// Design Name: 
// Module Name: OnboardTop
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


module OnboardTop(
    input   [15:0]  SW,
    output  [15:0]  LED,

    input           JB_TCK,
    input           JB_TMS,
    input           JB_TDI,
    output          JB_TDO,

    output          JBM_TCK,
    output          JBM_TMS,
    output          JBM_TDI,
    output          JBM_TDO
    );

    wire TCK, TMS, TDI, TDO;

    wire [4:0] from_SYS_to_BSR;
    wire [4:0] from_BSR_to_CL;
    wire [3:0] from_CL_to_BSR;
    wire [3:0] from_BSR_to_SYS;

    assign from_SYS_to_BSR = SW[15:11];
    assign LED[15:12] = from_BSR_to_SYS;

    assign TDI = JB_TDI;
    assign TMS = JB_TMS;
    assign TCK = JB_TCK;
    assign JB_TDO = TDO;

    assign JBM_TCK = JB_TCK;
    assign JBM_TDI = JB_TDI;
    assign JBM_TMS = JB_TMS;
    assign JBM_TDO = TDO;

DebugSYS debugsys1(
    .TCK(TCK),
    .TMS(TMS),
    .TDI(TDI),
    .TDO(TDO),

    .from_SYS_to_BSR(from_SYS_to_BSR),
    .from_BSR_to_CL(from_BSR_to_CL),
    .from_CL_to_BSR(from_CL_to_BSR),
    .from_BSR_to_SYS(from_BSR_to_SYS)
    );

CoreLogic corelogic1(
    .A(from_BSR_to_CL[4:3]),
    .B(from_BSR_to_CL[2:1]),
    .op_code(from_BSR_to_CL[0]),
    .result(from_CL_to_BSR)
    );
endmodule
