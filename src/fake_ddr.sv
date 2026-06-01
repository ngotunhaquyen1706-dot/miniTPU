`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 05/20/2026 10:55:43 PM
// Design Name:
// Module Name: fake_ddr
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


module fake_ddr #(
    parameter DATA_W    = 8,
    parameter ADDR_W    = 16,
    parameter LEN_W     = 8, //do dai burst
    parameter LATENCY   = 20,
    parameter MEM_DEPTH = 65536
    )(
    input clk,
    input rst_n,

    //Kenh request doc (Tu DMA)
    input              req_valid,   //DMA thong bao request hop le
    output reg         req_ready,   //DDR san sang nhan request
    input [ADDR_W-1:0] req_addr, //dia chi bat dau truy cap bo nho
    input [LEN_W-1:0]  req_len, // do dai burst yeu cau

    //Kenh WRITE (Ghi du lieu vao)
    input              wdata_valid, //tin hieu yeu cau ghi
    input [ADDR_W-1:0] waddr,
    input signed [DATA_W-1:0] wdata,

    //KENH READ DATA STREAM
    output reg              data_valid, //(tu DDR gui ra thong bao san sang doc data)
    input                   data_ready, //(tu DMA)
    output reg signed [DATA_W-1:0] data,
    output reg data_last
    );

    // Khai bao bo nho noi bo
    reg signed [DATA_W-1:0] mem [0:MEM_DEPTH-1];

    //1. READ DATA
    //FSM quan ly toan bo qua trinh xu ly transaction(giao dich) doc du lieu
    localparam S_IDLE   = 2'd0; // trang thai ranh -> req_ready dua len muc 1 de san sang nhan request tu DMA
    localparam S_WAIT   = 2'd1; // mo phong do tre thuc te cua ddr
    localparam S_STREAM = 2'd2; //trang thai truyen du lieu lien tuc theo burst

    reg [1:0] state;

    // Registers
    reg [ADDR_W-1:0] addr_reg; //luu dia chi bat dau cua data ma DMA yeu cau
    reg [LEN_W-1:0]  len_reg;  // luu do dai burst ma DMA yeu cau
    reg [LEN_W-1:0]  beat_cnt; //dem so luong du lieu da truyen di thanh cong
    reg [31:0]       latency_cnt; // dem so clk de mo phong do tre cua ddr

    // Dinh nghia cac vung nho
    localparam ADDR_A_START = 0;      // Matrix A: 0 - 4095
    localparam ADDR_B_START = 4096;   // Matrix B: 4096 - 8191
    localparam ADDR_C_START = 58000;  // Matrix C: 58000-65535

    integer i;

 //=======================================================================
    // Khoi tao bo nho cho simulation
    initial begin
        // Nap A (input data)
        $readmemh("data.mem", mem, ADDR_A_START);

        // Nap B (Matrix W1)
        $readmemh("W1.mem", mem, ADDR_B_START);
    end

    //khoi tao gia tri 0 cho ma tran C
    initial begin
        // Matrix C (= 0)
        for(i = ADDR_C_START; i < ADDR_C_START + 4096; i = i + 1) begin
            mem[i] = {DATA_W{1'b0}};
        end
    end
 //=======================================================================

    // Main FSM (Dieu khien doc)
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state       <= S_IDLE;
            req_ready   <= 1'b1;

            data_valid  <= 1'b0;
            data_last   <= 1'b0;
            data        <= {DATA_W{1'b0}};

            addr_reg    <= 0;
            len_reg     <= 0;
            beat_cnt    <= 0;
            latency_cnt <= 0;
        end
        else begin

            // Default: khong phai beat cuoi
            data_last <= 1'b0;

            case(state)

                // Trang thai cho lenh doc
                S_IDLE: begin

                    req_ready  <= 1'b1;
                    data_valid <= 1'b0;

                    // req_len != 0 tranh underflow
                    if(req_valid && req_ready && (req_len != 0)) begin

                        addr_reg    <= req_addr;
                        len_reg     <= req_len;

                        beat_cnt    <= 0;
                        latency_cnt <= 0;

                        state       <= S_WAIT;

                        req_ready   <= 1'b0;
                    end
                end

                // Trang thai cho do tre (Latency)
                S_WAIT: begin

                    if(latency_cnt == LATENCY-1) begin

                        state      <= S_STREAM;
                        data_valid <= 1'b1;

                        // Kiem tra boundary memory
                        if(addr_reg < MEM_DEPTH)
                            data <= mem[addr_reg];
                        else
                            data <= {DATA_W{1'b0}};

                    end
                    else begin
                        latency_cnt <= latency_cnt + 1;
                    end
                end

                // Trang thai truyen du lieu (Burst Stream)
                S_STREAM: begin

                    if(data_valid && data_ready) begin

                        // Assert last o beat cuoi
                        if(beat_cnt == len_reg - 1) begin

                            data_last <= 1'b1;

                            // Ket thuc transaction
                            data_valid <= 1'b0;
                            req_ready  <= 1'b1;

                            state      <= S_IDLE;
                        end
                        else begin

                            beat_cnt <= beat_cnt + 1;

                            // Nap data tiep theo
                            if ((addr_reg + beat_cnt + 1) < MEM_DEPTH)
                                data <= mem[addr_reg + beat_cnt + 1];
                            else
                                data <= {DATA_W{1'b0}};
                        end
                    end
                end

                default: begin
                    state <= S_IDLE;
                end

            endcase
        end
    end

 //=======================================================================

    // Logic Ghi du lieu (Write Logic)
    // Ghi du lieu bat dong bo voi FSM doc, co the ghi bat cu luc nao
    always @(posedge clk) begin

        if (wdata_valid) begin

            // Chi cho phep ghi vao vung C
            if (waddr >= ADDR_C_START &&
                waddr < (ADDR_C_START + 4096)) begin

                mem[waddr] <= wdata;
            end
        end
    end

endmodule