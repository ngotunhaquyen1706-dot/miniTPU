`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2026 04:03:29 PM
// Design Name: 
// Module Name: systolic_output_reg
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


module systolic_output_reg #(
    parameter DATA_WIDTH = 32, // ?ã ??i t? 8 -> 32
    parameter N          = 4
)(
    input  wire clk,
    input  wire rst_n,
    input  wire ps_en,
    input  wire [N*DATA_WIDTH-1:0] ps_in_row0,
    input  wire [N*DATA_WIDTH-1:0] ps_in_row1,
    input  wire [N*DATA_WIDTH-1:0] ps_in_row2,
    input  wire [N*DATA_WIDTH-1:0] ps_in_row3,
    output reg  out_valid,
    output reg  [N*DATA_WIDTH-1:0] data_out,
    input  wire out_ready
);
    reg [N*DATA_WIDTH-1:0] rows [0:3]; // M?ng l?u 4 hàng 128-bit
    reg [2:0] state;
    localparam IDLE = 0, SEND_R0 = 1, SEND_R1 = 2, SEND_R2 = 3, SEND_R3 = 4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; out_valid <= 0; data_out <= 'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (ps_en) begin
                        rows[0] <= ps_in_row0; rows[1] <= ps_in_row1;
                        rows[2] <= ps_in_row2; rows[3] <= ps_in_row3;
                        state <= SEND_R0;
                    end
                    out_valid <= 0;
                end
                SEND_R0: begin data_out <= rows[0]; out_valid <= 1; if(out_ready) state <= SEND_R1; end
                SEND_R1: begin data_out <= rows[1]; if(out_ready) state <= SEND_R2; end
                SEND_R2: begin data_out <= rows[2]; if(out_ready) state <= SEND_R3; end
                SEND_R3: begin data_out <= rows[3]; if(out_ready) begin out_valid <= 0; state <= IDLE; end end
            endcase
        end
    end
endmodule