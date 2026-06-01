`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/27/2026 04:17:58 PM
// Design Name: 
// Module Name: tile
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


module Tile #(
    parameter ROW = 4,
    parameter COL = 4
)(
    input wire clk, rst, init, en, compute_done,
    // Chuy?n m?ng valid_in sang d?ng ph?ng ?? tránh l?i port
    input wire [ROW-1:0] valid_in, 

    // Chuy?n ia, ib sang d?ng ph?ng (ROW*8 bit)
    input  wire [ROW*8-1:0] ia_flat, 
    input  wire [COL*8-1:0] ib_flat,

    // Outputs ph?ng
    output wire [ROW*8-1:0] oa_flat, 
    output wire [COL*8-1:0] ob_flat,

    output reg  [ROW*COL*32-1:0] matrix_out,
    output reg  matrix_valid
);

    // X? lý chuy?n ??i ph?ng -> m?ng n?i b?
    wire signed [7:0] ia [ROW-1:0];
    wire signed [7:0] ib [COL-1:0];
    genvar g;
    generate
        for(g=0; g<ROW; g=g+1) assign ia[g] = ia_flat[g*8 +: 8];
        for(g=0; g<COL; g=g+1) assign ib[g] = ib_flat[g*8 +: 8];
    endgenerate

    // Interconnections
    wire inter_valid [ROW-1:0][COL-1:0];
    wire signed [7:0] in_a [ROW-1:0][COL-1:0];
    wire signed [7:0] in_b [ROW-1:0][COL-1:0];
    wire signed [31:0] c [ROW-1:0][COL-1:0];

    // Kh?i ?i?u khi?n (DEPTH = ROW + COL - 1 = 7 cho 4x4)
    wire [ROW+COL-2:0] init_delay;
    initControl #(.DEPTH(ROW+COL-1)) init_block(
        .clk(clk), .rst(rst), .en(en), .init(init), .initFF(init_delay)
    );

    // M?ng PE
    genvar i, j;
    generate
        for (i = 0; i < ROW; i = i + 1) begin : ROW_
            for (j = 0; j < COL; j = j + 1) begin : COL_
                PE pe_block(
                    .clk(clk), .rst(rst),
                    .init(init_delay[i+j]), .en(en),
                    .valid_in( (j==0) ? valid_in[i] : inter_valid[i][j-1] ),
                    .a( (j==0) ? ia[i] : in_a[i][j-1] ),
                    .b( (i==0) ? ib[j] : in_b[i-1][j] ),
                    .a_out(in_a[i][j]),
                    .b_out(in_b[i][j]),
                    .c_out(c[i][j]),
                    .valid_out(inter_valid[i][j])
                );
            end
        end
    endgenerate

    // Gán tín hi?u c?nh ph?ng
    generate
        for (i = 0; i < ROW; i = i + 1) assign oa_flat[i*8 +: 8] = in_a[i][COL-1];
        for (j = 0; j < COL; j = j + 1) assign ob_flat[j*8 +: 8] = in_b[ROW-1][j];
    endgenerate

    // Logic ?óng gói k?t qu?
    integer r, c_idx;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            matrix_out   <= 'b0;
            matrix_valid <= 1'b0;
        end else if (compute_done) begin
            matrix_valid <= 1'b1;
            for (r = 0; r < ROW; r = r + 1) begin
                for (c_idx = 0; c_idx < COL; c_idx = c_idx + 1) begin
                    matrix_out[(r*COL + c_idx)*32 +: 32] <= c[r][c_idx];
                end
            end
        end else begin
            matrix_valid <= 1'b0;
        end
    end
endmodule