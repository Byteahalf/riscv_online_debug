`timescale 1ns/1ps

module alu(
    input clk,
    input rst_n,
    input i_valid,
    output i_next,
    input i_rs1en,
    input i_rs2en,
    input [31:0] i_imm,
    input [4:0] i_opcode,
    input i_memen,
    input i_regen,
    input [2:0] i_memstrb,
    input [32:0] i_pc,
    input [31:0] i_rs1,
    input [31:0] i_rs2,
    input [4:0] i_rd,
    input [31:0] i_instr_pc,

    output reg c_flush,
    output reg [31:0] c_pc,

    output o_regen,
    output o_memen,
    output reg [2:0] o_memstrb,
    output [31:0] o_data,
    output reg [31:0] o_memdata,
    output [4:0] o_rd,
    output o_valid,
    output reg [31:0] o_instr_pc,
    input o_next
);

    wire [31:0] rs1;
    wire [31:0] rs2;
    reg [31:0] data_out[0:2];
    reg [2:0] valid = 0;
    reg [2:0] next = 3'b111;
    reg [2:0] error = 0;
    reg [1:0] regen = 0;
    reg memen = 0;
    reg [4:0] rd [0:1];

    wire [31:0] o_add;
    wire [31:0] o_sub;
    wire [31:0] o_xor;
    wire [31:0] o_or;
    wire [31:0] o_and;
    wire o_slt;
    wire o_sltu;

    reg [1:0] shift_stage = 0;
    reg [31:0] shift_cache;
    reg [1:0] shift_instr;
    reg [4:0] shift_shamt;
    wire [31:0] shift_sll_pipe[4:0];
    wire [31:0] shift_srl_pipe[4:0];
    wire [31:0] shift_sra_pipe[4:0];

    wire comparator_equal;
    wire comparator_little;
    wire comparator_little_unsigned;
    wire [31:0] comparator_pc;
    reg flush;

    assign o_valid = |{valid};
    assign i_next = &{next} & o_next;
    assign o_regen = (valid[0] ? regen[0] : 0) | (valid[1] ? regen[1] : 0);
    assign o_memen = memen;
    assign o_data = (valid[0] ? data_out[0] : 32'b0) | (valid[1] ? data_out[1] : 32'b0) | (valid[2] ? data_out[2] : 32'b0);
    assign o_rd = (valid[0] ? rd[0] : 0) | (valid[1] ? rd[1] : 0);

    assign rs1 = i_rs1en ? i_rs1 : i_pc[31:0];
    assign rs2 = i_rs2en ? i_rs2 : i_imm;

    assign o_add = rs1 + rs2;
    assign o_sub = rs1 - rs2;
    assign o_xor = rs1 ^ rs2;
    assign o_or = rs1 | rs2;
    assign o_and = rs1 & rs2;
    assign o_slt = $signed(rs1) < $signed(rs2);
    assign o_sltu = rs1 < rs2;

    assign shift_sll_pipe[4] = shift_shamt[4] ? shift_cache << 16 : shift_cache;
    assign shift_srl_pipe[4] = shift_shamt[4] ? shift_cache >> 16 : shift_cache;
    assign shift_sra_pipe[4] = shift_shamt[4] ? $signed(shift_cache) >>> 16 : shift_cache;

    assign comparator_equal = (i_rs1 == i_rs2);
    assign comparator_little = $signed(i_rs1) < $signed(i_rs2);
    assign comparator_little_unsigned = i_rs1 < i_rs2;
    assign comparator_pc = i_pc[32] ? i_pc[31:0] : i_pc[31:0] + i_imm;

    genvar i;
    generate for(i = 3; i >= 0; i = i - 1) begin: label0
        assign shift_sll_pipe[i] = shift_shamt[i] ? shift_sll_pipe[i + 1] << (2**i) : shift_sll_pipe[i + 1];
        assign shift_srl_pipe[i] = shift_shamt[i] ? shift_srl_pipe[i + 1] >> (2**i) : shift_srl_pipe[i + 1];
        assign shift_sra_pipe[i] = shift_shamt[i] ? $signed(shift_sra_pipe[i + 1]) >>> (2**i) : shift_sra_pipe[i + 1];
    end
    endgenerate

    always @(posedge clk) begin
        if(i_valid & i_next) begin
            o_instr_pc <= i_instr_pc;
        end
    end

    //basic
    always @(posedge clk) begin
        if(!rst_n) begin
            error[0] <= 0;
            valid[0] <= 0;
            next[0] <= 1;
            rd[0] <= 0;
        end
        else if(i_next & i_valid) begin
            regen[0] <= i_regen;
            memen <= i_memen;
            rd[0] <= i_rd;
            o_memstrb <= i_memstrb;
            o_memdata <= i_rs2;
            if(i_opcode[4:3] == 2'b00) begin
                (* full_case *)
                case(i_opcode[2:0])
                3'b000: begin
                    valid[0] <= 1;
                    if(i_rs1en & i_rs2en & i_imm[10]) data_out[0] <= o_sub;
                    else data_out[0] <= o_add;
                end
                3'b100: begin
                    data_out[0] <= o_xor;
                    valid[0] <= 1;
                end
                3'b110: begin
                    data_out[0] <= o_or;
                    valid[0] <= 1;
                end
                3'b111: begin
                    data_out[0] <= o_and;
                    valid[0] <= 1;
                end
                3'b010: begin
                    data_out[0] <= o_slt;
                    valid[0] <= 1;
                end
                3'b011: begin
                    data_out[0] <= o_sltu;
                    valid[0] <= 1;
                end
                default: begin
                    valid[0] <= 0;
                end 
                endcase
            end
            else begin
                valid[0] <= 0;
            end
        end
        else if(o_next) begin
            valid[0] <= 0;
        end
    end

    //shift
    always @(posedge clk) begin
        if(!rst_n) begin
            valid[1] <= 0;
            shift_stage <= 0;
            next[1] <= 1;
            rd[1] <= 0;
            error[1] <= 0;
        end
        else begin
            (* full_case *)
            case(shift_stage)
            0: begin
                if((i_opcode == 'b1 | i_opcode == 'b101) & i_valid & i_next) begin
                    shift_cache <= rs1;
                    shift_shamt <= rs2[4:0];
                    shift_stage <= 1;
                    shift_instr <= {i_imm[10], i_opcode[2]};
                    valid[1] <= 0;
                    next[1] <= 0;
                    regen[1] <= i_regen;
                    rd[1] <= i_rd;
                    if(i_imm[10] == 1 & i_opcode[2] == 0) begin
                        error[1] <= 1;
                    end
                end
                else if(o_next) begin
                    valid[1] <= 0;
                end
            end
            1: begin
                shift_stage <= 0;
                valid[1] <= 1;
                next[1] <= 1;
                (* full_case *)
                case(shift_instr)
                3'b000: data_out[1] <= shift_sll_pipe[0];
                3'b001: data_out[1] <= shift_srl_pipe[0];
                3'b011: data_out[1] <= shift_sra_pipe[0];
                endcase
            end
            endcase
        end
    end

    //comparator
    always @(posedge clk) begin
        if(!rst_n) begin
            error[2] <= 0;
            c_flush <= 0;
            valid[2] <= 0;
            flush <= 0;
            next[2] <= 1;
            data_out[2] <= 0;
        end
        else if(flush & o_next) begin
            c_flush <= 1;
            flush <= 0;
        end
        else if(c_flush) begin
            c_flush <= 0;
            valid[2] <= 0;
            next[2] <= 1;
        end
        else if(i_valid & i_next) begin
            if(i_opcode[4]) begin
                c_flush <= 1;
                c_pc <= i_rs1 + i_imm;
                data_out[2] <= i_pc + 4;
                valid[2] <= 1;
                next[2] <= 0;
            end
            else if(i_opcode[3]) begin
                case(i_opcode[2:1])
                2'b00: begin
                    flush <= i_pc[32] ^ (comparator_equal ^ i_opcode[0]);
                    next[2] <= ~(i_pc[32] ^ (comparator_equal ^ i_opcode[0]));
                    valid[2] <= ~(i_pc[32] ^ (comparator_equal ^ i_opcode[0]));
                    c_pc <= comparator_pc;
                end
                2'b10: begin
                    flush <= i_pc[32] ^ (comparator_little ^ i_opcode[0]);
                    next[2] <= ~(i_pc[32] ^ (comparator_little ^ i_opcode[0]));
                    valid[2] <= ~(i_pc[32] ^ (comparator_little ^ i_opcode[0]));
                    c_pc <= comparator_pc;
                end
                2'b11: begin
                    flush <= i_pc[32] ^ (comparator_little_unsigned ^ i_opcode[0]);
                    next[2] <= ~(i_pc[32] ^ (comparator_little_unsigned ^ i_opcode[0]));
                    valid[2] <= ~(i_pc[32] ^ (comparator_little_unsigned ^ i_opcode[0]));
                    c_pc <= comparator_pc;
                end
                2'b01: begin
                    error[2] <= 1;
                    next[2] <= 1;
                    valid[2] <= 0;
                end
                endcase
            end
            else begin
                flush <= 0;
                valid[2] <= 0;
                next[2] <= 1;
            end
        end
        else if(o_next) begin
            valid[2] <= 0;
        end
    end

endmodule