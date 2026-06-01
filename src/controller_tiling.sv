`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/21/2026 05:11:28 PM
// Design Name: 
// Module Name: tiling_engine
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


module controller_tiling(

    input clk,
    input rst_n,

    input start_proc, //khoi tao quy trinh tiling 1 ma tran
    input matrix_sel,//chon ma tran A hay B de nap vao ping-pong buffer   0: A, 1: B
    input dma_done, //tin hieu tu DMA bao da hoan thanh nap/ghi xong 1 tile
    output reg dma_start, //kich hoat DMA bat dau 1 transaction
    output reg [31:0] dma_addr, //dia chi tuyet doi trong DDR dua tren cong thuc base+offset
    output reg [16:0] dma_len //do dai du lieu cua 1 tile
);

    localparam BASE_A = 0;
    localparam BASE_B = 4096;
    localparam BASE_C = 58000;

    localparam MAT_DIM   = 64; //matrix dimension
    localparam TILE_DIM  = 4;
    localparam NUM_TILES = MAT_DIM / TILE_DIM; //so luong cac tile 
    
    reg [4:0] tile_r, tile_c;// tile row, tile column 
    reg [2:0] line_cnt; // Bo dem so hang trong 1 tile (0 to 3)

    // FSM state  0: idle  1: setup_dma  2: wait_dma   3: done

    reg [2:0] state;
    reg [31:0] current_base;

//===========================================================================
    // chon base address

    always @(*) begin
        case(matrix_sel)
            1'b0: current_base = BASE_A;
            1'b1: current_base = BASE_B;
            default: current_base = BASE_A;
        endcase
    end

//=============================================================================
    // FSM

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            tile_r <= 0;
            tile_c <= 0;
            line_cnt <= 0;
            dma_start <= 0;
            dma_addr  <= 0;
            dma_len   <= 0;
        end
        else begin
            // default pulse
            dma_start <= 0;

            case (state)
                //===============================================
                // IDLE
                0: begin
                    tile_r   <= 0;
                    tile_c   <= 0;
                    line_cnt <= 0;

                    if (start_proc)
                        state <= 1;
                end
                //================================================
                // SETUP DMA
                1: begin
                    // Tinh toan dia chi va do dai cho 1 tile
                    // offset = (tile_r * TILE_DIM * MAT_DIM) + (tile_c * TILE_DIM)
                    // Cong them offset cua tung dong
                    // (line_cnt * MAT_DIM)
                    dma_addr <= current_base +
                               ((tile_r * TILE_DIM * MAT_DIM) +
                               (tile_c * TILE_DIM)) +
                               (line_cnt * MAT_DIM);
                    dma_len <= TILE_DIM;
                    // Pulse 1 cycle
                    dma_start <= 1;
                    state <= 2;
                end

                //======================================================
                // WAIT DMA
                2: begin

                    if (dma_done) begin
                        // Neu chua lay du 4 dong cua tile
                        if (line_cnt < TILE_DIM - 1) begin
                            line_cnt <= line_cnt + 1;
                            state <= 1;
                        end
                        else begin
                            // reset line count
                            line_cnt <= 0;
                            // Tang bo dem tile
                            if (tile_c == NUM_TILES - 1) begin
                                tile_c <= 0;
                                if (tile_r == NUM_TILES - 1)
                                    state <= 3;
                                else begin
                                    tile_r <= tile_r + 1;
                                    state <= 1;
                                end
                            end
                            else begin
                                tile_c <= tile_c + 1;
                                state <= 1;
                            end
                        end
                    end
                end

                //======================================================
                // DONE
                3: begin
                    // Cho phep restart
                    if (!start_proc)
                        state <= 0;
                end

                default: begin
                    state <= 0;
                end

            endcase
        end
    end

endmodule