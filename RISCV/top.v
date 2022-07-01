`timescale 1ns/1ps

module top(
    input clk,
    input rst_n,

    output [31:0] pc,
    output pc_valid,
    output [31:0] perf,
    output error,

    output M_AXI_clk,
    output M_AXI_rst_n,
    output M_AXI_wrb_awvalid,
    input M_AXI_wrb_awready,
    output [31:0] M_AXI_wrb_awaddr,
    output M_AXI_wrb_wvalid,
    input M_AXI_wrb_wready,
    output [31:0] M_AXI_wrb_wdata,
    input M_AXI_wrb_bvalid,
    output M_AXI_wrb_bready,
    input [1:0] M_AXI_wrb_bresp,
    output M_AXI_wrb_arvalid,
    input M_AXI_wrb_arready,
    output [31:0] M_AXI_wrb_araddr,
    input M_AXI_wrb_rvalid,
    output M_AXI_wrb_rready,
    input [31:0] M_AXI_wrb_rdata,
    input [1:0] M_AXI_wrb_rresp,

    output [31:0] M_AXI_fetch_araddr,
    output [7:0] M_AXI_fetch_arlen,
    output [2:0] M_AXI_fetch_arsize,
    output [1:0] M_AXI_fetch_arburst,
    output M_AXI_fetch_arvalid,
    input M_AXI_fetch_arready,
    input [31:0] M_AXI_fetch_rdata,
    input [1:0] M_AXI_fetch_rresp,
    input M_AXI_fetch_rlast,
    input M_AXI_fetch_rvalid,
    output M_AXI_fetch_rready
);
    wire [31:0] o_instr;
    wire [32:0] o_pc;
    wire o_valid;
    wire o_next;

    wire dec_valid;
    wire dec_next;
    wire dec_rs1en;
    wire dec_rs2en;
    wire [4:0] dec_rs1;
    wire [4:0] dec_rs2;
    wire [31:0] dec_imm;
    wire [4:0] dec_opcode;
    wire dec_memen;
    wire dec_regen;
    wire [2:0] dec_memstrb;
    wire [32:0] dec_pc;
    wire [4:0] dec_rd;
    wire [31:0] dec_instr_pc;

    wire [31:0] reg_rs1;
    wire [31:0] reg_rs2;
    wire c_flush;
    wire [31:0] c_pc;

    wire alu_regen;
    wire alu_memen;
    wire [2:0] alu_memstrb;
    wire [31:0] alu_data;
    wire [31:0] alu_memdata;
    wire [4:0] alu_rd;
    wire alu_next;
    wire alu_valid;
    wire [31:0] alu_instr_pc;

    wire wrb_wren;
    wire [4:0] wrb_rd;
    wire [31:0] wrb_data;
    wire wrb_finish;

    assign mem_rst = 0;

    assign pc = alu_instr_pc;
    assign pc_valid = alu_next & alu_valid;
    assign perf = performance;

    reg [31:0] performance = 0;

    always @(posedge clk) begin
        if(!rst_n) begin
            performance <= 0;
        end
        else begin
            performance <= performance + 1;
        end
    end

    fetch U0(
        .clk         (clk),
        .rst_n       (rst_n),
        .o_next      (o_next),
        .o_instr     (o_instr),
        .o_pc        (o_pc),
        .o_valid     (o_valid),
        .c_flush     (c_flush),
        .c_pc        (c_pc),
        .m_axi_araddr      (M_AXI_fetch_araddr),
        .m_axi_arlen       (M_AXI_fetch_arlen),
        .m_axi_arsize      (M_AXI_fetch_arsize),
        .m_axi_arburst     (M_AXI_fetch_arburst),
        .m_axi_arvalid     (M_AXI_fetch_arvalid),
        .m_axi_arready     (M_AXI_fetch_arready),
        .m_axi_rdata       (M_AXI_fetch_rdata),
        .m_axi_rresp       (M_AXI_fetch_rresp),
        .m_axi_rlast       (M_AXI_fetch_rlast),
        .m_axi_rvalid      (M_AXI_fetch_rvalid),
        .m_axi_rready      (M_AXI_fetch_rready)
    );

    decode U1(
        .clk         (clk),
        .rst_n       (rst_n),
        .i_instr     (o_instr),
        .i_pc        (o_pc),
        .i_valid     (o_valid),
        .i_next      (o_next),
        .i_finish    (wrb_finish),

        .c_flush     (c_flush),
        .c_error     (error),

        .o_valid     (dec_valid),
        .o_next      (dec_next),
        .o_rs1en     (dec_rs1en),
        .o_rs2en     (dec_rs2en),
        .o_rs1       (dec_rs1),
        .o_rs2       (dec_rs2),
        .o_imm       (dec_imm),
        .o_opcode    (dec_opcode),
        .o_memen     (dec_memen),
        .o_regen     (dec_regen),
        .o_memstrb   (dec_memstrb),
        .o_pc        (dec_pc),
        .o_rd        (dec_rd),
        .o_instr_pc  (dec_instr_pc)
    );

    cpureg U2(
        .clk         (clk),
        .rd_addr0    (dec_rs1),
        .rd_addr1    (dec_rs2),
        .rd_rs1      (reg_rs1),
        .rd_rs2      (reg_rs2),
        .wr_addr     (wrb_rd),
        .wr_data     (wrb_data),
        .wr_en       (wrb_wren),

        .o_next      (dec_next)
    );

    alu U3(
        .clk         (clk),
        .rst_n       (rst_n),

        .i_valid     (dec_valid),
        .i_next      (dec_next),
        .i_rs1en     (dec_rs1en),
        .i_rs2en     (dec_rs2en),
        .i_rs1       (reg_rs1),
        .i_rs2       (reg_rs2),
        .i_imm       (dec_imm),
        .i_opcode    (dec_opcode),
        .i_memen     (dec_memen),
        .i_regen     (dec_regen),
        .i_memstrb   (dec_memstrb),
        .i_pc        (dec_pc),
        .i_rd        (dec_rd),
        .i_instr_pc  (dec_instr_pc),
        .c_flush     (c_flush),
        .c_pc        (c_pc),

        .o_valid     (alu_valid),
        .o_next      (alu_next),
        .o_regen     (alu_regen),
        .o_memen     (alu_memen),
        .o_memstrb   (alu_memstrb),
        .o_data      (alu_data),
        .o_memdata   (alu_memdata),
        .o_rd        (alu_rd),
        .o_instr_pc  (alu_instr_pc)
    );

    wrb U4(
        .clk         (clk),
        .rst_n       (rst_n),

        .i_valid     (alu_valid),
        .i_next      (alu_next),
        .i_regen     (alu_regen),
        .i_memen     (alu_memen),
        .i_memstrb   (alu_memstrb),
        .i_data      (alu_data),
        .i_memdata   (alu_memdata),
        .i_rd        (alu_rd),

        .m_axi_awvalid  (M_AXI_wrb_awvalid),
        .m_axi_awready  (M_AXI_wrb_awready),
        .m_axi_awaddr   (M_AXI_wrb_awaddr),
        .m_axi_wvalid   (M_AXI_wrb_wvalid),
        .m_axi_wready   (M_AXI_wrb_wready),
        .m_axi_wdata    (M_AXI_wrb_wdata),
        .m_axi_bvalid   (M_AXI_wrb_bvalid),
        .m_axi_bready   (M_AXI_wrb_bready),
        .m_axi_bresp    (M_AXI_wrb_bresp),
        .m_axi_arvalid  (M_AXI_wrb_arvalid),
        .m_axi_arready  (M_AXI_wrb_arready),
        .m_axi_araddr   (M_AXI_wrb_araddr),
        .m_axi_rvalid   (M_AXI_wrb_rvalid),
        .m_axi_rready   (M_AXI_wrb_rready),
        .m_axi_rdata    (M_AXI_wrb_rdata),
        .m_axi_rresp    (M_AXI_wrb_rresp),

        .o_wren      (wrb_wren),
        .o_rd        (wrb_rd),
        .o_data      (wrb_data),
        .o_finish    (wrb_finish)

    );


endmodule