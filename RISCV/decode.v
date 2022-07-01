`timescale 1ns/1ps

module decode(
    input clk,
    input rst_n,
    input [31:0] i_instr,
    input [32:0] i_pc,
    input i_valid,
    output i_next,
    input i_finish,

    input c_flush,
    output reg c_error,

    output o_valid,
    input o_next,
    output reg o_rs1en,
    output reg o_rs2en,
    output reg [4:0] o_rs1,
    output reg [4:0] o_rs2,
    output reg [31:0] o_imm,
    output reg [4:0] o_opcode,
    output reg o_memen,
    output reg o_regen,
    output reg [2:0] o_memstrb,
    output reg [32:0] o_pc,
    output reg [4:0] o_rd,

    output reg [31:0] o_instr_pc
);
    wire [31:0] imm_u;
    wire [31:0] imm_j;
    wire [31:0] imm_i;
    wire [31:0] imm_b;
    wire [31:0] imm_s;
    wire [6:0] opcode;
    wire [2:0] opcodea;

    reg valid;
    reg finish;

    reg fifo_en;
    wire fifo_result;

    assign imm_u = {i_instr[31:12], 12'b0};
    assign imm_j = $signed({i_instr[31], i_instr[19:12], i_instr[20], i_instr[30:21], 1'b0});
    assign imm_i = $signed({i_instr[31:20]});
    assign imm_b = $signed({i_instr[31], i_instr[7], i_instr[30:25], i_instr[11:8], 1'b0});
    assign imm_s = $signed({i_instr[31:25], i_instr[11:7]});
    assign opcode = i_instr[6:0];
    assign opcodea = i_instr[14:12];
    assign i_next = o_next & !c_error & !fifo_result;
    assign o_valid = valid & ~fifo_result & ~c_flush;

    //reg_en mem_en controller
    always @(posedge clk) begin
        if(!rst_n) begin
            c_error <= 0;
            valid <= 0;
        end
        else if(c_flush | c_error) begin
            valid <= 0;
            c_error <= ~c_flush;
        end
        else if(i_valid & i_next) begin
            o_instr_pc <= i_pc;
            if(opcode[1:0] != 2'b11) begin
                c_error <= 1;
                valid <= 0;
            end
            else begin
                o_rd <= i_instr[11:7];
                o_rs1 <= i_instr[19:15];
                o_rs2 <= i_instr[24:20];
                case(opcode[6:2])
                5'b01101: begin //lui
                    o_rs1en <= 0;
                    o_rs2en <= 0;
                    o_imm <= imm_u;
                    o_opcode <= 0;
                    o_memen <= 0;
                    o_regen <= 1;
                    o_pc <= 0;
                    valid <= 1;
                end
                5'b00101: begin //auipc
                    o_rs1en <= 0;
                    o_rs2en <= 0;
                    o_imm <= imm_u;
                    o_opcode <= 0;
                    o_memen <= 0;
                    o_regen <= 1;
                    o_pc <= i_pc;
                    valid <= 1;
                end
                5'b11011: begin //jal
                    o_rs1en <= 0;
                    o_rs2en <= 0;
                    o_imm <= 4;
                    o_opcode <= 0;
                    o_regen <= 1;
                    o_memen <= 0;
                    o_pc <= i_pc;
                    valid <= 1;
                end
                5'b11001: begin //jalr
                    o_rs1en <= 1;
                    o_rs2en <= 0;
                    o_imm <= imm_i;
                    o_opcode <= 5'b1_0000;
                    o_memen <= 0;
                    o_regen <= 1;
                    o_pc <= i_pc;
                    valid <= 1;
                end
                5'b11000: begin //beq bne blt bge bltu bgeu
                    o_rs1en <= 1;
                    o_rs2en <= 1;
                    o_imm <= imm_b;
                    o_opcode <= {1'b1, opcodea};
                    o_memen <= 0;
                    o_regen <= 0;
                    o_pc <= i_pc;
                    valid <= 1;
                end
                5'b00000: begin //lb lw ls lbu lhu
                    o_rs1en <= 1;
                    o_rs2en <= 0;
                    o_imm <= imm_i;
                    o_opcode <= 0;
                    o_memen <= 1;
                    o_regen <= 1;
                    o_memstrb <= opcodea;
                    valid <= 1;
                end
                5'b01000: begin //sb sh sw
                    o_rs1en <= 1;
                    o_rs2en <= 0;
                    o_imm <= imm_s;
                    o_opcode <= 0;
                    o_memen <= 1;
                    o_regen <= 0;
                    o_memstrb <= opcodea;
                    valid <= 1;
                end
                5'b00100: begin //addi slti sltiu xori ori andi slli srli srai
                    o_rs1en <= 1;
                    o_rs2en <= 0;
                    o_imm <= imm_i;
                    o_opcode <= opcodea;
                    o_memen <= 0;
                    o_regen <= 1;
                    valid <= 1;
                end
                5'b01100: begin //R
                    if(i_instr[31:25] != 0 & i_instr[31:25] != 7'b010_0000) begin
                        c_error <= 1;
                        valid <= 0;
                    end
                    else begin
                        o_rs1en <= 1;
                        o_rs2en <= 1;
                        o_imm <= imm_i;
                        o_opcode <= opcodea;
                        o_memen <= 0;
                        o_regen <= 1;
                        valid <= 1;
                    end
                end
                default: begin
                    c_error <= 1;
                    valid <= 0;
                end
                endcase
            end
        end
        else if(i_next) begin
            valid <= 0;
        end
    end

    always @(posedge clk) begin
        finish <= i_finish;
    end

    async_fifo_comparator #(
        .DATA_DEPTH    (4),
        .DATA_WIDTH    (5)
    )
    fifo(
        .clk           (clk),
        .rst_n         (rst_n & ~c_flush),
        .rd_en         (finish),
        .wr_en         (o_next & o_valid),
        .wr_data       (o_rd),
        
        .i_rs1         (o_rs1),
        .i_rs2         (o_rs2),
        .i_rs1en       (o_rs1en),
        .i_rs2en       (o_rs2en | (o_memen & ~o_regen)),
        .o_result      (fifo_result)
    );


endmodule