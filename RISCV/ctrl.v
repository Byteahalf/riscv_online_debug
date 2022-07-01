`timescale 1ns/1ps

module ctrl(
    input clk,
    input rst_n,

    input [31:0] pc,
    input valid,
    output reg [31:0] o_pc,
    output reg o_valid,
    output reg [4:0] o_data
);
    reg [31:0] symbol [31:0];

    reg [0:4] pc_valid;
    reg [4:0] pc_symbol [0:4];
    reg [32:0] pc_cache [0:4];

    integer i;
    initial begin
        for(i = 0; i < 32; i = i + 1) begin
            symbol[i] = i << 4;
        end
    end

    initial begin
        pc_symbol[0] <= 0;
        pc_valid[0] <= 0;
    end

    genvar j;
    generate for(j = 0; j < 4; j = j + 1) begin
        always @(posedge clk) begin
            pc_cache[j + 1] <= pc_cache[j];
            if(pc_cache[j] == symbol[8 * j]) begin
                pc_symbol[j + 1] <= 8 * j;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 1]) begin
                pc_symbol[j + 1] <= 8 * j + 1;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 2]) begin
                pc_symbol[j + 1] <= 8 * j + 2;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 3]) begin
                pc_symbol[j + 1] <= 8 * j + 3;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 4]) begin
                pc_symbol[j + 1] <= 8 * j + 4;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 5]) begin
                pc_symbol[j + 1] <= 8 * j + 5;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 6]) begin
                pc_symbol[j + 1] <= 8 * j + 6;
                pc_valid[j + 1] <= 1;
            end
            else if(pc_cache[j] == symbol[8 * j + 7]) begin
                pc_symbol[j + 1] <= 8 * j + 7;
                pc_valid[j + 1] <= 1;
            end
            else begin
                pc_symbol[j + 1] <= pc_symbol[j];
                pc_valid[j + 1] <= pc_valid[j];
            end
        end
    end
    endgenerate

    always @(posedge clk) begin
        if(valid) begin
            pc_cache[0] <= pc;
        end
        else begin
            pc_cache[0] <= (1 << 32);
        end
    end

    always @(posedge clk) begin
        o_valid <= pc_valid[4];
        o_pc <= pc_cache[4];
        o_data <= pc_symbol[4];
    end

    
endmodule