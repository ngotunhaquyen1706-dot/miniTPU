`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/22/2026 03:19:21 AM
// Design Name: 
// Module Name: axi_master
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


module axi_master (
    input clk,
    input rst_n,

    // Giao tiep voi Tiling Engine (Control Plane)
    input             dma_start,
    input      [31:0] dma_addr,
    input      [16:0] dma_len,
    output reg        dma_done,

    // Giao tiep voi Fake DDR (AXI Slave Interface)
    output reg        req_valid,
    input             req_ready,
    output reg [15:0] req_addr,
    output reg [7:0]  req_len,
    
    input             data_valid,
    output reg        data_ready,
    input             data_last
);

    // Trang thai FSM
    localparam S_IDLE       = 3'd0;
    localparam S_WAIT_READY = 3'd1;
    localparam S_READING    = 3'd2;
    localparam S_DONE       = 3'd3;

    reg [2:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            req_valid  <= 1'b0;
            data_ready <= 1'b0;
            dma_done   <= 1'b0;
            req_addr   <= 16'd0;
            req_len    <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    dma_done <= 1'b0;
                    if (dma_start) begin
                        req_addr  <= dma_addr[15:0]; // lay 16 bit dia chi
                        req_len   <= dma_len[7:0];   // do dai 1 burst
                        req_valid <= 1'b1;
                        state     <= S_WAIT_READY;
                    end
                end

                S_WAIT_READY: begin
                    if (req_ready) begin
                        req_valid  <= 1'b0;       
                        data_ready <= 1'b1;        
                        state      <= S_READING;
                    end
                end

                S_READING: begin
                    // Nhan du lieu tung nhip clk cho den khi dma_last bao ket thuc
                    if (data_valid && data_last) begin
                        data_ready <= 1'b0;
                        dma_done   <= 1'b1;        // bao xong 1 luot truyen
                        state      <= S_DONE;
                    end
                end

                S_DONE: begin
                    dma_done <= 1'b0;
                    state    <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule