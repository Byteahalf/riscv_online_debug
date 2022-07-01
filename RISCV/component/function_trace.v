`timescale 1ns/1ps

module function_trace
#(
    parameter OUTPUT_FIFO_DEPTH = 256,
    parameter DEBUG_MODE = 1
)
(
    input clk,
    input rst_n,

    input S_AXI_arvalid,
    output reg S_AXI_arready,
    input [9:0] S_AXI_araddr,
    output reg S_AXI_rvalid,
    input S_AXI_rready,
    output reg [31:0] S_AXI_rdata,
    input S_AXI_awvalid,
    output reg S_AXI_awready,
    input [9:0] S_AXI_awaddr,
    input S_AXI_wvalid,
    output reg S_AXI_wready,
    input [31:0] S_AXI_wdata,
    output reg S_AXI_bvalid,
    input S_AXI_bready,
    output [1:0] S_AXI_bresp,

    input [31:0] i_pc,
    input i_pc_valid,
    input [31:0] i_pc_perf
);
    //resgiter map
    reg reg_system_run; //0x0 R/W
    reg [31:0] reg_symbol_input; //0x4 W
    reg [31:0] reg_mark_perf_output; //0X8 R
    reg [31:0] reg_mark_symbol_output; //0XC R
    reg [4:0] reg_symbol_counter; //0X10 R
    reg reg_mark_available; //0x14 R

    //Symbol interface
    reg symbol_en;
    reg symbol_rst;

    //PC interface
    reg pc_en [0:3];
    reg [31:0] pc_cache [0:3];
    reg pc_valid [0:3];
    reg [4:0] pc_symbol [0:3];
    reg [31:0] pc_perf [0:3];

    //symbol internal register
    reg [5:0] counter = 0;
    reg [31:0] symbol_array [31:0];
    reg symbol_valid [31:0];

    //mark internal register
    reg [31:0] mark_perf [0:OUTPUT_FIFO_DEPTH - 1];
    reg [5:0] mark_symbol [0:OUTPUT_FIFO_DEPTH - 1];
    reg [$clog2(OUTPUT_FIFO_DEPTH) - 1:0] mark_write_counter = 0;
    reg [$clog2(OUTPUT_FIFO_DEPTH) - 1:0] mark_read_counter_perf = 0;
    reg [$clog2(OUTPUT_FIFO_DEPTH) - 1:0] mark_read_counter_symbol = 0;
    wire mark_empty;
    assign mark_empty = mark_read_counter_perf == mark_write_counter;

    //AXI internal register
    reg [31:0] axi_write_channel_address;

    // temporary variable
    integer i;

    //wire variable
    assign S_AXI_bresp = 0;

    initial begin
        for(i = 0; i < 32; i = i + 1) begin
            symbol_valid[i] <= 0;
            symbol_array[i] <= 0;
        end
    end

    //DEBUG
    generate if(DEBUG_MODE) begin
        initial begin
            reg_system_run <= 0;
        end
    end
    endgenerate

    //symbol FIFO
    always @(posedge clk) begin
        if(symbol_rst) begin
            for(i = 0; i < 32; i = i + 1) begin
                symbol_valid[i] <= 0;
                counter <= 0;
            end    
        end
        else if(symbol_en & ~counter[5]) begin
            symbol_valid[counter[4:0]] <= 1;
            symbol_array[counter[4:0]] <= reg_symbol_input;
            counter <= counter + 1;
        end
    end

    //PC pipeline
    genvar j;
    generate for(j = 0; j < 3; j = j + 1) begin
        always @(posedge clk) begin
            pc_en[j + 1] <= pc_en[j];
            pc_cache[j + 1] <= pc_cache[j];
            pc_perf[j + 1] <= pc_perf[j];
            if(pc_en[j]) begin
                if(pc_cache[j] == symbol_array[j * 8 + 8] && symbol_valid[j * 8 + 8]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 8;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 9] && symbol_valid[j * 8 + 9]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 9;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 10] && symbol_valid[j * 8 + 10]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 10;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 11] && symbol_valid[j * 8 + 11]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 11;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 12] && symbol_valid[j * 8 + 12]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 12;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 13] && symbol_valid[j * 8 + 13]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 13;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 14] && symbol_valid[j * 8 + 14]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 14;
                end
                else if(pc_cache[j] == symbol_array[j * 8 + 15] && symbol_valid[j * 8 + 15]) begin
                    pc_valid[j + 1] <= 1;
                    pc_symbol[j + 1] <= j * 8 + 15;
                end
                else begin
                    pc_valid[j + 1] <= pc_valid[j];
                    pc_symbol[j + 1] <= pc_symbol[j];
                end
            end
            else begin
                pc_valid[j + 1] <= pc_valid[j];
                pc_symbol[j + 1] <= pc_symbol[j];
            end
        end
    end
    endgenerate

    //PC pipeline level-0
    always @(posedge clk) begin
        pc_perf[0] <= i_pc_perf;
        pc_cache[0] <= i_pc;
        pc_en[0] <= i_pc_valid;
        if(i_pc_valid) begin
            if(i_pc == symbol_array[0] && symbol_valid[0]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 0;
            end
            else if(i_pc == symbol_array[1] && symbol_valid[1]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 1;
            end
            else if(i_pc == symbol_array[2] && symbol_valid[2]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 2;
            end
            else if(i_pc == symbol_array[3] && symbol_valid[3]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 3;
            end
            else if(i_pc == symbol_array[4] && symbol_valid[4]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 4;
            end
            else if(i_pc == symbol_array[5] && symbol_valid[5]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 5;
            end
            else if(i_pc == symbol_array[6] && symbol_valid[6]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 6;
            end
            else if(i_pc == symbol_array[7] && symbol_valid[7]) begin
                pc_valid[0] <= 1;
                pc_symbol[0] <= 7;
            end
            else begin
                pc_valid[0] <= 0;
                pc_symbol[0] <= 0;
            end
        end
        else begin
            pc_valid[0] <= 0;
            pc_symbol[0] <= 0;
        end
    end

    //mark FIFO
    always @(posedge clk) begin
        if(pc_valid[3] & reg_system_run) begin
            mark_perf[mark_write_counter] <= pc_perf[3];
            mark_symbol[mark_write_counter] <= pc_symbol[3];
            mark_write_counter <= mark_write_counter + 1;
        end
    end

    //AXI READ
    always @(posedge clk) begin
        if(S_AXI_arvalid) begin
            if(S_AXI_arready) begin
                S_AXI_arready <= 0;
                S_AXI_rvalid <= 1;
            end
            else begin
                S_AXI_arready <= 1;
                case(S_AXI_araddr)
                    'h00: begin
                        S_AXI_rdata <= reg_system_run;
                    end
                    'h08: begin
                        if(mark_read_counter_perf != mark_write_counter) begin
                            S_AXI_rdata <= mark_perf[mark_read_counter_perf];
                            mark_read_counter_perf <= mark_read_counter_perf + 1;
                        end
                    end
                    'h0c: begin
                        if(mark_read_counter_symbol != mark_write_counter) begin
                            S_AXI_rdata <= mark_symbol[mark_read_counter_symbol];
                            mark_read_counter_symbol <= mark_read_counter_symbol + 1;
                        end
                    end
                    'h10: begin
                        S_AXI_rdata <= counter;
                    end
                    'h14: begin
                        S_AXI_rdata <= mark_write_counter - mark_read_counter_perf;
                    end
                    default: S_AXI_rdata <= 0;
                endcase
            end
        end
        else if(S_AXI_rready & S_AXI_rvalid) begin
            S_AXI_rvalid <= 0;
        end
    end

    always @(posedge clk) begin
        if(S_AXI_awvalid) begin
            if(S_AXI_awready) begin
                S_AXI_awready <= 0;
            end
            else begin
                axi_write_channel_address <= S_AXI_awaddr;
                S_AXI_awready <= 1;
            end
        end
        else if(S_AXI_wvalid) begin
            if(S_AXI_wready) begin
                S_AXI_wready <= 0;
                S_AXI_bvalid <= 1;
                symbol_en <= 0;
            end
            else begin
                S_AXI_wready <= 1;
                (* full_case *)
                case(axi_write_channel_address)
                'h00: reg_system_run <= S_AXI_wdata;
                'h04: begin
                    reg_symbol_input <= S_AXI_wdata;
                    symbol_en <= 1;
                end
                endcase
            end
        end
        else if(S_AXI_bvalid & S_AXI_bready) begin
            S_AXI_bvalid <= 0;
        end
    end
endmodule