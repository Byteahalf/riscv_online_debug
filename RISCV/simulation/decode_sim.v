`timescale 1ns/1ps

module decode_sim();
    reg clk;
    integer counter = 0;

    wire [31:0] addr;
    wire [31:0] data;
    wire mem_clk;
    wire we;
    wire en;

    wire [31:0] o_instr;
    wire [31:0] o_pc;
    wire o_valid;
    wire o_next;


    initial begin
        #100 clk <= 0;
        forever begin
            #5 clk <= ~clk;
        end
    end

    always @(posedge clk) begin
        counter <= counter + 1;
    end

    fetch U0(
        .clk         (clk),
        .o_next      (o_next),
        .o_instr     (o_instr),
        .o_pc        (o_pc),
        .o_valid     (o_valid),
        .i_addr      (addr),
        .i_data      (data),
        .i_clk       (mem_clk),
        .i_we        (we),
        .i_en        (en),
        .c_flush     (0)
    );

    decode U1(
        .clk         (clk),
        .rst_n       (1),
        .i_instr     (o_instr),
        .i_pc        (o_pc),
        .i_valid     (o_valid),
        .i_next      (o_next),
        .c_flush     (0),
        .o_next      (1)
    );

    cpureg U2(
        .clk         (clk),
        .rd_addr0    (o_instr[19:15]),
        .rd_addr1    (o_instr[24:20])
    );

    blk_mem_gen_0 mem(
        .clka        (mem_clk),
        .rsta        (0),
        .ena         (en),
        .wea         (we),
        .addra       (addr[31:2]),
        .douta       (data)      
    );


endmodule