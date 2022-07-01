`timescale 1ns/1ps

module simulation();
    reg clk;
    reg rst_n;

    reg [31:0] pc;
    reg pc_valid;
    reg [31:0] counter = 0;

    initial begin
        clk <= 0;
        forever begin
            #5 clk <= ~clk;
        end
    end

    initial begin
        rst_n <= 0;
        #100 rst_n <= 1;
    end

    always @(posedge clk) begin
        counter <= counter + 1;
        pc <= counter << 3;
        pc_valid <= 1;
    end

    ctrl U0(
        .clk     (clk),
        .rst_n   (rst_n),
        .pc      (pc),
        .valid   (pc_valid)
    );
endmodule