`timescale 1ns/1ps

module wrb_sim();
    reg clk;
    reg rst_n;
    integer counter = 0;

    wire [31:0] addr;
    wire [31:0] data;
    wire mem_clk;
    wire we;
    wire en;

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

    wire wrb_wren;
    wire [4:0] wrb_rd;
    wire [31:0] wrb_data;
    wire wrb_finish;


    initial begin
        clk <= 0;
        #100 
        forever begin
            clk <= ~clk;
            #5;
        end
    end

    initial begin
        rst_n <= 0;
        #120;
        rst_n <= 1;
    end

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    fetch U0(
        .clk         (clk),
        .rst_n       (rst_n),
        .o_next      (o_next),
        .o_instr     (o_instr),
        .o_pc        (o_pc),
        .o_valid     (o_valid),
        .i_addr      (addr),
        .i_data      (data),
        .i_clk       (mem_clk),
        .i_we        (we),
        .i_en        (en),
        .c_flush     (c_flush),
        .c_pc        (c_pc)
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
        .o_rd        (dec_rd) 
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
        .c_flush     (c_flush),
        .c_pc        (c_pc),

        .o_valid     (alu_valid),
        .o_next      (alu_next),
        .o_regen     (alu_regen),
        .o_memen     (alu_memen),
        .o_memstrb   (alu_memstrb),
        .o_data      (alu_data),
        .o_memdata   (alu_memdata),
        .o_rd        (alu_rd)
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

        .m_axi_awready  (1'b1),
        .m_axi_wready   (1'b1),
        .m_axi_bvalid   (1'b1),
        .m_axi_bresp    (2'b00),
        .m_axi_rvalid   (1'b1),
        .m_axi_arready  (1'b1),
        .m_axi_rdata    ('h123),

        .o_wren      (wrb_wren),
        .o_rd        (wrb_rd),
        .o_data      (wrb_data),
        .o_finish    (wrb_finish)

    );


    blk_mem_gen_0 mem(
        .clka        (mem_clk),
        .rsta        (1'b0),
        .ena         (en),
        .wea         (we),
        .addra       (addr[31:2]),
        .douta       (data)      
    );


endmodule