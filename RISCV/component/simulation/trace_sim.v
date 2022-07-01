`timescale 1ns/1ps

module sim(
    input clk,
    input rst_n,
    output reg [31:0] pc,
    output reg pc_valid
);
    initial begin
        pc <= 0;
        pc_valid <= 0;
    end
    
    always @(posedge clk) begin
        if(rst_n) begin
            pc <= pc + 4;
            pc_valid <= 1;
        end
    end
endmodule