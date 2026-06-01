`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2026 05:09:47 PM
// Design Name: 
// Module Name: PE
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


module PE(

    input clk,
    input rst, init, en,
    input valid_in,                       // valid_in follow data_in, only data feeded, valid_in =1
    input   signed  [7:0]   a,            // Q1.7 : 1 bit for sign, 7 bits for fraction
    input   signed  [7:0]   b,


    output  signed  [7:0]   a_out,
    output  signed  [7:0]   b_out,
    output  signed  [31:0]  c_out,         // Q1.31 : 1 bit for sign, 31 bits for fraction
    output  reg             valid_out      // and b are multiplied => 8 bits * 8 bits = 16 bits,                                        // and then accumulated => 16 bits + 16 bits + ... = 32 bits 
);

//======register pipeline 1=============
reg                 valid_reg_1, init_reg_1;
reg signed [7:0]    a_reg, b_reg;
reg signed [31:0]   acc;
//======register pipeline 2=============
reg valid_reg_2, init_reg_2;
reg signed [15:0]   mult;




always @(posedge clk) begin

    if (rst) begin
    
        a_reg         <= 0;             
        b_reg         <= 0;
        acc           <= 0;
        valid_reg_1   <= 0;
        init_reg_1    <= 0;
        mult          <= 0;
        valid_reg_2   <= 0;
        init_reg_2    <= 0;
        valid_out     <= 0;
    end 
                                          //clk 1: PE receive a, b
                                          //clk 2: PE compute acc = acc + ab => delay 1 clk
    else if(en) begin

    // stage 1: input register
        a_reg        <= a;                     //  <= = update after clock edge (parallel)
        b_reg        <= b;                     // clk = 0: update a_reg, b_reg; clk = 1: update acc
        valid_reg_1  <= valid_in;
        init_reg_1   <= init;
        valid_out <= valid_reg_2;
    // stage 2: compute a*b
        
        mult        <= $signed(a_reg) * $signed(b_reg);
        valid_reg_2 <= valid_reg_1;
        init_reg_2  <= init_reg_1;

    //stage 3: MAC
        if(valid_reg_2) begin

            if(init_reg_2) 
                acc <= mult;         
            else 
                acc <= acc + mult; 
        end
    end
end 

assign a_out = a_reg;
assign b_out = b_reg;
assign c_out = acc;         

endmodule
