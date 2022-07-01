`timescale 1ns/1ps

module pc_stream(
    input clk,
    input rst_n,
    
    input [31:0] i_pc,
    input i_pc_valid,
    input i_error,

    output reg M_AXIS_tvalid,
    input M_AXIS_tready,
    output reg [15:0] M_AXIS_tdata,
    output reg M_AXIS_tlast
);

    reg fifo_rden = 0;
    wire [31:0] fifo_dout;
    wire fifo_empty;

    reg axis_stage = 0;
    reg error = 0;

    always @(posedge clk) begin
        if(!rst_n) begin
            M_AXIS_tvalid <= 0;
            M_AXIS_tdata <= 0;
        end
        else begin
            case(axis_stage)
            0: begin
                if(~error) begin
                    if(~fifo_empty) begin
                        axis_stage <= 1;
                        M_AXIS_tvalid <= 1;
                        M_AXIS_tdata <= fifo_dout;
                        fifo_rden <= 1;
                    end
                    else if(i_error) begin
                        error <= 1;
                        M_AXIS_tvalid <= 1;
                        M_AXIS_tdata <= 1;
                        M_AXIS_tlast <= 1;
                        axis_stage <= 1;
                    end
                end
            end
            1: begin
                fifo_rden <= 0;
                if(M_AXIS_tready) begin
                    axis_stage <= 0;
                    M_AXIS_tvalid <= 0;
                    M_AXIS_tlast <= 0;
                end
            end
            endcase 
        end
    end

    sync_fifo#(
        .DATA_DEPTH   (32),
        .DATA_WIDTH   (32)
    ) fifo (
        .clk      (clk),
        .rst_n    (rst_n),
        .rd_en    (fifo_rden),
        .wr_en    (i_pc_valid),
        .wr_data  (i_pc),
        .rd_data  (fifo_dout),
        .empty    (fifo_empty)
    );

    
endmodule