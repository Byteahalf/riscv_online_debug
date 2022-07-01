`timescale 1ns/1ps

module fetch_sim();
    reg clk;
    integer counter = 0;

    wire [31:0] addr;
    wire [31:0] data;
    wire mem_clk;
    wire we;
    wire en;

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
        .o_next      (counter[0]),
        .i_addr      (addr),
        .i_data      (data),
        .i_clk       (mem_clk),
        .i_we        (we),
        .i_en        (en),
        .c_flush     (0)
    );

    blk_mem_gen_0 mem(
        .clka        (mem_clk),
        .rsta        (0),
        .ena         (en),
        .wea         (we),
        .addra       (addr),
        .douta       (data)      
    );
endmodule