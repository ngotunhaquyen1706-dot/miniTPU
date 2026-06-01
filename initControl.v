`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2026 05:16:46 PM
// Design Name: 
// Module Name: initControl
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


module initControl #(

    parameter DEPTH = 7

    )(

    input               clk, rst, en,
    input               init,

    output reg [DEPTH-1:0]   initFF

);


integer k;


always @(posedge clk) begin

    if(rst) 
        initFF <= {DEPTH{1'b0}};

    else if(en) begin
        
        initFF[0] <= init;

        for(k =1; k < DEPTH; k = k+1) 
            initFF[k] <= initFF[k-1];
    end
end

endmodule
