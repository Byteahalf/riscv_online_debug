`timescale 1ns/1ps

module alu_sim();
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
        .c_flush     (c_flush),

        .o_valid     (dec_valid),
        .o_next      (dec_next),
        .o_rs1en     (dec_rs1en),
        .o_rs2en     (dec_rs2en),
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
        .rd_addr0    (o_instr[19:15]),
        .rd_addr1    (o_instr[24:20]),
        .rd_rs1      (reg_rs1),
        .rd_rs2      (reg_rs2),

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

        .o_next      (1'b1)
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