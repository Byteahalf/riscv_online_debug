`timescale 1ns/1ps

module wrb(
    input clk,
    input rst_n,

    input i_regen,
    input i_memen,
    input [2:0] i_memstrb,
    input [31:0] i_data,
    input [4:0] i_rd,
    input [31:0] i_memdata,
    input i_valid,
    output reg i_next,
    
    output reg c_error,

    output m_axi_clk,
    output m_axi_rst_n,
    output reg m_axi_awvalid,
    input m_axi_awready,
    output reg [31:0] m_axi_awaddr,
    output reg m_axi_wvalid,
    input m_axi_wready,
    output reg [31:0] m_axi_wdata,
    input m_axi_bvalid,
    output reg m_axi_bready,
    input [1:0] m_axi_bresp,
    output reg m_axi_arvalid,
    input m_axi_arready,
    output reg [31:0] m_axi_araddr,
    input m_axi_rvalid,
    output reg m_axi_rready,
    input [31:0] m_axi_rdata,
    input [1:0] m_axi_rresp,


    output reg o_wren,
    output reg [4:0] o_rd,
    output reg [31:0] o_data,
    output reg o_finish
);

    reg [2:0] axi_stage = 0;
    reg [4:0] axi_rd_cache;

    assign m_axi_clk = clk;
    assign m_axi_rst_n = rst_n;

    initial begin
        m_axi_awvalid <= 0;
        m_axi_awaddr <= 0;
        m_axi_wvalid <= 0;
        m_axi_wdata <= 0;
        m_axi_bready <= 0;
        m_axi_arvalid <= 0;
        m_axi_araddr <= 0;
        m_axi_rready <= 0;
    end
                      

    always @(posedge clk) begin
        if(!rst_n) begin
            i_next <= 1;
            o_finish <= 0;
        end
        else if(c_error) begin
            i_next <= 0;
        end
        else begin
            case(axi_stage)
                0: begin
                    m_axi_rready <= 0;
                    m_axi_bready <= 1;
                    if(i_valid) begin
                        if(i_memen) begin
                            i_next <= 0;
                            o_finish <= 0;
                            o_wren <= 0;
                            if(i_regen) begin
                                m_axi_araddr <= i_data;
                                m_axi_arvalid <= 1;
                                axi_stage <= 1;
                                o_rd <= i_rd;
                            end
                            else begin
                                m_axi_awaddr <= i_data;
                                m_axi_awvalid <= 1;
                                m_axi_wvalid <= 1;
                                axi_stage <= 3;
                                (*full_case*)
                                case(i_memstrb)
                                    0: m_axi_wdata <= i_memdata[7:0];
                                    1: m_axi_wdata <= i_memdata[15:0];
                                    2: m_axi_wdata <= i_memdata;
                                endcase
                            end
                        end
                        else if(i_regen) begin
                            i_next <= 1;
                            o_wren <= 1;
                            o_rd <= i_rd;
                            o_data <= i_data;
                            o_finish <= 1;
                        end
                        else begin
                            i_next <= 1;
                            o_wren <= 0;
                            o_finish <= 1;
                        end
                    end
                    else begin
                        o_wren <= 0;
                        o_finish <= 0;
                    end
                end
                1: begin
                    if(m_axi_arready) begin
                        m_axi_arvalid <= 0;
                        m_axi_rready <= 1;
                        axi_stage <= 2;
                    end
                end
                2: begin
                    if(m_axi_rvalid) begin
                        if(m_axi_rresp[1]) begin
                            c_error <= 1;
                        end
                        else begin
                            o_wren <= 1;
                            i_next <= 1;
                            axi_stage <= 0;
                            o_finish <= 1;
                            m_axi_rready <= 0;
                            (* full_case *)
                            case(i_memstrb)
                            0: o_data <= $signed(m_axi_rdata[7:0]);
                            1: o_data <= $signed(m_axi_rdata[15:0]);
                            2: o_data <= m_axi_rdata;
                            4: o_data <= m_axi_rdata[7:0];
                            5: o_data <= m_axi_rdata[15:0];
                            endcase
                        end
                    end
                end
                3: begin
                    if(m_axi_awready) m_axi_awvalid <= 0;
                    if(m_axi_wready) m_axi_wvalid <= 0;
                    if((m_axi_awvalid & m_axi_awready & !m_axi_awvalid) | (m_axi_wvalid & m_axi_wready & !m_axi_awvalid) | (m_axi_wvalid & m_axi_wready & m_axi_awvalid & m_axi_awready)) begin
                        axi_stage <= 4;
                        m_axi_bready <= 1;
                    end
                end
                4: begin
                    if(m_axi_bvalid) begin
                        if(!m_axi_bresp[1]) begin
                            axi_stage <= 0;
                            i_next <= 1;
                            o_finish <= 1;
                            m_axi_bready <= 0;
                        end
                        else begin
                            c_error <= 1;
                        end
                    end
                end
            endcase
        end
    end

    

endmodule