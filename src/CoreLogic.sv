`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.10.2019 17:01:28
// Design Name: 
// Module Name: CoreLogic
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


module CoreLogic(
    input [1:0] A,
    input [1:0] B,
    input op_code,
    output [3:0] result
    );
    assign result = (op_code == 1'b1) ? A + B : A * B;
endmodule
