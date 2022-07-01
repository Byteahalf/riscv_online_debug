`timescale 1ns/1ps

module cpureg #(
    parameter REGISTER_INITIAL_VALUE = 0
)(
    input clk,
    input [4:0] rd_addr0,
    input [4:0] rd_addr1,
    output [31:0] rd_rs1,
    output [31:0] rd_rs2,
    input [4:0] wr_addr,
    input [31:0] wr_data,
    input wr_en,

    input o_next
);
    reg [31:0] cpu_reg [0:31];

    assign rd_rs1 = cpu_reg[rd_addr0];
    assign rd_rs2 = cpu_reg[rd_addr1];
    integer i;
    initial begin
        for(i = 0; i < 32; i = i + 1) begin: init
            cpu_reg[i] <= REGISTER_INITIAL_VALUE;
        end
    end
    
    always @(posedge clk) begin
        if(wr_en) begin
            if(wr_addr != 0) begin
                cpu_reg[wr_addr] <= wr_data;
            end
        end
    end
    
endmodule