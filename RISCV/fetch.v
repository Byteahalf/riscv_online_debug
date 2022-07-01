`timescale 1ns/1ps

module fetch
#(
    parameter FIFO_DEPTH = 8
)(
    input clk,
    input rst_n,
    output [31:0] o_instr,
    output [32:0] o_pc,
    output o_valid,
    input o_next,

    input c_flush,
    input [31:0] c_pc,

    output reg [31:0] m_axi_araddr,
    output reg [7:0] m_axi_arlen,
    output reg [2:0] m_axi_arsize,
    output reg [1:0] m_axi_arburst,
    output reg m_axi_arvalid,
    input m_axi_arready,
    input [31:0] m_axi_rdata,
    input [1:0] m_axi_rresp,
    input m_axi_rlast,
    input m_axi_rvalid,
    output reg m_axi_rready
);

    wire fifo_half;
    wire fifo_empty;
    wire fifo_full;
    wire [63:0] fifo_din;
    wire [63:0] fifo_dout;
    wire signed [31:0] jal_offset;

    reg fifo_wren;
    reg [31:0] fifo_pc;
    reg [31:0] fifo_instr;
    
    reg [31:0] next_pc = 0;
    
    reg branch_din = 0;
    wire branch_dout;
    
    reg instr_jalr = 0;

    reg [1:0] fetch_stage = 0;
    reg flush_req = 0;
    reg [31:0] flush_pc;
    reg fifo_break = 0;

    assign fifo_din = {fifo_pc, fifo_instr};
    assign jal_offset = $signed({m_axi_rdata[31], m_axi_rdata[19:12], m_axi_rdata[20], m_axi_rdata[30:21], 1'b0});
    assign o_pc = {branch_dout, fifo_dout[63:32]};
    assign o_instr = fifo_dout[31:0];
    assign o_valid = ~fifo_empty;

    initial begin
        m_axi_arvalid <= 0;
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            next_pc <= 0;
            fetch_stage <= 0;
            m_axi_arlen <= FIFO_DEPTH / 2 - 1;
            m_axi_rready <= 0;
            m_axi_arsize <= 'b010;
            m_axi_arburst <= 'b01;
            instr_jalr <= 0;
        end
        else begin
            case(fetch_stage)
            0: begin
                fifo_wren <= 0;
                if(fifo_half & (c_flush | ~instr_jalr)) begin
                    m_axi_arvalid <= 1;
                    fetch_stage <= 1;
                    instr_jalr <= 0;
                    flush_req <= 0;
                    if(c_flush) begin
                        m_axi_araddr <= c_pc;
                        next_pc <= c_pc;
                    end
                    else if(flush_req) begin
                        m_axi_araddr <= flush_pc;
                        next_pc <= flush_pc;
                    end
                    else begin
                        m_axi_araddr <= next_pc;
                    end 
                end
                else if(c_flush) begin
                    flush_req <= 1;
                    flush_pc <= c_pc;
                    instr_jalr <= 0;
                end
            end
            1: begin
                if(m_axi_arready) begin
                    m_axi_rready <= 1;
                    m_axi_arvalid <= 0;
                    fetch_stage <= 2;
                end
                if(c_flush) begin
                    flush_req <= 1;
                    flush_pc <= c_pc;
                    fifo_break <= 1;
                end
            end
            2: begin
                if(c_flush) begin
                    flush_req <= 1;
                    flush_pc <= c_pc;
                    fifo_break <= 1;
                    fifo_wren <= 0;
                end
                if(m_axi_rvalid) begin
                    if(m_axi_rlast) begin
                        m_axi_rready <= 0;
                        fetch_stage <= 0;
                        fifo_break <= 0;
                    end
                    if(~fifo_break & ~c_flush) begin
                        fifo_wren <= 1;
                        fifo_pc <= next_pc;
                        fifo_instr <= m_axi_rdata;
                        case(m_axi_rdata[6:0])
                        7'b110_1111: begin
                            next_pc <= $signed(next_pc) + jal_offset;
                            fifo_break <= 1;
                        end
                        7'b110_0111: begin
                            instr_jalr <= 1;
                            fifo_break <= 1;
                        end
                        default: begin
                            next_pc <= next_pc + 4;
                        end
                        endcase
                    end
                    else begin
                        fifo_wren <= 0;
                    end
                end
                else begin
                    fifo_wren <= 0;
                end
            end
            endcase
        end
    end

    async_fifo #(
        .DATA_WIDTH(64)
    )
    fifo(
        .clk             (clk),
        .rd_en           (o_next),
        .wr_en           (fifo_wren & ~c_flush),
        .wr_data         (fifo_din),
        .rd_data         (fifo_dout),
        .full            (fifo_full),
        .empty           (fifo_empty),
        .half            (fifo_half),
        .rst_n           (!c_flush & rst_n)
    );

    async_fifo #(
        .DATA_WIDTH(1)
    )
    branch(
        .clk             (clk),
        .rd_en           (o_next),
        .wr_en           (fifo_wren & ~c_flush),
        .wr_data         (branch_din),
        .rd_data         (branch_dout),
        .rst_n           (!c_flush & rst_n)
    );
    
endmodule