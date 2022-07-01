`timescale 1ns/1ps
module mul
#(
    parameter MUL_METHOD="RADIX-4",
    paramter MUL_ADD_RATE = 4
)
(
    input clk,
    input rst_n,

    input [31:0] rs1,
    input [31:0] rs2,
    input rs1_signed,
    input rs2_signed,
    input en,
    output reg [63:0] rd,
);

    integer i;

    generate if(MUL_METHOD == "RADIX-4") begin
        always @(posedge clk) begin
            if(!rst_n) begin

            end
            else begin
                
            end
        end
    end
    endgenerate
    
endmodule

module mul_booth
#(
    paramter MUL_ADD_RATE = 4
)
(
    input clk,
    input rst_n,

    input [31:0] rs1,
    input [31:0] rs2,
    input rs1_signed,
    input rs2_signed,
    input en,
    output reg [63:0] rd,
);
    integer i;

    always @(posedge clk) begin
        if(!rst_n) begin

        end
        else begin
            
        end
    end

endmodule