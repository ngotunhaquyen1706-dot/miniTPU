`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/20/2026 06:42:56 AM
// Design Name: 
// Module Name: ping_pong_bram_banks
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


module ping_pong_bram_banks #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 10, //Depth 1024, luu duoc nhieu tile
    parameter BANKS = 4        //systolic 4x4
)(
    // Tin hieu System & Control
    input logic clk,
    input logic rst_n,
    input logic pingpong_swap,
    // Write (Tu DMA loader - nap data vao) => LOADING
    input logic dma_we, // tin hieuj cho phep ghi
    input logic [BANKS-1:0]     dma_bank_sel,//chon bank de ghi (moi bank tuong ung voi 1 hang) => one hot: 4 bit de chon 1 trong 4 bank, ?u ?i?m so v?i dùng 2 bit là d? m? r?ng thêm bank trong t??ng lai ma khong can thay doi logic chon bank, và có th? ghi ??ng th?i vào nhi?u bank n?u c?n 
    input logic [ADDR_WIDTH-1:0]  dma_waddr, //dia chi o nho de ghi du lieu vao tu DMA
    input logic signed [DATA_WIDTH-1:0]  dma_wdata, //gia tri data duoc luu vao tu DMA
    // READ (tu Address scheduler - doc song song 16 banks cung luc) => COMPUTE
    input logic         [ADDR_WIDTH-1:0] sched_raddr [0:BANKS-1],   //cung c?p 4 ??a ch? khác nhau cho 4 bank ?? d? qu?n lý quá trình skew data sang systolic array, m?i bank s? ??c theo ??a ch? riêng c?a nó
    output logic signed [DATA_WIDTH-1:0] array_rdata [0:BANKS-1]   // các giá tr? data ???c ??c ra t? 4 bank, m?i bank s? tr? v? m?t giá tr? data theo ??a ch? ?ã cung c?p b?i sched_raddr
    );
    localparam DEPTH = (1 << ADDR_WIDTH);
     // 1. Khai bao phan cung cho 4 bank thuoc set 1 va 4 banks thuoc set 2
    // Moi set bank gom 1024 address x 8 bit
    logic signed [DATA_WIDTH-1:0] b_set0 [0:BANKS-1][0:DEPTH-1];
    logic signed [DATA_WIDTH-1:0] b_set1 [0:BANKS-1][0:DEPTH-1];
    // 2. Dinh nghia thanh ghi quan ly trang thai Ping-Pong
    logic pingpong_state; // 0: Set0=Load/Set1=Compute ; 1: Set0=Compute/Set1=Load

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pingpong_state <= 1'b0;
        end else if (pingpong_swap) begin
            pingpong_state <= ~pingpong_state; // doi vai tro 2 buffer
        end
    end
// 3. Logic Ghi (Write data tu DMA vao 1 trong 2 set bank) - Luon ghi vao tap "Loading"
    // Neu pingpong_state = 0 -> ghi vao set0, doc tu set1
    // Neu pingpong_state = 1 -> ghi vao set1, doc tu set0
    integer b;
    always_ff @(posedge clk) begin
        if (dma_we) begin
            for (b = 0; b < BANKS; b = b + 1) begin
                if (dma_bank_sel[b]) begin
                    if (pingpong_state == 1'b0)
                        b_set0[b][dma_waddr] <= dma_wdata;
                    else
                        b_set1[b][dma_waddr] <= dma_wdata;
                end
            end
        end
    end

    // 4. Logic Doc (Read) - Luon doc tu tap "Compute"
    // Tao logic doc song song cho 4 bank
    always_comb begin
        for (int i = 0; i < BANKS; i++) begin
            if (pingpong_state == 1'b0)
                array_rdata[i] = b_set1[i][sched_raddr[i]]; // Set1 dang compute
            else
                array_rdata[i] = b_set0[i][sched_raddr[i]]; // Set0 dang compute
        end
    end

endmodule
